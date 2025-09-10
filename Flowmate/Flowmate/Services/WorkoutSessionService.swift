//
//  WorkoutSessionService.swift
//  Flowmate
//
//  Created on 2025-09-10
//

import Foundation
import Combine

@MainActor
class WorkoutSessionService: ObservableObject {
    static let shared = WorkoutSessionService()
    
    @Published var isLogging = false
    @Published var sessions: [WorkoutSession] = []
    @Published var weeklyStats: WeeklyStats?
    @Published var currentStreak: Int = 0
    
    private let baseURL = "https://fitflow-production.up.railway.app"
    
    private init() {}
    
    // MARK: - Models
    struct WorkoutSession: Codable, Identifiable {
        let id: String
        let userId: String
        let workoutType: String
        let durationMinutes: Int?
        let exercisesCompleted: [CompletedExercise]
        let notes: String?
        let completedAt: Date
        let muscleGroups: [String]
        let createdAt: Date
        
        enum CodingKeys: String, CodingKey {
            case id, notes
            case userId = "user_id"
            case workoutType = "workout_type"
            case durationMinutes = "duration_minutes"
            case exercisesCompleted = "exercises_completed"
            case completedAt = "completed_at"
            case muscleGroups = "muscle_groups"
            case createdAt = "created_at"
        }
    }
    
    struct CompletedExercise: Codable {
        let name: String
        let sets: Int?
        let reps: String?
        let weight: String?
        let notes: String?
    }
    
    struct WeeklyStats: Codable {
        let workoutsCompleted: Int
        let totalTimeMinutes: Int
        let averageDuration: Int
        let favoritesMuscleGroups: [String]
        
        enum CodingKeys: String, CodingKey {
            case workoutsCompleted = "workouts_completed"
            case totalTimeMinutes = "total_time_minutes"
            case averageDuration = "average_duration"
            case favoritesMuscleGroups = "favorites_muscle_groups"
        }
    }
    
    // MARK: - API Methods
    
    /// Log a completed manual workout
    func logManualWorkout(
        type: String,
        duration: Int?,
        exercises: [CompletedExercise],
        muscleGroups: [String],
        notes: String? = nil
    ) async -> Bool {
        return await logWorkout(
            type: type,
            duration: duration,
            exercises: exercises,
            muscleGroups: muscleGroups,
            notes: notes
        )
    }
    
    /// Log completion of an AI-generated workout
    func logAIWorkoutCompletion(
        workoutPlan: WorkoutPlanResponse,
        duration: Int?,
        completedExercises: [CompletedExercise],
        notes: String? = nil
    ) async -> Bool {
        return await logWorkout(
            type: "ai_generated",
            duration: duration,
            exercises: completedExercises,
            muscleGroups: workoutPlan.target_muscle_groups,
            notes: notes
        )
    }
    
    private func logWorkout(
        type: String,
        duration: Int?,
        exercises: [CompletedExercise],
        muscleGroups: [String],
        notes: String?
    ) async -> Bool {
        isLogging = true
        defer { isLogging = false }
        
        guard let url = URL(string: "\(baseURL)/v1/fitness/workout-sessions") else { return false }
        
        let payload = [
            "workout_type": type,
            "duration_minutes": duration as Any,
            "exercises_completed": exercises,
            "muscle_groups": muscleGroups,
            "notes": notes as Any
        ] as [String: Any]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "auth_access_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                HapticFeedback.success()
                await fetchRecentSessions() // Refresh the list
                return true
            }
            return false
        } catch {
            print("Failed to log workout: \(error)")
            return false
        }
    }
    
    /// Fetch recent workout sessions
    func fetchRecentSessions() async {
        guard let url = URL(string: "\(baseURL)/v1/fitness/workout-sessions") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = UserDefaults.standard.string(forKey: "auth_access_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode([String: [WorkoutSession]].self, from: data)
            self.sessions = response["sessions"] ?? []
        } catch {
            print("Failed to fetch sessions: \(error)")
        }
    }
    
    /// Fetch progress statistics
    func fetchWeeklyStats() async {
        guard let url = URL(string: "\(baseURL)/v1/fitness/weekly-stats") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = UserDefaults.standard.string(forKey: "auth_access_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode([String: Any].self, from: data) as? [String: Any]
            // Parse weekly stats and current streak from response
            if let stats = response?["weekly_stats"] as? [String: Any] {
                self.weeklyStats = try? JSONSerialization.data(withJSONObject: stats).decoded() as WeeklyStats
            }
            if let streak = response?["current_streak"] as? Int {
                self.currentStreak = streak
            }
        } catch {
            print("Failed to fetch weekly stats: \(error)")
        }
    }
}

// MARK: - Data Extension
private extension Data {
    func decoded<T: Decodable>() throws -> T {
        return try JSONDecoder().decode(T.self, from: self)
    }
}
