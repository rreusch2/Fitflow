//
//  DatabaseService.swift
//  NexusGPT
//
//  Created on 2025-01-13
//

import Foundation
import Combine

class DatabaseService: ObservableObject {
    static let shared = DatabaseService()
    
    @Published var isConnected = false
    @Published var isLoading = false
    
    private var cancellables = Set<AnyCancellable>()
    
    // Supabase REST base
    private let supabaseBaseURL = URL(string: Config.Supabase.url)!
    private var restBaseURL: URL { supabaseBaseURL.appendingPathComponent("rest/v1") }
    private var anonKey: String { Config.Supabase.anonKey }
    private var authToken: String?
    private var authBaseURL: URL { supabaseBaseURL.appendingPathComponent("auth/v1") }
    
    init() {
        initialize()
    }
    
    // MARK: - Initialization
    
    func initialize() {
        // Basic reachability check to Supabase REST (non-blocking)
        let url = restBaseURL.appendingPathComponent("users")
        var comps = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        comps.queryItems = [URLQueryItem(name: "select", value: "id"), URLQueryItem(name: "limit", value: "1")]
        var req = URLRequest(url: comps.url!)
        req.httpMethod = "GET"
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(authToken ?? anonKey)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: req) { _, resp, _ in
            DispatchQueue.main.async {
                self.isConnected = (resp as? HTTPURLResponse)?.statusCode ?? 0 > 0
            }
        }.resume()
    }

    // MARK: - Supabase REST helpers
    
    private func restRequest(path: String,
                             method: String,
                             query: [URLQueryItem] = [],
                             body: Data? = nil,
                             prefer: String? = nil) async throws -> Data {
        var components = URLComponents(url: restBaseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if !query.isEmpty { components.queryItems = query }
        var req = URLRequest(url: components.url!)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(authToken ?? anonKey)", forHTTPHeaderField: "Authorization")
        if let prefer = prefer { req.setValue(prefer, forHTTPHeaderField: "Prefer") }
        req.httpBody = body
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            let text = String(data: data, encoding: .utf8) ?? ""
            throw DatabaseError.unknownError("Supabase REST error (\(code)): \(text)")
        }
        return data
    }
    
    private func rpc(_ name: String, payload: [String: Any]) async throws -> Data {
        let url = supabaseBaseURL.appendingPathComponent("rest/v1/rpc/\(name)")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(authToken ?? anonKey)", forHTTPHeaderField: "Authorization")
        req.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            let text = String(data: data, encoding: .utf8) ?? ""
            throw DatabaseError.unknownError("Supabase RPC error (\(code)): \(text)")
        }
        return data
    }
    
    // MARK: - GoTrue Auth (REST)
    
    struct AuthSession: Decodable {
        let access_token: String?
        let refresh_token: String?
        let user: AuthUser?
    }
    
    struct AuthUser: Decodable {
        let id: String
        let email: String?
    }
    
    private func authRequest(path: String, body: [String: Any]) async throws -> AuthSession {
        let url = authBaseURL.appendingPathComponent(path)
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        req.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            let text = String(data: data, encoding: .utf8) ?? ""
            throw DatabaseError.authenticationFailed("Auth error (\(code)): \(text)")
        }
        return try JSONDecoder().decode(AuthSession.self, from: data)
    }
    
    func authSignUp(email: String, password: String) async throws -> AuthSession {
        try await authRequest(path: "signup", body: ["email": email, "password": password])
    }
    
    func authSignIn(email: String, password: String) async throws -> AuthSession {
        try await authRequest(path: "token?grant_type=password", body: ["email": email, "password": password])
    }
    
    func authRefresh(refreshToken: String) async throws -> AuthSession {
        try await authRequest(path: "token?grant_type=refresh_token", body: ["refresh_token": refreshToken])
    }
    
    // MARK: - Auth Token Management
    
    func setAuthToken(_ token: String) {
        self.authToken = token
    }
    func clearAuthToken() {
        self.authToken = nil
    }
    
    // MARK: - User Management
    
    func createUser(_ user: User) async throws {
        isLoading = true
        defer { isLoading = false }
        // Insert into public.users via PostgREST
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let body = try encoder.encode([user])
        _ = try await restRequest(
            path: Config.Supabase.usersTable,
            method: "POST",
            body: body,
            prefer: "return=minimal"
        )
    }
    
    func authenticateUser(email: String, password: String) async throws -> User {
        isLoading = true
        defer { isLoading = false }
        // 1) Auth via GoTrue
        let session = try await authSignIn(email: email, password: password)
        guard let token = session.access_token, let authUser = session.user else {
            throw DatabaseError.authenticationFailed("No session returned. Check email confirmation settings.")
        }
        setAuthToken(token)
        // 2) Fetch or create profile row in users table
        guard let authUUID = UUID(uuidString: authUser.id) else {
            throw DatabaseError.invalidData("Invalid auth user id")
        }
        if let existing = try await getUserById(authUUID) {
            return existing
        }
        // Create minimal user row
        let new = User(
            id: authUUID,
            email: email,
            subscriptionTier: .free,
            preferences: nil,
            healthProfile: nil,
            hasCompletedOnboarding: false,
            createdAt: Date(),
            updatedAt: Date()
        )
        try await createUser(new)
        return new
    }
    
    func updateUser(_ user: User) async throws -> User {
        isLoading = true
        defer { isLoading = false }
        
        // Simulate API call delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Mock implementation - return updated user with new timestamp
        var updatedUser = user
        updatedUser = User(
            id: user.id,
            email: user.email,
            subscriptionTier: user.subscriptionTier,
            preferences: user.preferences,
            healthProfile: user.healthProfile,
            hasCompletedOnboarding: user.hasCompletedOnboarding,
            createdAt: user.createdAt,
            updatedAt: Date()
        )
        
        return updatedUser
    }
    
    func getUserById(_ userId: UUID) async throws -> User? {
        isLoading = true
        defer { isLoading = false }
        let data = try await restRequest(
            path: Config.Supabase.usersTable,
            method: "GET",
            query: [
                URLQueryItem(name: "select", value: "*"),
                URLQueryItem(name: "id", value: "eq.\(userId.uuidString)"),
                URLQueryItem(name: "limit", value: "1")
            ]
        )
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let users = try decoder.decode([User].self, from: data)
        return users.first
    }
    
    func sendPasswordResetEmail(email: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Simulate API call delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // In real implementation:
        // try await supabaseClient.auth.resetPasswordForEmail(email)
        
        // Mock implementation - just validate email format
        if !Config.isValidEmail(email) {
            throw DatabaseError.invalidData("Invalid email format")
        }
    }
    
    // MARK: - Workout Plans
    
    func saveWorkoutPlan(_ plan: WorkoutPlan) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Simulate API call delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // In real implementation:
        // try await supabaseClient.from(Config.Supabase.workoutPlansTable).insert(plan).execute()
        
        // Mock validation
        if plan.title.isEmpty {
            throw DatabaseError.invalidData("Workout plan title cannot be empty")
        }
    }
    
    func getWorkoutPlans(for userId: UUID) async throws -> [WorkoutPlan] {
        isLoading = true
        defer { isLoading = false }
        
        // Simulate API call delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // In real implementation:
        // let plans = try await supabaseClient.from(Config.Supabase.workoutPlansTable).select().eq("user_id", userId).execute()
        
        // Mock implementation - return sample workout plans
        return createMockWorkoutPlans(for: userId)
    }
    
    func deleteWorkoutPlan(_ planId: UUID) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Simulate API call delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // In real implementation:
        // try await supabaseClient.from(Config.Supabase.workoutPlansTable).delete().eq("id", planId).execute()
    }
    
    // MARK: - Meal Plans
    
    func saveMealPlan(_ plan: MealPlan) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Simulate API call delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // In real implementation:
        // try await supabaseClient.from(Config.Supabase.mealPlansTable).insert(plan).execute()
        
        // Mock validation
        if plan.title.isEmpty {
            throw DatabaseError.invalidData("Meal plan title cannot be empty")
        }
    }
    
    func getMealPlans(for userId: UUID) async throws -> [MealPlan] {
        isLoading = true
        defer { isLoading = false }
        
        // Simulate API call delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // In real implementation:
        // let plans = try await supabaseClient.from(Config.Supabase.mealPlansTable).select().eq("user_id", userId).execute()
        
        // Mock implementation - return sample meal plans
        return createMockMealPlans(for: userId)
    }
    
    func deleteMealPlan(_ planId: UUID) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Simulate API call delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // In real implementation:
        // try await supabaseClient.from(Config.Supabase.mealPlansTable).delete().eq("id", planId).execute()
    }
    
    // MARK: - Progress Tracking
    
    func saveProgressEntry(_ entry: ProgressEntry) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Simulate API call delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // In real implementation:
        // try await supabaseClient.from(Config.Supabase.progressTable).insert(entry).execute()
    }
    
    func getProgressEntries(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> [ProgressEntry] {
        isLoading = true
        defer { isLoading = false }
        
        // Simulate API call delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // In real implementation:
        // let entries = try await supabaseClient.from(Config.Supabase.progressTable)
        //     .select()
        //     .eq("user_id", userId)
        //     .gte("date", startDate)
        //     .lte("date", endDate)
        //     .execute()
        
        // Mock implementation
        return createMockProgressEntries(for: userId, from: startDate, to: endDate)
    }

    // MARK: - Fitness Preferences (RPC)
    
    func updateFitnessPreferences(userId: UUID, fitness: FitnessPreferences) async throws {
        isLoading = true
        defer { isLoading = false }
        let fitnessData = try JSONEncoder().encode(fitness)
        let fitnessJSON = try JSONSerialization.jsonObject(with: fitnessData, options: []) as? [String: Any] ?? [:]
        _ = try await rpc("update_fitness_preferences", payload: ["fitness": fitnessJSON])
    }

    // MARK: - Finance Preferences (RPC)
    // Server-side RPC expected: create a PostgreSQL function `update_finance_preferences(finance jsonb)`
    // that persists the preferences for the authenticated user (via auth.uid()).
    func updateFinancePreferences(preferences: FinancePreferences) async throws {
        isLoading = true
        defer { isLoading = false }
        let data = try JSONEncoder().encode(preferences)
        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] ?? [:]
        _ = try await rpc("update_finance_preferences", payload: ["finance": json])
    }

    // MARK: - Fitness Progress Persistence (Supabase-backed)
    
    // Workout Sessions
    func saveWorkoutSession(userId: UUID, _ session: WorkoutSession) async throws {
        isLoading = true
        defer { isLoading = false }
        struct Row: Encodable {
            let user_id: String
            let title: String
            let occurred_at: String
            let duration_seconds: Int
            let exercises: [CompletedExercise]
            let muscle_groups: [String]
            let calories_burned: Int?
            let average_heart_rate: Int?
        }
        let row = Row(
            user_id: userId.uuidString,
            title: session.title,
            occurred_at: ISO8601DateFormatter().string(from: session.date),
            duration_seconds: Int(session.duration),
            exercises: session.exercises,
            muscle_groups: session.muscleGroups.map { $0.rawValue },
            calories_burned: session.caloriesBurned,
            average_heart_rate: session.averageHeartRate
        )
        let body = try JSONEncoder().encode([row])
        _ = try await restRequest(path: "workout_sessions", method: "POST", body: body, prefer: "return=representation")
    }
    
    func getWorkoutHistory(for userId: UUID) async throws -> [WorkoutSession] {
        isLoading = true
        defer { isLoading = false }
        var items: [Any] = []
        let data = try await restRequest(
            path: "workout_sessions",
            method: "GET",
            query: [
                URLQueryItem(name: "select", value: "*"),
                URLQueryItem(name: "user_id", value: "eq.\(userId.uuidString)"),
                URLQueryItem(name: "order", value: "occurred_at.desc")
            ]
        )
        if let json = try JSONSerialization.jsonObject(with: data) as? [Any] { items = json }
        // Decode manually to model
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        // Map each dict to WorkoutSession via re-encoding
        return try items.compactMap { obj in
            guard let dict = obj as? [String: Any] else { return nil }
            // Build a DTO that matches WorkoutSession
            struct DTO: Codable {
                let id: UUID?
                let title: String
                let occurred_at: Date
                let duration_seconds: Int
                let exercises: [CompletedExercise]
                let muscle_groups: [String]
                let calories_burned: Int?
                let average_heart_rate: Int?
            }
            let dtoData = try JSONSerialization.data(withJSONObject: dict, options: [])
            let dto = try decoder.decode(DTO.self, from: dtoData)
            return WorkoutSession(
                id: dto.id ?? UUID(),
                title: dto.title,
                date: dto.occurred_at,
                duration: TimeInterval(dto.duration_seconds),
                exercises: dto.exercises,
                muscleGroups: dto.muscle_groups.compactMap { MuscleGroup(rawValue: $0) },
                caloriesBurned: dto.calories_burned ?? 0,
                averageHeartRate: dto.average_heart_rate ?? 0
            )
        }
    }
    
    // Achievements
    func saveFitnessAchievements(userId: UUID, _ achievements: [FitnessAchievement]) async throws {
        isLoading = true
        defer { isLoading = false }
        struct Row: Encodable {
            let user_id: String
            let achievement_key: String
            let title: String
            let description: String?
            let emoji: String?
            let is_unlocked: Bool
            let unlocked_at: String?
            let required_value: Int?
        }
        let iso = ISO8601DateFormatter()
        let rows = achievements.map { a in
            Row(
                user_id: userId.uuidString,
                achievement_key: a.id,
                title: a.title,
                description: a.description,
                emoji: a.emoji,
                is_unlocked: a.isUnlocked,
                unlocked_at: a.unlockedDate.map { iso.string(from: $0) },
                required_value: a.requiredValue
            )
        }
        let body = try JSONEncoder().encode(rows)
        _ = try await restRequest(
            path: "fitness_achievements",
            method: "POST",
            query: [URLQueryItem(name: "on_conflict", value: "user_id,achievement_key")],
            body: body,
            prefer: "resolution=merge-duplicates,return=minimal"
        )
    }
    
    func getFitnessAchievements(for userId: UUID) async throws -> [FitnessAchievement] {
        isLoading = true
        defer { isLoading = false }
        let data = try await restRequest(
            path: "fitness_achievements",
            method: "GET",
            query: [
                URLQueryItem(name: "select", value: "*"),
                URLQueryItem(name: "user_id", value: "eq.\(userId.uuidString)")
            ]
        )
        let decoder = JSONDecoder()
        struct Row: Decodable {
            let achievement_key: String
            let title: String
            let description: String?
            let emoji: String?
            let is_unlocked: Bool
            let unlocked_at: String?
            let required_value: Int?
        }
        let rows = try decoder.decode([Row].self, from: data)
        return rows.map { r in
            FitnessAchievement(
                id: r.achievement_key,
                title: r.title,
                description: r.description ?? "",
                emoji: r.emoji ?? "🏆",
                isUnlocked: r.is_unlocked,
                unlockedDate: (r.unlocked_at != nil ? ISO8601DateFormatter().date(from: r.unlocked_at!) : nil) ?? Date(),
                requiredValue: r.required_value ?? 0
            )
        }
    }
    
    // Weekly Stats
    func upsertWeeklyStats(userId: UUID, weekStart: Date, stats: WeeklyStats) async throws {
        isLoading = true
        defer { isLoading = false }
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        _ = try await rpc("upsert_weekly_stats", payload: [
            "p_week_start": df.string(from: weekStart),
            "p_workouts_completed": stats.workoutsCompleted,
            "p_total_time_seconds": Int(stats.totalTime),
            "p_calories_burned": stats.caloriesBurned,
            "p_average_heart_rate": stats.averageHeartRate
        ])
    }
    
    func getWeeklyStats(for userId: UUID, weekStart: Date) async throws -> WeeklyStats? {
        isLoading = true
        defer { isLoading = false }
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let data = try await restRequest(
            path: "fitness_weekly_stats",
            method: "GET",
            query: [
                URLQueryItem(name: "select", value: "*"),
                URLQueryItem(name: "user_id", value: "eq.\(userId.uuidString)"),
                URLQueryItem(name: "week_start", value: "eq.\(df.string(from: weekStart))")
            ]
        )
        struct Row: Decodable { let workouts_completed: Int; let total_time_seconds: Int; let calories_burned: Int; let average_heart_rate: Int }
        let rows = try JSONDecoder().decode([Row].self, from: data)
        guard let r = rows.first else { return nil }
        return WeeklyStats(
            workoutsCompleted: r.workouts_completed,
            totalTime: TimeInterval(r.total_time_seconds),
            caloriesBurned: r.calories_burned,
            averageHeartRate: r.average_heart_rate
        )
    }
    
    // Streaks
    func setStreak(userId: UUID, count: Int) async throws {
        isLoading = true
        defer { isLoading = false }
        _ = try await rpc("set_streak", payload: ["count": count])
    }
    
    func getStreak(for userId: UUID) async throws -> Int {
        isLoading = true
        defer { isLoading = false }
        let data = try await restRequest(
            path: "fitness_streaks",
            method: "GET",
            query: [
                URLQueryItem(name: "select", value: "streak_count"),
                URLQueryItem(name: "user_id", value: "eq.\(userId.uuidString)"),
                URLQueryItem(name: "limit", value: "1")
            ]
        )
        struct Row: Decodable { let streak_count: Int }
        let rows = try JSONDecoder().decode([Row].self, from: data)
        return rows.first?.streak_count ?? 0
    }
    
    // MARK: - Chat Sessions
    
    func saveChatSession(_ session: ChatSession) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Simulate API call delay
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        // In real implementation:
        // try await supabaseClient.from(Config.Supabase.chatSessionsTable).insert(session).execute()
    }
    
    func getChatSessions(for userId: UUID) async throws -> [ChatSession] {
        isLoading = true
        defer { isLoading = false }
        
        // Simulate API call delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // In real implementation:
        // let sessions = try await supabaseClient.from(Config.Supabase.chatSessionsTable).select().eq("user_id", userId).execute()
        
        // Mock implementation
        return []
    }
    
    // MARK: - Real-time Subscriptions
    
    func subscribeToUserUpdates(userId: UUID, callback: @escaping (User) -> Void) {
        // In real implementation:
        // supabaseClient.from(Config.Supabase.usersTable)
        //     .on(.update) { payload in
        //         if let user = payload.new as? User, user.id == userId {
        //             callback(user)
        //         }
        //     }
        //     .subscribe()
    }
    
    func subscribeToProgressUpdates(userId: UUID, callback: @escaping (ProgressEntry) -> Void) {
        // In real implementation:
        // supabaseClient.from(Config.Supabase.progressTable)
        //     .on(.insert) { payload in
        //         if let entry = payload.new as? ProgressEntry, entry.userId == userId {
        //             callback(entry)
        //         }
        //     }
        //     .subscribe()
    }
}

// MARK: - Database Errors

enum DatabaseError: LocalizedError {
    case connectionFailed
    case invalidData(String)
    case duplicateEntry(String)
    case notFound
    case authenticationFailed(String)
    case networkError
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .connectionFailed:
            return "Failed to connect to the database"
        case .invalidData(let message):
            return message
        case .duplicateEntry(let message):
            return message
        case .notFound:
            return "Requested data not found"
        case .authenticationFailed(let message):
            return message
        case .networkError:
            return Config.ErrorMessages.networkError
        case .unknownError(let message):
            return message
        }
    }
}

// MARK: - Mock Data Creation

extension DatabaseService {
    private func createMockWorkoutPlans(for userId: UUID) -> [WorkoutPlan] {
        return [
            WorkoutPlan(
                id: UUID(),
                userId: userId,
                title: "Upper Body Strength",
                description: "Focus on building upper body strength with compound movements",
                difficultyLevel: .intermediate,
                estimatedDuration: 45,
                targetMuscleGroups: [.chest, .back, .shoulders, .biceps, .triceps],
                equipment: [.dumbbells],
                exercises: createMockExercises(),
                aiGeneratedNotes: "This workout is designed to build functional upper body strength. Focus on proper form over heavy weight.",
                createdAt: Date().addingTimeInterval(-86400), // Yesterday
                updatedAt: Date().addingTimeInterval(-86400)
            ),
            WorkoutPlan(
                id: UUID(),
                userId: userId,
                title: "HIIT Cardio Blast",
                description: "High-intensity interval training for maximum calorie burn",
                difficultyLevel: .advanced,
                estimatedDuration: 30,
                targetMuscleGroups: [.fullBody, .cardio],
                equipment: [.none],
                exercises: createMockCardioExercises(),
                aiGeneratedNotes: "Push yourself during the work intervals and use the rest periods to recover completely.",
                createdAt: Date().addingTimeInterval(-172800), // 2 days ago
                updatedAt: Date().addingTimeInterval(-172800)
            )
        ]
    }
    
    private func createMockExercises() -> [Exercise] {
        return [
            Exercise(
                id: UUID(),
                name: "Push-ups",
                description: "Classic bodyweight exercise for chest, shoulders, and triceps",
                muscleGroups: [.chest, .shoulders, .triceps],
                equipment: Equipment.none,
                sets: 3,
                reps: "10-15",
                weight: "bodyweight",
                restTime: 60,
                instructions: [
                    "Start in plank position with hands slightly wider than shoulders",
                    "Lower your body until chest nearly touches the floor",
                    "Push back up to starting position",
                    "Keep your core tight throughout the movement"
                ],
                tips: [
                    "Keep your body in a straight line",
                    "Don't let your hips sag or pike up",
                    "Control the descent - don't drop down quickly"
                ],
                modifications: [
                    ExerciseModification(
                        type: .easier,
                        description: "Knee Push-ups",
                        instructions: "Perform push-ups from your knees instead of toes"
                    ),
                    ExerciseModification(
                        type: .harder,
                        description: "Diamond Push-ups",
                        instructions: "Place hands in diamond shape under your chest"
                    )
                ],
                videoUrl: nil,
                imageUrl: nil
            )
        ]
    }
    
    private func createMockCardioExercises() -> [Exercise] {
        return [
            Exercise(
                id: UUID(),
                name: "Burpees",
                description: "Full-body explosive movement combining squat, plank, and jump",
                muscleGroups: [.fullBody, .cardio],
                equipment: Equipment.none,
                sets: 4,
                reps: "30 seconds",
                weight: "bodyweight",
                restTime: 30,
                instructions: [
                    "Start standing with feet shoulder-width apart",
                    "Drop into squat position and place hands on floor",
                    "Jump feet back into plank position",
                    "Do a push-up (optional)",
                    "Jump feet back to squat position",
                    "Explode up with arms overhead"
                ],
                tips: [
                    "Land softly on your feet",
                    "Keep your core engaged throughout",
                    "Modify by stepping back instead of jumping"
                ],
                modifications: [
                    ExerciseModification(
                        type: .easier,
                        description: "Step-back Burpees",
                        instructions: "Step back into plank instead of jumping"
                    )
                ],
                videoUrl: nil,
                imageUrl: nil
            )
        ]
    }
    
    private func createMockMealPlans(for userId: UUID) -> [MealPlan] {
        return [
            MealPlan(
                id: UUID(),
                userId: userId,
                title: "Balanced Daily Nutrition",
                description: "Well-rounded meals for optimal health and energy",
                targetCalories: 2000,
                macroBreakdown: MacroBreakdown(protein: 150, carbs: 200, fat: 67, fiber: 30),
                meals: createMockMeals(),
                shoppingList: [
                    "Chicken breast",
                    "Brown rice",
                    "Broccoli",
                    "Sweet potato",
                    "Greek yogurt",
                    "Berries",
                    "Almonds",
                    "Olive oil"
                ],
                prepTime: 60,
                aiGeneratedNotes: "This meal plan provides balanced nutrition with adequate protein for muscle recovery and complex carbs for sustained energy.",
                createdAt: Date().addingTimeInterval(-86400),
                updatedAt: Date().addingTimeInterval(-86400)
            )
        ]
    }
    
    private func createMockMeals() -> [Meal] {
        return [
            Meal(
                id: UUID(),
                type: .breakfast,
                name: "Greek Yogurt Berry Bowl",
                description: "Protein-rich breakfast with antioxidant-packed berries",
                calories: 350,
                macros: MacroBreakdown(protein: 25, carbs: 35, fat: 12, fiber: 8),
                ingredients: createMockIngredients(),
                instructions: [
                    "Add Greek yogurt to a bowl",
                    "Top with mixed berries",
                    "Sprinkle with granola and nuts",
                    "Drizzle with honey if desired"
                ],
                prepTime: 5,
                cookTime: 0,
                servings: 1,
                difficulty: .beginner,
                tags: ["high-protein", "quick", "healthy"],
                imageUrl: nil
            )
        ]
    }
    
    private func createMockIngredients() -> [Ingredient] {
        return [
            Ingredient(
                id: UUID(),
                name: "Greek Yogurt",
                amount: 200,
                unit: "g",
                calories: 130,
                macros: MacroBreakdown(protein: 20, carbs: 9, fat: 0, fiber: 0),
                isOptional: false,
                substitutes: ["Regular yogurt", "Cottage cheese"]
            ),
            Ingredient(
                id: UUID(),
                name: "Mixed Berries",
                amount: 100,
                unit: "g",
                calories: 60,
                macros: MacroBreakdown(protein: 1, carbs: 14, fat: 0, fiber: 6),
                isOptional: false,
                substitutes: ["Banana", "Apple slices"]
            )
        ]
    }
    
    private func createMockProgressEntries(for userId: UUID, from startDate: Date, to endDate: Date) -> [ProgressEntry] {
        var entries: [ProgressEntry] = []
        let calendar = Calendar.current
        var currentDate = startDate
        
        while currentDate <= endDate {
            let entry = ProgressEntry(
                id: UUID(),
                userId: userId,
                date: currentDate,
                workoutCompleted: Bool.random(),
                workoutPlanId: UUID(),
                exercisesCompleted: [],
                mealsLogged: [],
                bodyMetrics: BodyMetrics(
                    weight: 70.0 + Double.random(in: -2...2),
                    bodyFatPercentage: 15.0 + Double.random(in: -1...1),
                    muscleMass: 55.0 + Double.random(in: -1...1),
                    measurements: ["waist": 85.0, "chest": 100.0]
                ),
                mood: MoodRating.allCases.randomElement(),
                energyLevel: EnergyLevel.allCases.randomElement(),
                notes: "Feeling good today!",
                createdAt: currentDate
            )
            entries.append(entry)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? endDate
        }
        
        return entries
    }
}

// MARK: - Placeholder for Supabase Client

// This would be replaced with the actual Supabase Swift client
struct SupabaseClient {
    let url: String
    let key: String
    
    init(supabaseURL: String, supabaseKey: String) {
        self.url = supabaseURL
        self.key = supabaseKey
    }
}

// MARK: - Chat Session Model (referenced in database service)

struct ChatSession: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let messages: [ChatMessage]
    let sessionType: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, messages, createdAt
        case userId = "user_id"
        case sessionType = "session_type"
    }
}

struct ChatMessage: Codable, Identifiable {
    let id: UUID
    let role: MessageRole
    let content: String
    let timestamp: Date
    
    enum MessageRole: String, Codable {
        case user = "user"
        case assistant = "assistant"
        case system = "system"
    }
}