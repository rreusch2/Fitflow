//
//  PlanModels.swift
//  Fitflow
//
//  Created on 2025-01-13
//

import Foundation
import SwiftUI

// MARK: - Workout Plan
struct WorkoutPlan: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let title: String
    let description: String
    let difficultyLevel: FitnessLevel
    let estimatedDuration: Int // in minutes
    let targetMuscleGroups: [MuscleGroup]
    let equipment: [Equipment]
    let exercises: [Exercise]
    let aiGeneratedNotes: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, exercises, createdAt, updatedAt
        case userId = "user_id"
        case difficultyLevel = "difficulty_level"
        case estimatedDuration = "estimated_duration"
        case targetMuscleGroups = "target_muscle_groups"
        case equipment
        case aiGeneratedNotes = "ai_generated_notes"
    }
}

struct Exercise: Codable, Identifiable {
    let id: UUID
    let name: String
    let description: String
    let muscleGroups: [MuscleGroup]
    let equipment: Equipment?
    let sets: Int?
    let reps: String? // Can be "10-12" or "30 seconds"
    let weight: String? // Can be "bodyweight" or "15 lbs"
    let restTime: Int? // in seconds
    let instructions: [String]
    let tips: [String]
    let modifications: [ExerciseModification]
    let videoUrl: String?
    let imageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, equipment, sets, reps, weight, instructions, tips, modifications
        case muscleGroups = "muscle_groups"
        case restTime = "rest_time"
        case videoUrl = "video_url"
        case imageUrl = "image_url"
    }
}

struct ExerciseModification: Codable {
    let type: ModificationType
    let description: String
    let instructions: String
}

enum ModificationType: String, Codable, CaseIterable {
    case easier = "easier"
    case harder = "harder"
    case lowImpact = "low_impact"
    case noEquipment = "no_equipment"
    case injury = "injury"
    
    var displayName: String {
        switch self {
        case .easier: return "Easier Version"
        case .harder: return "Harder Version"
        case .lowImpact: return "Low Impact"
        case .noEquipment: return "No Equipment"
        case .injury: return "Injury Modification"
        }
    }
}

enum MuscleGroup: String, Codable, CaseIterable {
    case chest = "chest"
    case back = "back"
    case shoulders = "shoulders"
    case biceps = "biceps"
    case triceps = "triceps"
    case forearms = "forearms"
    case abs = "abs"
    case obliques = "obliques"
    case lowerBack = "lower_back"
    case glutes = "glutes"
    case quadriceps = "quadriceps"
    case hamstrings = "hamstrings"
    case calves = "calves"
    case fullBody = "full_body"
    case cardio = "cardio"
    
    var displayName: String {
        switch self {
        case .chest: return "Chest"
        case .back: return "Back"
        case .shoulders: return "Shoulders"
        case .biceps: return "Biceps"
        case .triceps: return "Triceps"
        case .forearms: return "Forearms"
        case .abs: return "Abs"
        case .obliques: return "Obliques"
        case .lowerBack: return "Lower Back"
        case .glutes: return "Glutes"
        case .quadriceps: return "Quadriceps"
        case .hamstrings: return "Hamstrings"
        case .calves: return "Calves"
        case .fullBody: return "Full Body"
        case .cardio: return "Cardio"
        }
    }
    
    var icon: String {
        switch self {
        case .chest: return "figure.strengthtraining.traditional"
        case .back: return "figure.strengthtraining.traditional"
        case .shoulders: return "figure.strengthtraining.traditional"
        case .biceps, .triceps, .forearms: return "arm.flex"
        case .abs, .obliques: return "figure.core.training"
        case .lowerBack: return "figure.strengthtraining.traditional"
        case .glutes, .quadriceps, .hamstrings, .calves: return "figure.strengthtraining.traditional"
        case .fullBody: return "figure.strengthtraining.functional"
        case .cardio: return "heart.fill"
        }
    }
}

// MARK: - Meal Plan
struct MealPlan: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let title: String
    let description: String
    let targetCalories: Int
    let macroBreakdown: MacroBreakdown
    let meals: [Meal]
    let shoppingList: [String]
    let prepTime: Int // in minutes
    let aiGeneratedNotes: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, meals, createdAt, updatedAt
        case userId = "user_id"
        case targetCalories = "target_calories"
        case macroBreakdown = "macro_breakdown"
        case shoppingList = "shopping_list"
        case prepTime = "prep_time"
        case aiGeneratedNotes = "ai_generated_notes"
    }
}

struct MacroBreakdown: Codable {
    let protein: Int // in grams
    let carbs: Int // in grams
    let fat: Int // in grams
    let fiber: Int // in grams
    
    var proteinPercentage: Double {
        let totalCalories = (protein * 4) + (carbs * 4) + (fat * 9)
        return totalCalories > 0 ? Double(protein * 4) / Double(totalCalories) * 100 : 0
    }
    
    var carbsPercentage: Double {
        let totalCalories = (protein * 4) + (carbs * 4) + (fat * 9)
        return totalCalories > 0 ? Double(carbs * 4) / Double(totalCalories) * 100 : 0
    }
    
    var fatPercentage: Double {
        let totalCalories = (protein * 4) + (carbs * 4) + (fat * 9)
        return totalCalories > 0 ? Double(fat * 9) / Double(totalCalories) * 100 : 0
    }
}

struct Meal: Codable, Identifiable {
    let id: UUID
    let type: MealType
    let name: String
    let description: String
    let calories: Int
    let macros: MacroBreakdown
    let ingredients: [Ingredient]
    let instructions: [String]
    let prepTime: Int // in minutes
    let cookTime: Int // in minutes
    let servings: Int
    let difficulty: CookingSkill
    let tags: [String]
    let imageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id, type, name, description, calories, macros, ingredients, instructions, servings, difficulty, tags
        case prepTime = "prep_time"
        case cookTime = "cook_time"
        case imageUrl = "image_url"
    }
}

enum MealType: String, Codable, CaseIterable {
    case breakfast = "breakfast"
    case lunch = "lunch"
    case dinner = "dinner"
    case snack = "snack"
    case preworkout = "preworkout"
    case postworkout = "postworkout"
    
    var displayName: String {
        switch self {
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .snack: return "Snack"
        case .preworkout: return "Pre-Workout"
        case .postworkout: return "Post-Workout"
        }
    }
    
    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.fill"
        case .snack: return "leaf.fill"
        case .preworkout: return "bolt.fill"
        case .postworkout: return "checkmark.circle.fill"
        }
    }
    
    var emoji: String {
        switch self {
        case .breakfast: return "🌅"
        case .lunch: return "☀️"
        case .dinner: return "🌙"
        case .snack: return "🍎"
        case .preworkout: return "⚡"
        case .postworkout: return "💪"
        }
    }
    
    var color: Color {
        switch self {
        case .breakfast: return .orange
        case .lunch: return .yellow
        case .dinner: return .purple
        case .snack: return .green
        case .preworkout: return .blue
        case .postworkout: return .red
        }
    }
}

struct Ingredient: Codable, Identifiable {
    let id: UUID
    let name: String
    let amount: Double
    let unit: String
    let calories: Int
    let macros: MacroBreakdown
    let isOptional: Bool
    let substitutes: [String]
    
    enum CodingKeys: String, CodingKey {
        case id, name, amount, unit, calories, macros, substitutes
        case isOptional = "is_optional"
    }
}

// MARK: - Progress Tracking
struct ProgressEntry: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let date: Date
    let workoutCompleted: Bool
    let workoutPlanId: UUID?
    let exercisesCompleted: [ExerciseProgress]
    let mealsLogged: [MealProgress]
    let bodyMetrics: BodyMetrics?
    let mood: MoodRating?
    let energyLevel: EnergyLevel?
    let notes: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, date, notes, createdAt
        case userId = "user_id"
        case workoutCompleted = "workout_completed"
        case workoutPlanId = "workout_plan_id"
        case exercisesCompleted = "exercises_completed"
        case mealsLogged = "meals_logged"
        case bodyMetrics = "body_metrics"
        case mood
        case energyLevel = "energy_level"
    }
}

struct ExerciseProgress: Codable, Identifiable {
    let id: UUID
    let exerciseId: UUID
    let completed: Bool
    let actualSets: Int?
    let actualReps: [Int]? // Array for each set
    let actualWeight: [Double]? // Array for each set
    let restTime: [Int]? // Array for each rest period
    let difficulty: DifficultyRating?
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case id, completed, notes
        case exerciseId = "exercise_id"
        case actualSets = "actual_sets"
        case actualReps = "actual_reps"
        case actualWeight = "actual_weight"
        case restTime = "rest_time"
        case difficulty
    }
}

struct MealProgress: Codable, Identifiable {
    let id: UUID
    let mealId: UUID?
    let mealType: MealType
    let consumed: Bool
    let actualCalories: Int?
    let actualMacros: MacroBreakdown?
    let satisfaction: SatisfactionRating?
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case id, consumed, notes
        case mealId = "meal_id"
        case mealType = "meal_type"
        case actualCalories = "actual_calories"
        case actualMacros = "actual_macros"
        case satisfaction
    }
}

struct BodyMetrics: Codable {
    let weight: Double? // in kg
    let bodyFatPercentage: Double?
    let muscleMass: Double? // in kg
    let measurements: [String: Double]? // e.g., "waist": 85.0, "chest": 100.0
    
    enum CodingKeys: String, CodingKey {
        case weight, measurements
        case bodyFatPercentage = "body_fat_percentage"
        case muscleMass = "muscle_mass"
    }
}

enum MoodRating: String, Codable, CaseIterable {
    case terrible = "terrible"
    case poor = "poor"
    case okay = "okay"
    case good = "good"
    case excellent = "excellent"
    
    var displayName: String {
        switch self {
        case .terrible: return "Terrible"
        case .poor: return "Poor"
        case .okay: return "Okay"
        case .good: return "Good"
        case .excellent: return "Excellent"
        }
    }
    
    var emoji: String {
        switch self {
        case .terrible: return "😞"
        case .poor: return "😕"
        case .okay: return "😐"
        case .good: return "😊"
        case .excellent: return "😄"
        }
    }
    
    var value: Int {
        switch self {
        case .terrible: return 1
        case .poor: return 2
        case .okay: return 3
        case .good: return 4
        case .excellent: return 5
        }
    }
}

enum EnergyLevel: String, Codable, CaseIterable {
    case veryLow = "very_low"
    case low = "low"
    case moderate = "moderate"
    case high = "high"
    case veryHigh = "very_high"
    
    var displayName: String {
        switch self {
        case .veryLow: return "Very Low"
        case .low: return "Low"
        case .moderate: return "Moderate"
        case .high: return "High"
        case .veryHigh: return "Very High"
        }
    }
    
    var emoji: String {
        switch self {
        case .veryLow: return "🔋"
        case .low: return "🪫"
        case .moderate: return "🔋"
        case .high: return "⚡"
        case .veryHigh: return "⚡⚡"
        }
    }
    
    var value: Int {
        switch self {
        case .veryLow: return 1
        case .low: return 2
        case .moderate: return 3
        case .high: return 4
        case .veryHigh: return 5
        }
    }
}

enum DifficultyRating: String, Codable, CaseIterable {
    case tooEasy = "too_easy"
    case easy = "easy"
    case justRight = "just_right"
    case hard = "hard"
    case tooHard = "too_hard"
    
    var displayName: String {
        switch self {
        case .tooEasy: return "Too Easy"
        case .easy: return "Easy"
        case .justRight: return "Just Right"
        case .hard: return "Hard"
        case .tooHard: return "Too Hard"
        }
    }
    
    var emoji: String {
        switch self {
        case .tooEasy: return "😴"
        case .easy: return "😌"
        case .justRight: return "😊"
        case .hard: return "😅"
        case .tooHard: return "😰"
        }
    }
}

enum SatisfactionRating: String, Codable, CaseIterable {
    case hated = "hated"
    case disliked = "disliked"
    case neutral = "neutral"
    case liked = "liked"
    case loved = "loved"
    
    var displayName: String {
        switch self {
        case .hated: return "Hated It"
        case .disliked: return "Disliked"
        case .neutral: return "Neutral"
        case .liked: return "Liked It"
        case .loved: return "Loved It"
        }
    }
    
    var emoji: String {
        switch self {
        case .hated: return "🤢"
        case .disliked: return "👎"
        case .neutral: return "😐"
        case .liked: return "👍"
        case .loved: return "😍"
        }
    }
}