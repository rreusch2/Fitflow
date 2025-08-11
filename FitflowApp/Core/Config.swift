//
//  Config.swift
//  Fitflow
//
//  Created on 2025-01-13
//

import Foundation

struct Config {
    // MARK: - Keys Management
    private static let keys: [String: Any] = {
        guard let path = Bundle.main.path(forResource: "Keys", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            fatalError("Keys.plist file not found or invalid format")
        }
        return plist
    }()
    
    private static func getKey(_ key: String) -> String {
        guard let value = keys[key] as? String, !value.isEmpty else {
            fatalError("Key '\(key)' not found in Keys.plist or is empty")
        }
        return value
    }
    
    // MARK: - Supabase Configuration
    struct Supabase {
        static let url = getKey("SUPABASE_URL")
        static let anonKey = getKey("SUPABASE_ANON_KEY")
        
        // Database table names
        static let usersTable = "users"
        static let workoutPlansTable = "workout_plans"
        static let mealPlansTable = "meal_plans"
        static let progressTable = "user_progress"
        static let chatSessionsTable = "chat_sessions"
    }
    
    // MARK: - AI Configuration
    struct AI {
        // Grok API Configuration
        static let grokAPIKey = getKey("GROK_API_KEY")
        static let grokBaseURL = "https://api.x.ai/v1"
        static let grokModel = "grok-beta"
        
        // OpenAI Configuration (Fallback)
        static let openAIAPIKey = getKey("OPENAI_API_KEY")
        static let openAIBaseURL = "https://api.openai.com/v1"
        static let openAIModel = "gpt-4"
        
        // Rate limiting
        static let maxRequestsPerMinute = 60
        static let maxRequestsPerDay = 1000
        
        // Free tier limits
        static let freeUserDailyLimit = 5
        static let proUserDailyLimit = -1 // Unlimited
    }
    
    // MARK: - App Configuration
    struct App {
        static let name = "Fitflow"
        static let version = "1.0.0"
        static let buildNumber = "1"
        
        // Feature flags
        static let enableHealthKit = true
        static let enablePushNotifications = true
        static let enableAnalytics = true
        static let enableCrashReporting = true
        
        // Subscription configuration
        static let freeTrialDays = 7
        static let subscriptionProductIDs = [
            "fitflow_pro_monthly",
            "fitflow_pro_yearly",
            "fitflow_lifetime"
        ]
    }
    
    // MARK: - API Endpoints
    struct Endpoints {
        static let generateWorkoutPlan = "/generate-workout-plan"
        static let generateMealPlan = "/generate-meal-plan"
        static let chatCompletion = "/chat-completion"
        static let analyzeProgress = "/analyze-progress"
        static let generateMotivation = "/generate-motivation"
        // Supabase Edge Functions are exposed at /functions/v1/<name>
        static let generateImage = "/functions/v1/generate-image"
    }
    
    // MARK: - Cache Configuration
    struct Cache {
        static let workoutPlanTTL: TimeInterval = 24 * 60 * 60 // 24 hours
        static let mealPlanTTL: TimeInterval = 24 * 60 * 60 // 24 hours
        static let chatResponseTTL: TimeInterval = 60 * 60 // 1 hour
        static let userPreferencesTTL: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    }
    
    // MARK: - Validation Rules
    struct Validation {
        static let minPasswordLength = 8
        static let maxGoalTitleLength = 100
        static let maxNotesLength = 500
        static let minAge = 13
        static let maxAge = 120
        static let minWeight = 30.0 // kg
        static let maxWeight = 300.0 // kg
        static let minHeight = 100.0 // cm
        static let maxHeight = 250.0 // cm
    }
    
    // MARK: - Environment Detection
    enum Environment {
        case development
        case staging
        case production
        
        static var current: Environment {
            #if DEBUG
            return .development
            #elseif STAGING
            return .staging
            #else
            return .production
            #endif
        }
        
        var isDebug: Bool {
            return self == .development
        }
        
        var baseURL: String {
            switch self {
            case .development:
                return "http://localhost:3000"
            case .staging:
                return "https://staging-api.fitflow.app"
            case .production:
                return "https://api.fitflow.app"
            }
        }
    }
    
    // MARK: - Logging Configuration
    struct Logging {
        static let enableConsoleLogging = Environment.current.isDebug
        static let enableFileLogging = true
        static let enableRemoteLogging = Environment.current != .development
        static let maxLogFileSize = 10 * 1024 * 1024 // 10MB
        static let maxLogFiles = 5
    }
    
    // MARK: - Analytics Configuration
    struct Analytics {
        static let enableUserTracking = Environment.current == .production
        static let enableCrashTracking = true
        static let enablePerformanceTracking = Environment.current == .production
        static let sessionTimeout: TimeInterval = 30 * 60 // 30 minutes
    }
    
    // MARK: - Health Kit Configuration
    struct HealthKit {
        static let readTypes = [
            "HKQuantityTypeIdentifierStepCount",
            "HKQuantityTypeIdentifierActiveEnergyBurned",
            "HKQuantityTypeIdentifierBodyMass",
            "HKQuantityTypeIdentifierHeight",
            "HKQuantityTypeIdentifierHeartRate",
            "HKQuantityTypeIdentifierDistanceWalkingRunning"
        ]
        
        static let writeTypes = [
            "HKQuantityTypeIdentifierActiveEnergyBurned",
            "HKWorkoutTypeIdentifier"
        ]
    }
    
    // MARK: - Push Notification Configuration
    struct PushNotifications {
        static let categories = [
            "workout_reminder",
            "meal_reminder",
            "motivation_boost",
            "progress_update",
            "goal_achievement"
        ]
        
        static let defaultReminderTime = DateComponents(hour: 9, minute: 0) // 9:00 AM
    }
    
    // MARK: - Error Messages
    struct ErrorMessages {
        static let networkError = "Unable to connect to the server. Please check your internet connection."
        static let authenticationError = "Authentication failed. Please sign in again."
        static let validationError = "Please check your input and try again."
        static let aiServiceError = "AI service is temporarily unavailable. Please try again later."
        static let subscriptionError = "Subscription service is unavailable. Please try again later."
        static let healthKitError = "Unable to access health data. Please check your permissions."
        static let genericError = "Something went wrong. Please try again."
    }
    
    // MARK: - Success Messages
    struct SuccessMessages {
        static let accountCreated = "Account created successfully! Welcome to Fitflow!"
        static let profileUpdated = "Profile updated successfully!"
        static let workoutCompleted = "Great job! Workout completed!"
        static let goalAchieved = "Congratulations! You've achieved your goal!"
        static let planGenerated = "Your personalized plan is ready!"
        static let progressSaved = "Progress saved successfully!"
    }
    
    // MARK: - Helper Methods
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    static func isValidPassword(_ password: String) -> Bool {
        return password.count >= Validation.minPasswordLength
    }
    
    static func formatWeight(_ weight: Double, unit: String = "kg") -> String {
        return String(format: "%.1f %@", weight, unit)
    }
    
    static func formatHeight(_ height: Double, unit: String = "cm") -> String {
        return String(format: "%.0f %@", height, unit)
    }
    
    static func formatCalories(_ calories: Int) -> String {
        return "\(calories) cal"
    }
    
    static func formatDuration(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(remainingMinutes)m"
            }
        }
    }
}

// MARK: - Debug Configuration
#if DEBUG
extension Config {
    struct Debug {
        static let enableMockData = true
        static let enableSlowAnimations = false
        static let enableNetworkLogging = true
        static let enableUITesting = false
        static let skipOnboarding = false
        static let mockUserSubscription: SubscriptionTier = .free
    }
}
#endif