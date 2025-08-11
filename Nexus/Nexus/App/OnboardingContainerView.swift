//
//  OnboardingContainerView.swift
//  NexusGPT
//
//  Created on 2025-01-13
//

import SwiftUI

struct OnboardingContainerView: View {
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var themeProvider: ThemeProvider
    
    @State private var step: Int = 0
    @State private var fitnessPrefs = FitnessPreferences(
        level: .beginner,
        preferredActivities: [],
        availableEquipment: [],
        workoutDuration: .short,
        workoutFrequency: .light,
        limitations: []
    )
    @State private var nutritionPrefs = NutritionPreferences(
        dietaryRestrictions: [.none],
        calorieGoal: .maintain,
        mealPreferences: [.healthy],
        allergies: [],
        dislikedFoods: [],
        cookingSkill: .beginner,
        mealPrepTime: .minimal
    )
    @State private var motivationPrefs = MotivationPreferences(
        communicationStyle: .energetic,
        reminderFrequency: .daily,
        motivationTriggers: [.morningBoost],
        preferredTimes: [.morning]
    )
    
    var body: some View {
        NavigationStack {
            VStack {
                TabView(selection: $step) {
                    WelcomeSlide()
                        .tag(0)
                    FitnessSlide(prefs: $fitnessPrefs)
                        .tag(1)
                    NutritionSlide(prefs: $nutritionPrefs)
                        .tag(2)
                    MotivationSlide(prefs: $motivationPrefs)
                        .tag(3)
                    SummarySlide(
                        fitness: fitnessPrefs,
                        nutrition: nutritionPrefs,
                        motivation: motivationPrefs,
                        onComplete: completeOnboarding
                    )
                    .tag(4)
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .background(themeProvider.theme.backgroundPrimary)
            }
            .navigationTitle("Get Started")
        }
        .onChange(of: motivationPrefs.communicationStyle) { _, _ in
            themeProvider.applyTheme(for: authService.currentUser)
        }
    }
    
    private func completeOnboarding() {
        let userPreferences = UserPreferences(
            fitness: fitnessPrefs,
            nutrition: nutritionPrefs,
            motivation: motivationPrefs,
            goals: [],
            createdAt: Date(),
            updatedAt: Date()
        )
        Task { await authService.completeOnboarding(preferences: userPreferences, healthProfile: nil) }
    }
}

// MARK: - Slides

private struct WelcomeSlide: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "figure.run")
                .font(.system(size: 80))
                .foregroundColor(.primaryGreen)
            Text("Welcome to NexusGPT")
                .font(.title)
                .fontWeight(.bold)
            Text("Personalize your experience in under a minute.")
                .foregroundColor(.textSecondary)
            Spacer()
        }
        .padding()
    }
}

private struct FitnessSlide: View {
    @Binding var prefs: FitnessPreferences
    
    var body: some View {
        Form {
            Picker("Level", selection: $prefs.level) {
                ForEach(FitnessLevel.allCases, id: \.self) { level in
                    Text(level.displayName).tag(level)
                }
            }
            
            Section("Preferred Activities") {
                ForEach(ActivityType.allCases, id: \.self) { activity in
                    Toggle(activity.displayName, isOn: Binding(
                        get: { prefs.preferredActivities.contains(activity) },
                        set: { isOn in
                            if isOn { prefs.preferredActivities.append(activity) }
                            else { prefs.preferredActivities.removeAll { $0 == activity } }
                        }
                    ))
                }
            }
        }
    }
}

private struct NutritionSlide: View {
    @Binding var prefs: NutritionPreferences
    
    var body: some View {
        Form {
            Picker("Calorie Goal", selection: $prefs.calorieGoal) {
                ForEach(CalorieGoal.allCases, id: \.self) { goal in
                    Text(goal.displayName).tag(goal)
                }
            }
            
            Section("Preferences") {
                ForEach(MealPreference.allCases, id: \.self) { mp in
                    Toggle(mp.displayName, isOn: Binding(
                        get: { prefs.mealPreferences.contains(mp) },
                        set: { isOn in
                            if isOn { prefs.mealPreferences.append(mp) }
                            else { prefs.mealPreferences.removeAll { $0 == mp } }
                        }
                    ))
                }
            }
        }
    }
}

private struct MotivationSlide: View {
    @Binding var prefs: MotivationPreferences
    
    var body: some View {
        Form {
            Picker("Style", selection: $prefs.communicationStyle) {
                ForEach(CommunicationStyle.allCases, id: \.self) { cs in
                    Text(cs.displayName).tag(cs)
                }
            }
            Picker("Reminders", selection: $prefs.reminderFrequency) {
                ForEach(ReminderFrequency.allCases, id: \.self) { rf in
                    Text(rf.displayName).tag(rf)
                }
            }
        }
    }
}

private struct SummarySlide: View {
    let fitness: FitnessPreferences
    let nutrition: NutritionPreferences
    let motivation: MotivationPreferences
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("You're all set")
                .font(.title2)
                .fontWeight(.semibold)
            Text("We'll tailor NexusGPT to your vibe and goals.")
                .foregroundColor(.textSecondary)
            Spacer()
            Button(action: onComplete) {
                Text("Finish")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal)
            Spacer(minLength: 24)
        }
        .padding()
    }
}

#Preview {
    OnboardingContainerView()
        .environmentObject(AuthenticationService())
        .environmentObject(ThemeProvider())
}


