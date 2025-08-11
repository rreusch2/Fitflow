//
//  UserModels.swift
//  NexusGPT
//
//  Created on 2025-01-13
//

import Foundation

// MARK: - User Model
struct User: Codable, Identifiable {
    let id: UUID
    let email: String
    let subscriptionTier: SubscriptionTier
    let preferences: UserPreferences?
    let healthProfile: HealthProfile?
    let hasCompletedOnboarding: Bool
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, email, preferences, createdAt, updatedAt
        case subscriptionTier = "subscription_tier"
        case healthProfile = "health_profile"
        case hasCompletedOnboarding = "has_completed_onboarding"
    }
}

// MARK: - Subscription Tiers
enum SubscriptionTier: String, Codable, CaseIterable {
    case free = "free"
    case pro = "pro"
    case lifetime = "lifetime"
    
    var displayName: String {
        switch self {
        case .free: return "Free"
        case .pro: return "Pro"
        case .lifetime: return "Lifetime"
        }
    }
    
    var features: [String] {
        switch self {
        case .free:
            return [
                "Basic workout plans",
                "Basic meal suggestions",
                "Limited AI queries (5/day)",
                "Manual progress tracking"
            ]
        case .pro, .lifetime:
            return [
                "Unlimited personalized plans",
                "Advanced AI chatbot",
                "Real-time plan adaptation",
                "HealthKit integration",
                "Progress analytics",
                "Custom AI personalities",
                "Priority support"
            ]
        }
    }
}

// MARK: - User Preferences
struct UserPreferences: Codable {
    let fitness: FitnessPreferences
    let nutrition: NutritionPreferences
    let motivation: MotivationPreferences
    let goals: [Goal]
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case fitness, nutrition, motivation, goals
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Fitness Preferences
struct FitnessPreferences: Codable {
    let level: FitnessLevel
    let preferredActivities: [ActivityType]
    let availableEquipment: [Equipment]
    let workoutDuration: WorkoutDuration
    let workoutFrequency: WorkoutFrequency
    let limitations: [String]
    
    enum CodingKeys: String, CodingKey {
        case level, limitations
        case preferredActivities = "preferred_activities"
        case availableEquipment = "available_equipment"
        case workoutDuration = "workout_duration"
        case workoutFrequency = "workout_frequency"
    }
}

enum FitnessLevel: String, Codable, CaseIterable {
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
        case .beginner: return "New to fitness or returning after a break"
        case .intermediate: return "Regular exercise routine for 6+ months"
        case .advanced: return "Consistent training for 2+ years"
        }
    }
}

enum ActivityType: String, Codable, CaseIterable {
    case cardio = "cardio"
    case strength = "strength"
    case yoga = "yoga"
    case hiit = "hiit"
    case pilates = "pilates"
    case running = "running"
    case cycling = "cycling"
    case swimming = "swimming"
    case dancing = "dancing"
    case sports = "sports"
    
    var displayName: String {
        switch self {
        case .cardio: return "Cardio"
        case .strength: return "Strength Training"
        case .yoga: return "Yoga"
        case .hiit: return "HIIT"
        case .pilates: return "Pilates"
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .dancing: return "Dancing"
        case .sports: return "Sports"
        }
    }
    
    var icon: String {
        switch self {
        case .cardio: return "heart.fill"
        case .strength: return "dumbbell.fill"
        case .yoga: return "figure.yoga"
        case .hiit: return "flame.fill"
        case .pilates: return "figure.pilates"
        case .running: return "figure.run"
        case .cycling: return "bicycle"
        case .swimming: return "figure.pool.swim"
        case .dancing: return "music.note"
        case .sports: return "sportscourt.fill"
        }
    }
}

enum Equipment: String, Codable, CaseIterable {
    case none = "none"
    case dumbbells = "dumbbells"
    case resistanceBands = "resistance_bands"
    case kettlebells = "kettlebells"
    case pullupBar = "pullup_bar"
    case yogaMat = "yoga_mat"
    case fullGym = "full_gym"
    
    var displayName: String {
        switch self {
        case .none: return "No Equipment"
        case .dumbbells: return "Dumbbells"
        case .resistanceBands: return "Resistance Bands"
        case .kettlebells: return "Kettlebells"
        case .pullupBar: return "Pull-up Bar"
        case .yogaMat: return "Yoga Mat"
        case .fullGym: return "Full Gym Access"
        }
    }
}

enum WorkoutDuration: String, Codable, CaseIterable {
    case short = "15-30"
    case medium = "30-45"
    case long = "45-60"
    case extended = "60+"
    
    var displayName: String {
        switch self {
        case .short: return "15-30 minutes"
        case .medium: return "30-45 minutes"
        case .long: return "45-60 minutes"
        case .extended: return "60+ minutes"
        }
    }
}

enum WorkoutFrequency: String, Codable, CaseIterable {
    case light = "1-2"
    case moderate = "3-4"
    case intense = "5-6"
    case daily = "7"
    
    var displayName: String {
        switch self {
        case .light: return "1-2 times per week"
        case .moderate: return "3-4 times per week"
        case .intense: return "5-6 times per week"
        case .daily: return "Daily"
        }
    }
}