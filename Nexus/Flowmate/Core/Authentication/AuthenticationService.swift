//
//  AuthenticationService.swift
//  Fitflow
//
//  Created on 2025-01-13
//

import Foundation
import Combine
import SwiftUI

@MainActor
class AuthenticationService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let databaseService = DatabaseService.shared
    
    init() {
        setupAuthStateListener()
    }
    
    // MARK: - Authentication State Management
    
    func checkAuthState() {
        isLoading = true
        
        // Check if user is already authenticated (stored session)
        if let userData = UserDefaults.standard.data(forKey: "current_user"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.currentUser = user
            self.isAuthenticated = true
        }
        
        isLoading = false
    }
    
    private func setupAuthStateListener() {
        // Listen for authentication state changes
        // This would typically integrate with Supabase auth state changes
        // For now, we'll use a simple implementation
    }
    
    // MARK: - Sign Up
    
    func signUp(email: String, password: String, fullName: String) async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Validate input
            guard Config.isValidEmail(email) else {
                throw AuthenticationError.invalidEmail
            }
            
            guard Config.isValidPassword(password) else {
                throw AuthenticationError.weakPassword
            }
            
            // Create user account
            let userId = UUID()
            let newUser = User(
                id: userId,
                email: email,
                subscriptionTier: .free,
                preferences: nil,
                healthProfile: nil,
                hasCompletedOnboarding: false,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            // Save user to database
            try await databaseService.createUser(newUser)
            
            // Update local state
            self.currentUser = newUser
            self.isAuthenticated = true
            
            // Store user session
            saveUserSession(newUser)
            
            HapticFeedback.success()
            
        } catch {
            self.errorMessage = handleAuthError(error)
            HapticFeedback.error()
        }
        
        isLoading = false
    }
    
    // MARK: - Sign In
    
    func signIn(email: String, password: String) async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Validate input
            guard Config.isValidEmail(email) else {
                throw AuthenticationError.invalidEmail
            }
            
            // Authenticate user
            let user = try await databaseService.authenticateUser(email: email, password: password)
            
            // Update local state
            self.currentUser = user
            self.isAuthenticated = true
            
            // Store user session
            saveUserSession(user)
            
            HapticFeedback.success()
            
        } catch {
            self.errorMessage = handleAuthError(error)
            HapticFeedback.error()
        }
        
        isLoading = false
    }
    
    // MARK: - Sign In with Apple
    
    func signInWithApple() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // This would integrate with Apple Sign In
            // For now, we'll create a mock implementation
            let userId = UUID()
            let user = User(
                id: userId,
                email: "user@icloud.com",
                subscriptionTier: .free,
                preferences: nil,
                healthProfile: nil,
                hasCompletedOnboarding: false,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            // Save user to database
            try await databaseService.createUser(user)
            
            // Update local state
            self.currentUser = user
            self.isAuthenticated = true
            
            // Store user session
            saveUserSession(user)
            
            HapticFeedback.success()
            
        } catch {
            self.errorMessage = handleAuthError(error)
            HapticFeedback.error()
        }
        
        isLoading = false
    }
    
    // MARK: - Password Reset
    
    func resetPassword(email: String) async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            guard Config.isValidEmail(email) else {
                throw AuthenticationError.invalidEmail
            }
            
            // Send password reset email
            try await databaseService.sendPasswordResetEmail(email: email)
            
            HapticFeedback.success()
            
        } catch {
            self.errorMessage = handleAuthError(error)
            HapticFeedback.error()
        }
        
        isLoading = false
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        currentUser = nil
        isAuthenticated = false
        
        // Clear stored session
        UserDefaults.standard.removeObject(forKey: "current_user")
        UserDefaults.standard.removeObject(forKey: "auth_token")
        
        HapticFeedback.light()
    }
    
    // MARK: - Update User Profile
    
    func updateUserProfile(_ updatedUser: User) async {
        guard currentUser != nil else { return }
        
        isLoading = true
        
        do {
            let user = try await databaseService.updateUser(updatedUser)
            self.currentUser = user
            saveUserSession(user)
            
        } catch {
            self.errorMessage = handleAuthError(error)
        }
        
        isLoading = false
    }
    
    // MARK: - Complete Onboarding
    
    func completeOnboarding(preferences: UserPreferences, healthProfile: HealthProfile?) async {
        guard var user = currentUser else { return }
        
        isLoading = true
        
        do {
            // Update user with preferences and mark onboarding as complete
            user = User(
                id: user.id,
                email: user.email,
                subscriptionTier: user.subscriptionTier,
                preferences: preferences,
                healthProfile: healthProfile,
                hasCompletedOnboarding: true,
                createdAt: user.createdAt,
                updatedAt: Date()
            )
            
            let updatedUser = try await databaseService.updateUser(user)
            self.currentUser = updatedUser
            saveUserSession(updatedUser)
            
            HapticFeedback.success()
            
        } catch {
            self.errorMessage = handleAuthError(error)
            HapticFeedback.error()
        }
        
        isLoading = false
    }
    
    // MARK: - Subscription Management
    
    func updateSubscription(to tier: SubscriptionTier) async {
        guard var user = currentUser else { return }
        
        isLoading = true
        
        do {
            user = User(
                id: user.id,
                email: user.email,
                subscriptionTier: tier,
                preferences: user.preferences,
                healthProfile: user.healthProfile,
                hasCompletedOnboarding: user.hasCompletedOnboarding,
                createdAt: user.createdAt,
                updatedAt: Date()
            )
            
            let updatedUser = try await databaseService.updateUser(user)
            self.currentUser = updatedUser
            saveUserSession(updatedUser)
            
        } catch {
            self.errorMessage = handleAuthError(error)
        }
        
        isLoading = false
    }
    
    // MARK: - Helper Methods
    
    private func saveUserSession(_ user: User) {
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: "current_user")
        }
    }
    
    private func handleAuthError(_ error: Error) -> String {
        if let authError = error as? AuthenticationError {
            return authError.localizedDescription
        } else if let dbError = error as? DatabaseError {
            return dbError.localizedDescription
        } else {
            return Config.ErrorMessages.authenticationError
        }
    }
    
    // MARK: - Validation Helpers
    
    func validateSignUpForm(email: String, password: String, confirmPassword: String, fullName: String) -> [String] {
        var errors: [String] = []
        
        if fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Full name is required")
        }
        
        if !Config.isValidEmail(email) {
            errors.append("Please enter a valid email address")
        }
        
        if !Config.isValidPassword(password) {
            errors.append("Password must be at least \(Config.Validation.minPasswordLength) characters long")
        }
        
        if password != confirmPassword {
            errors.append("Passwords do not match")
        }
        
        return errors
    }
    
    func validateSignInForm(email: String, password: String) -> [String] {
        var errors: [String] = []
        
        if !Config.isValidEmail(email) {
            errors.append("Please enter a valid email address")
        }
        
        if password.isEmpty {
            errors.append("Password is required")
        }
        
        return errors
    }
}

// MARK: - Authentication Errors

enum AuthenticationError: LocalizedError {
    case invalidEmail
    case weakPassword
    case emailAlreadyExists
    case invalidCredentials
    case userNotFound
    case networkError
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address"
        case .weakPassword:
            return "Password must be at least \(Config.Validation.minPasswordLength) characters long"
        case .emailAlreadyExists:
            return "An account with this email already exists"
        case .invalidCredentials:
            return "Invalid email or password"
        case .userNotFound:
            return "No account found with this email address"
        case .networkError:
            return Config.ErrorMessages.networkError
        case .unknownError:
            return Config.ErrorMessages.authenticationError
        }
    }
}

// MARK: - Mock Implementation for Development

#if DEBUG
extension AuthenticationService {
    func signInWithMockUser() {
        let mockUser = User(
            id: UUID(),
            email: "test@fitflow.app",
            subscriptionTier: Config.Debug.mockUserSubscription,
            preferences: createMockPreferences(),
            healthProfile: createMockHealthProfile(),
            hasCompletedOnboarding: !Config.Debug.skipOnboarding,
            createdAt: Date().addingTimeInterval(-86400 * 30), // 30 days ago
            updatedAt: Date()
        )
        
        self.currentUser = mockUser
        self.isAuthenticated = true
        saveUserSession(mockUser)
    }
    
    private func createMockPreferences() -> UserPreferences {
        return UserPreferences(
            fitness: FitnessPreferences(
                level: .intermediate,
                preferredActivities: [.strength, .cardio, .yoga],
                availableEquipment: [.dumbbells, .yogaMat],
                workoutDuration: .medium,
                workoutFrequency: .moderate,
                limitations: []
            ),
            nutrition: NutritionPreferences(
                dietaryRestrictions: [.none],
                calorieGoal: .maintain,
                mealPreferences: [.quickAndEasy, .healthy],
                allergies: [],
                dislikedFoods: [],
                cookingSkill: .intermediate,
                mealPrepTime: .moderate
            ),
            motivation: MotivationPreferences(
                communicationStyle: .energetic,
                reminderFrequency: .daily,
                motivationTriggers: [.morningBoost, .preWorkout],
                preferredTimes: [.morning, .evening]
            ),
            business: BusinessPreferences(focus: .leadership, workStyle: .remote, weeklyHours: 8),
            creativity: CreativityPreferences(mediums: [.music, .writing], tools: [.ipad, .pencil], weeklyHours: 4),
            mindset: MindsetPreferences(focuses: [.growth, .habits], reflection: .weekly),
            wealth: WealthPreferences(goals: [.saving, .investing], risk: .moderate, monthlyBudget: 500),
            relationships: RelationshipPreferences(focuses: [.friendships, .networking], weeklySocialHours: 6),
            theme: ThemePreferences(
                style: .energetic,
                accent: .coral,
                selectedInterests: [.fitness, .mindset, .business],
                tabVisibility: TabVisibilityPreferences(
                    visibleTabs: [.fitness, .mindset, .business],
                    tabOrder: [.flow, .fitness, .business, .mindset, .creativity],
                    maxVisibleTabs: 4
                )
            ),
            goals: [
                Goal(
                    id: UUID(),
                    type: .muscleGain,
                    title: "Build Muscle",
                    description: "Gain 5kg of lean muscle mass",
                    targetValue: 5.0,
                    currentValue: 2.0,
                    unit: "kg",
                    targetDate: Calendar.current.date(byAdding: .month, value: 6, to: Date()),
                    isCompleted: false,
                    createdAt: Date()
                )
            ],
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    private func createMockHealthProfile() -> HealthProfile {
        return HealthProfile(
            age: 28,
            height: 175.0,
            weight: 70.0,
            activityLevel: .moderatelyActive,
            healthConditions: [],
            medications: [],
            injuries: []
        )
    }
}
#endif