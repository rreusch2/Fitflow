//
//  PreferenceModels.swift
//  NexusGPT
//
//  Created on 2025-01-13
//

import Foundation

// MARK: - Nutrition Preferences
struct NutritionPreferences: Codable {
    var dietaryRestrictions: [DietaryRestriction]
    var calorieGoal: CalorieGoal
    var mealPreferences: [MealPreference]
    var allergies: [String]
    var dislikedFoods: [String]
    var cookingSkill: CookingSkill
    var mealPrepTime: MealPrepTime
    
    enum CodingKeys: String, CodingKey {
        case allergies, dislikedFoods
        case dietaryRestrictions = "dietary_restrictions"
        case calorieGoal = "calorie_goal"
        case mealPreferences = "meal_preferences"
        case cookingSkill = "cooking_skill"
        case mealPrepTime = "meal_prep_time"
    }
}

enum DietaryRestriction: String, Codable, CaseIterable {
    case none = "none"
    case vegetarian = "vegetarian"
    case vegan = "vegan"
    case keto = "keto"
    case paleo = "paleo"
    case glutenFree = "gluten_free"
    case dairyFree = "dairy_free"
    case lowCarb = "low_carb"
    case mediterranean = "mediterranean"
    case intermittentFasting = "intermittent_fasting"
    
    var displayName: String {
        switch self {
        case .none: return "No Restrictions"
        case .vegetarian: return "Vegetarian"
        case .vegan: return "Vegan"
        case .keto: return "Ketogenic"
        case .paleo: return "Paleo"
        case .glutenFree: return "Gluten-Free"
        case .dairyFree: return "Dairy-Free"
        case .lowCarb: return "Low Carb"
        case .mediterranean: return "Mediterranean"
        case .intermittentFasting: return "Intermittent Fasting"
        }
    }
    
    var description: String {
        switch self {
        case .none: return "No dietary restrictions"
        case .vegetarian: return "No meat, but includes dairy and eggs"
        case .vegan: return "No animal products"
        case .keto: return "Very low carb, high fat"
        case .paleo: return "Whole foods, no processed foods"
        case .glutenFree: return "No gluten-containing grains"
        case .dairyFree: return "No dairy products"
        case .lowCarb: return "Reduced carbohydrate intake"
        case .mediterranean: return "Fish, olive oil, vegetables, whole grains"
        case .intermittentFasting: return "Time-restricted eating patterns"
        }
    }
}

enum CalorieGoal: String, Codable, CaseIterable {
    case loseWeight = "lose_weight"
    case maintain = "maintain"
    case gainWeight = "gain_weight"
    case buildMuscle = "build_muscle"
    
    var displayName: String {
        switch self {
        case .loseWeight: return "Lose Weight"
        case .maintain: return "Maintain Weight"
        case .gainWeight: return "Gain Weight"
        case .buildMuscle: return "Build Muscle"
        }
    }
    
    var description: String {
        switch self {
        case .loseWeight: return "Create a caloric deficit for weight loss"
        case .maintain: return "Maintain current weight and body composition"
        case .gainWeight: return "Increase overall body weight"
        case .buildMuscle: return "Gain lean muscle mass"
        }
    }
}

enum MealPreference: String, Codable, CaseIterable {
    case quickAndEasy = "quick_and_easy"
    case homeCooking = "home_cooking"
    case mealPrep = "meal_prep"
    case restaurantStyle = "restaurant_style"
    case comfort = "comfort"
    case international = "international"
    case healthy = "healthy"
    case budget = "budget"
    
    var displayName: String {
        switch self {
        case .quickAndEasy: return "Quick & Easy"
        case .homeCooking: return "Home Cooking"
        case .mealPrep: return "Meal Prep Friendly"
        case .restaurantStyle: return "Restaurant Style"
        case .comfort: return "Comfort Food"
        case .international: return "International Cuisine"
        case .healthy: return "Health-Focused"
        case .budget: return "Budget-Friendly"
        }
    }
}

enum CookingSkill: String, Codable, CaseIterable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    
    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }
    
    var description: String {
        switch self {
        case .beginner: return "Simple recipes with basic techniques"
        case .intermediate: return "Moderate complexity, some techniques"
        case .advanced: return "Complex recipes and advanced techniques"
        }
    }
}

enum MealPrepTime: String, Codable, CaseIterable {
    case minimal = "15"
    case moderate = "30"
    case extended = "60"
    case unlimited = "unlimited"
    
    var displayName: String {
        switch self {
        case .minimal: return "15 minutes or less"
        case .moderate: return "30 minutes"
        case .extended: return "1 hour"
        case .unlimited: return "No time limit"
        }
    }
}

// MARK: - Motivation Preferences
struct MotivationPreferences: Codable {
    var communicationStyle: CommunicationStyle
    var reminderFrequency: ReminderFrequency
    var motivationTriggers: [MotivationTrigger]
    var preferredTimes: [PreferredTime]
    
    enum CodingKeys: String, CodingKey {
        case communicationStyle = "communication_style"
        case reminderFrequency = "reminder_frequency"
        case motivationTriggers = "motivation_triggers"
        case preferredTimes = "preferred_times"
    }
}

enum CommunicationStyle: String, Codable, CaseIterable {
    case energetic = "energetic"
    case calm = "calm"
    case tough = "tough"
    case supportive = "supportive"
    case scientific = "scientific"
    case humorous = "humorous"
    
    var displayName: String {
        switch self {
        case .energetic: return "Energetic & Hype"
        case .calm: return "Calm & Mindful"
        case .tough: return "Tough Love"
        case .supportive: return "Supportive & Encouraging"
        case .scientific: return "Data-Driven & Scientific"
        case .humorous: return "Fun & Humorous"
        }
    }
    
    var description: String {
        switch self {
        case .energetic: return "High energy, motivational, like a personal trainer"
        case .calm: return "Peaceful, zen-like, mindfulness focused"
        case .tough: return "Direct, challenging, pushes you harder"
        case .supportive: return "Understanding, patient, celebrates small wins"
        case .scientific: return "Facts, data, research-based approach"
        case .humorous: return "Light-hearted, funny, makes fitness fun"
        }
    }
    
    var sampleMessage: String {
        switch self {
        case .energetic: return "LET'S GO! You've got this! Time to crush today's workout! 💪🔥"
        case .calm: return "Take a deep breath. You're exactly where you need to be. Let's move mindfully today. 🧘‍♀️"
        case .tough: return "No excuses today. You said you wanted results - time to earn them. Get moving."
        case .supportive: return "You're doing amazing! Every step counts, and I'm here to support you. 💙"
        case .scientific: return "Studies show consistency beats intensity. Your 3x/week routine is optimal for progress."
        case .humorous: return "Time to turn your body into a temple... or at least a decent shed! 😄"
        }
    }
}

enum ReminderFrequency: String, Codable, CaseIterable {
    case none = "none"
    case daily = "daily"
    case weekdays = "weekdays"
    case workoutDays = "workout_days"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .none: return "No Reminders"
        case .daily: return "Daily"
        case .weekdays: return "Weekdays Only"
        case .workoutDays: return "Workout Days Only"
        case .custom: return "Custom Schedule"
        }
    }
}

enum MotivationTrigger: String, Codable, CaseIterable {
    case morningBoost = "morning_boost"
    case preWorkout = "pre_workout"
    case postWorkout = "post_workout"
    case plateauBreaker = "plateau_breaker"
    case goalReminder = "goal_reminder"
    case progressCelebration = "progress_celebration"
    case badDayPickup = "bad_day_pickup"
    
    var displayName: String {
        switch self {
        case .morningBoost: return "Morning Motivation"
        case .preWorkout: return "Pre-Workout Hype"
        case .postWorkout: return "Post-Workout Celebration"
        case .plateauBreaker: return "Plateau Breaker"
        case .goalReminder: return "Goal Reminder"
        case .progressCelebration: return "Progress Celebration"
        case .badDayPickup: return "Bad Day Pick-Me-Up"
        }
    }
}

enum PreferredTime: String, Codable, CaseIterable {
    case earlyMorning = "early_morning"
    case morning = "morning"
    case afternoon = "afternoon"
    case evening = "evening"
    case night = "night"
    
    var displayName: String {
        switch self {
        case .earlyMorning: return "Early Morning (5-7 AM)"
        case .morning: return "Morning (7-11 AM)"
        case .afternoon: return "Afternoon (11 AM-5 PM)"
        case .evening: return "Evening (5-9 PM)"
        case .night: return "Night (9 PM-12 AM)"
        }
    }
}

// MARK: - Goals
struct Goal: Codable, Identifiable {
    let id: UUID
    let type: GoalType
    let title: String
    let description: String
    let targetValue: Double?
    let currentValue: Double
    let unit: String?
    let targetDate: Date?
    let isCompleted: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, type, title, description, unit, createdAt
        case targetValue = "target_value"
        case currentValue = "current_value"
        case targetDate = "target_date"
        case isCompleted = "is_completed"
    }
}

enum GoalType: String, Codable, CaseIterable {
    case weightLoss = "weight_loss"
    case weightGain = "weight_gain"
    case muscleGain = "muscle_gain"
    case endurance = "endurance"
    case strength = "strength"
    case flexibility = "flexibility"
    case habit = "habit"
    case performance = "performance"
    
    var displayName: String {
        switch self {
        case .weightLoss: return "Weight Loss"
        case .weightGain: return "Weight Gain"
        case .muscleGain: return "Muscle Gain"
        case .endurance: return "Endurance"
        case .strength: return "Strength"
        case .flexibility: return "Flexibility"
        case .habit: return "Habit Building"
        case .performance: return "Performance"
        }
    }
    
    var icon: String {
        switch self {
        case .weightLoss: return "minus.circle.fill"
        case .weightGain: return "plus.circle.fill"
        case .muscleGain: return "figure.strengthtraining.traditional"
        case .endurance: return "heart.circle.fill"
        case .strength: return "dumbbell.fill"
        case .flexibility: return "figure.yoga"
        case .habit: return "checkmark.circle.fill"
        case .performance: return "trophy.fill"
        }
    }
}

// MARK: - Health Profile
struct HealthProfile: Codable {
    let age: Int?
    let height: Double? // in cm
    let weight: Double? // in kg
    let activityLevel: ActivityLevel
    let healthConditions: [String]
    let medications: [String]
    let injuries: [String]
    
    enum CodingKeys: String, CodingKey {
        case age, height, weight, medications, injuries
        case activityLevel = "activity_level"
        case healthConditions = "health_conditions"
    }
}

enum ActivityLevel: String, Codable, CaseIterable {
    case sedentary = "sedentary"
    case lightlyActive = "lightly_active"
    case moderatelyActive = "moderately_active"
    case veryActive = "very_active"
    case extremelyActive = "extremely_active"
    
    var displayName: String {
        switch self {
        case .sedentary: return "Sedentary"
        case .lightlyActive: return "Lightly Active"
        case .moderatelyActive: return "Moderately Active"
        case .veryActive: return "Very Active"
        case .extremelyActive: return "Extremely Active"
        }
    }
    
    var description: String {
        switch self {
        case .sedentary: return "Little to no exercise"
        case .lightlyActive: return "Light exercise 1-3 days/week"
        case .moderatelyActive: return "Moderate exercise 3-5 days/week"
        case .veryActive: return "Hard exercise 6-7 days/week"
        case .extremelyActive: return "Very hard exercise, physical job"
        }
    }
    
    var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .lightlyActive: return 1.375
        case .moderatelyActive: return 1.55
        case .veryActive: return 1.725
        case .extremelyActive: return 1.9
        }
    }
}