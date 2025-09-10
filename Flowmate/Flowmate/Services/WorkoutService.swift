//
//  WorkoutService.swift
//  Flowmate
//
//  Created on 2025-01-13
//

import Foundation
import Combine

@MainActor
class WorkoutService: ObservableObject {
    static let shared = WorkoutService()
    
    @Published var isGeneratingWorkout = false
    @Published var lastError: String?
    
    private let baseURL = "https://fitflow-production.up.railway.app"
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Workout Generation
    
    func generateWorkout(
        muscleGroups: [MuscleGroup],
        workoutType: WorkoutType,
        duration: AIWorkoutDuration,
        difficulty: DifficultyLevel
    ) async throws -> WorkoutPlanResponse {
        isGeneratingWorkout = true
        defer { isGeneratingWorkout = false }
        
        // Check for auth token directly instead of relying on AuthService state
        let token = UserDefaults.standard.string(forKey: "auth_access_token")
        print("🔥 DEBUG: WorkoutService - Direct token check: \(token != nil ? "TOKEN FOUND" : "NO TOKEN")")
        
        guard token != nil else {
            print("🔥 DEBUG: WorkoutService - No auth token found, throwing notAuthenticated")
            throw WorkoutServiceError.notAuthenticated
        }
        
        // Map frontend enums to backend format
        let targetMuscleGroups = muscleGroups.map { $0.backendValue }
        let estimatedDuration = duration.minutes
        let difficultyLevel = difficulty.backendValue
        
        let requestBody = GenerateWorkoutRequest(
            difficulty_level: difficultyLevel,
            estimated_duration: estimatedDuration,
            target_muscle_groups: targetMuscleGroups,
            equipment: [], // Use user's default equipment
            preferred_activities: [workoutType.backendValue],
            limitations: []
        )
        
        do {
            let bodyData = try JSONEncoder().encode(requestBody)
            let bodyObj = try JSONSerialization.jsonObject(with: bodyData) as? [String: Any] ?? [:]
            print("🔥 DEBUG: WorkoutService - POST /ai/workout-plan with body: \(bodyObj)")
            let (data, http) = try await BackendAPIClient.shared.sendJSON(path: "ai/workout-plan", method: "POST", json: bodyObj)
            let responseText = String(data: data, encoding: .utf8) ?? ""
            print("🔥 DEBUG: WorkoutService - Response status: \(http.statusCode)")
            print("🔥 DEBUG: WorkoutService - Response body: \(responseText)")
            if http.statusCode == 401 {
                throw WorkoutServiceError.notAuthenticated
            }
            guard http.statusCode == 200 else {
                throw WorkoutServiceError.apiError("Status: \(http.statusCode), Message: \(responseText)")
            }
            let apiResponse = try JSONDecoder().decode(WorkoutAPIResponse.self, from: data)
            return apiResponse.plan
        } catch let error as WorkoutServiceError {
            lastError = error.localizedDescription
            throw error
        } catch {
            let errorMessage = "Network error: \(error.localizedDescription)"
            lastError = errorMessage
            throw WorkoutServiceError.networkError(errorMessage)
        }
    }
}

// MARK: - Request/Response Models

struct GenerateWorkoutRequest: Codable {
    let difficulty_level: String?
    let estimated_duration: Int?
    let target_muscle_groups: [String]?
    let equipment: [String]?
    let preferred_activities: [String]?
    let limitations: [String]?
}

struct WorkoutAPIResponse: Codable {
    let plan: WorkoutPlanResponse
}

struct WorkoutPlanResponse: Codable, Identifiable {
    let id: String
    let user_id: String
    let title: String
    let description: String
    let difficulty_level: String
    let estimated_duration: Int
    let target_muscle_groups: [String]
    let equipment: [String]
    let exercises: [ExerciseResponse]
    let ai_generated_notes: String?
    let created_at: String
    let updated_at: String
    
    // Computed properties for display
    var displayTitle: String { title }
    var displayDescription: String { description }
    var durationText: String { "\(estimated_duration) minutes" }
    var difficultyText: String { difficulty_level.capitalized }
    var muscleGroupsText: String {
        target_muscle_groups.map { $0.replacingOccurrences(of: "_", with: " ").capitalized }.joined(separator: ", ")
    }
    var aiNotes: String { ai_generated_notes ?? "" }
}

struct ExerciseResponse: Codable, Identifiable {
    let name: String
    let sets: Int?
    let reps: String?
    let rest_seconds: Int?
    let instructions: String
    let primary_muscle: String
    let equipment: String
    
    // Computed properties for display
    var id: String { name } // Use name as ID since backend doesn't provide UUID
    var displayName: String { name }
    var displayDescription: String { instructions }
    var setsRepsText: String {
        guard let sets = sets else { return "As prescribed" }
        if let reps = reps {
            return "\(sets) sets × \(reps)"
        }
        return "\(sets) sets"
    }
    var restTimeText: String {
        guard let restSeconds = rest_seconds else { return "" }
        return "Rest: \(restSeconds)s"
    }
    var equipmentText: String {
        equipment.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

struct ExerciseModificationResponse: Codable {
    let type: String
    let description: String
    let instructions: String
}

// MARK: - Extensions for Backend Mapping

extension MuscleGroup {
    var backendValue: String {
        switch self {
        case .chest: return "chest"
        case .back: return "back"  
        case .shoulders: return "shoulders"
        case .biceps: return "biceps"
        case .triceps: return "triceps"
        case .forearms: return "forearms"
        case .abs: return "abs"
        case .obliques: return "obliques"
        case .lowerBack: return "lower_back"
        case .glutes: return "glutes"
        case .quadriceps: return "quadriceps"
        case .hamstrings: return "hamstrings"
        case .calves: return "calves"
        case .fullBody: return "full_body"
        case .cardio: return "cardio"
        }
    }
}

extension WorkoutType {
    var backendValue: String {
        switch self {
        case .strength: return "strength"
        case .cardio: return "cardio"
        case .hiit: return "hiit"
        case .yoga: return "yoga"
        case .mobility: return "yoga" // Map mobility to yoga for backend
        }
    }
}

extension DifficultyLevel {
    var backendValue: String {
        switch self {
        case .beginner: return "beginner"
        case .intermediate: return "intermediate"
        case .advanced: return "advanced"
        }
    }
}

extension AIWorkoutDuration {
    var minutes: Int {
        switch self {
        case .short: return 30
        case .medium: return 45
        case .long: return 60
        }
    }
}

// MARK: - Errors

enum WorkoutServiceError: LocalizedError {
    case notAuthenticated
    case invalidResponse
    case apiError(String)
    case networkError(String)
    case parsingError(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please log in to generate workouts"
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(let message):
            return "API Error: \(message)"
        case .networkError(let message):
            return "Network Error: \(message)"
        case .parsingError(let message):
            return "Parsing Error: \(message)"
        }
    }
}
