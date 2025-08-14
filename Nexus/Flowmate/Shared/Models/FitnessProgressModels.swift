//
//  FitnessProgressModels.swift
//  Flowmate
//
//  Created on 2025-01-13
//

import Foundation

// MARK: - Workout Session

struct WorkoutSession: Codable, Identifiable {
    let id: UUID
    let title: String
    let date: Date
    let duration: TimeInterval // in seconds
    let exercises: [CompletedExercise]
    let muscleGroups: [MuscleGroup]
    let caloriesBurned: Int
    let averageHeartRate: Int
    let notes: String?
    
    init(id: UUID = UUID(), title: String, date: Date, duration: TimeInterval, exercises: [CompletedExercise], muscleGroups: [MuscleGroup], caloriesBurned: Int, averageHeartRate: Int, notes: String? = nil) {
        self.id = id
        self.title = title
        self.date = date
        self.duration = duration
        self.exercises = exercises
        self.muscleGroups = muscleGroups
        self.caloriesBurned = caloriesBurned
        self.averageHeartRate = averageHeartRate
        self.notes = notes
    }
}

// MARK: - Completed Exercise

struct CompletedExercise: Codable, Identifiable {
    let id: UUID
    let name: String
    let sets: Int
    let reps: Int
    let weight: Double? // in lbs/kg
    let restTime: TimeInterval
    let completed: Bool
    let notes: String?
    
    init(id: UUID = UUID(), name: String, sets: Int, reps: Int, weight: Double? = nil, restTime: TimeInterval, completed: Bool, notes: String? = nil) {
        self.id = id
        self.name = name
        self.sets = sets
        self.reps = reps
        self.weight = weight
        self.restTime = restTime
        self.completed = completed
        self.notes = notes
    }
}

// MARK: - Fitness Achievement

struct FitnessAchievement: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let emoji: String
    var isUnlocked: Bool
    var unlockedDate: Date?
    let requiredValue: Int
    
    init(id: String, title: String, description: String, emoji: String, isUnlocked: Bool = false, unlockedDate: Date? = nil, requiredValue: Int) {
        self.id = id
        self.title = title
        self.description = description
        self.emoji = emoji
        self.isUnlocked = isUnlocked
        self.unlockedDate = unlockedDate
        self.requiredValue = requiredValue
    }
}

// MARK: - Weekly Stats

struct WeeklyStats: Codable {
    let workoutsCompleted: Int
    let totalTime: TimeInterval
    let caloriesBurned: Int
    let averageHeartRate: Int
    
    init(workoutsCompleted: Int = 0, totalTime: TimeInterval = 0, caloriesBurned: Int = 0, averageHeartRate: Int = 0) {
        self.workoutsCompleted = workoutsCompleted
        self.totalTime = totalTime
        self.caloriesBurned = caloriesBurned
        self.averageHeartRate = averageHeartRate
    }
}

// MARK: - Progress Metrics

struct ProgressMetrics {
    let workoutFrequency: Double
    let consistencyScore: Double
    let strengthProgress: Double
    let totalWorkoutTime: TimeInterval
    let totalCaloriesBurned: Int
    let averageHeartRate: Int
    
    init(workoutFrequency: Double = 0, consistencyScore: Double = 0, strengthProgress: Double = 0, totalWorkoutTime: TimeInterval = 0, totalCaloriesBurned: Int = 0, averageHeartRate: Int = 0) {
        self.workoutFrequency = workoutFrequency
        self.consistencyScore = consistencyScore
        self.strengthProgress = strengthProgress
        self.totalWorkoutTime = totalWorkoutTime
        self.totalCaloriesBurned = totalCaloriesBurned
        self.averageHeartRate = averageHeartRate
    }
}

// MARK: - Time Frame

enum TimeFrame: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
}

// MARK: - Extensions

extension WorkoutSession {
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var muscleGroupsString: String {
        muscleGroups.map { $0.displayName }.joined(separator: ", ")
    }
}

extension TimeInterval {
    var formattedWorkoutTime: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

extension Double {
    var formattedPercentage: String {
        return String(format: "%.0f%%", self * 100)
    }
    
    var formattedProgress: String {
        if self >= 0 {
            return "+\(String(format: "%.0f%%", self * 100))"
        } else {
            return String(format: "%.0f%%", self * 100)
        }
    }
}
