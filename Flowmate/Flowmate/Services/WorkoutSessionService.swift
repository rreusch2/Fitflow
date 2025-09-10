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
        
        // Convert exercises to JSON-serializable format
        let exercisesData = exercises.map { exercise -> [String: Any] in
            var exerciseDict: [String: Any] = ["name": exercise.name]
            if let sets = exercise.sets { exerciseDict["sets"] = sets }
            if let reps = exercise.reps { exerciseDict["reps"] = reps }
            if let weight = exercise.weight { exerciseDict["weight"] = weight }
            if let notes = exercise.notes { exerciseDict["notes"] = notes }
            return exerciseDict
        }
        
        var payload: [String: Any] = [
            "workout_type": type,
            "exercises_completed": exercisesData,
            "muscle_groups": muscleGroups
        ]
        
        if let duration = duration { payload["duration_minutes"] = duration }
        if let notes = notes { payload["notes"] = notes }
        
        do {
            let (_, http) = try await BackendAPIClient.shared.sendJSON(path: "fitness/workout-sessions", method: "POST", json: payload)
            print("🔥 HTTP Status: \(http.statusCode)")
            if (200...299).contains(http.statusCode) {
                HapticFeedback.success()
                await fetchRecentSessions() // Refresh the list
                return true
            } else {
                print("🔥 Server error: \(http.statusCode)")
                return false
            }
        } catch {
            print("🔥 Failed to log workout: \(error)")
            print("🔥 Payload: \(payload)")
            return false
        }
    }
    
    /// Fetch recent workout sessions
    func fetchRecentSessions() async {
        do {
            let (data, http) = try await BackendAPIClient.shared.get(path: "fitness/workout-sessions")
            print("🔥 Fetch sessions HTTP: \(http.statusCode)")
            let response = try JSONDecoder().decode([String: [WorkoutSession]].self, from: data)
            self.sessions = response["sessions"] ?? []
        } catch {
            print("Failed to fetch sessions: \(error)")
        }
    }
    
    /// Fetch progress statistics
    func fetchWeeklyStats() async {
        do {
            let (data, http) = try await BackendAPIClient.shared.get(path: "fitness/weekly-stats")
            print("🔥 Weekly stats HTTP: \(http.statusCode)")
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // Parse weekly stats and current streak from response
                if let stats = json["weekly_stats"] as? [String: Any] {
                    let statsData = try JSONSerialization.data(withJSONObject: stats)
                    self.weeklyStats = try JSONDecoder().decode(WeeklyStats.self, from: statsData)
                }
                if let streak = json["current_streak"] as? Int {
                    self.currentStreak = streak
                }
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
