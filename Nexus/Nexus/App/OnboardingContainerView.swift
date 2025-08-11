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
                    InterestsSlide()
                        .tag(1)
                    FitnessSlide(prefs: $fitnessPrefs)
                        .tag(2)
                    NutritionSlide(prefs: $nutritionPrefs)
                        .tag(3)
                    MotivationSlide(prefs: $motivationPrefs)
                        .tag(4)
                    SummarySlide(
                        fitness: fitnessPrefs,
                        nutrition: nutritionPrefs,
                        motivation: motivationPrefs,
                        onComplete: completeOnboarding
                    )
                    .tag(5)
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
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Dynamic icon with gradient background
            ZStack {
                Circle()
                    .fill(themeProvider.theme.accent.opacity(0.2))
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 60, weight: .light))
                    .foregroundColor(themeProvider.theme.accent)
                    .shadow(color: themeProvider.theme.accent.opacity(0.3), radius: 10)
            }
            
            VStack(spacing: 12) {
                Text("Welcome to NexusGPT")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(themeProvider.theme.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Your AI assistant that adapts to YOUR passions")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(themeProvider.theme.textSecondary)
                    .multilineTextAlignment(.center)
                
                Text("Fitness • Business • Mindset • Creativity • Goals")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeProvider.theme.accent)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                Text("Let's personalize your experience")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeProvider.theme.textPrimary)
                
                Text("Takes less than 2 minutes")
                    .font(.system(size: 14))
                    .foregroundColor(themeProvider.theme.textSecondary)
            }
        }
        .padding(.horizontal, 24)
        .background(themeProvider.theme.backgroundPrimary)
    }
}

// MARK: - Revolutionary Interests Selection

private struct InterestsSlide: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @State private var selectedInterests: Set<UserInterest> = []
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Text("What drives you?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(themeProvider.theme.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Select all that inspire and motivate you")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeProvider.theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 20)
            
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                    ForEach(UserInterest.allCases, id: \.self) { interest in
                        InterestCard(
                            interest: interest,
                            isSelected: selectedInterests.contains(interest),
                            themeProvider: themeProvider
                        ) {
                            if selectedInterests.contains(interest) {
                                selectedInterests.remove(interest)
                            } else {
                                selectedInterests.insert(interest)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            
            Spacer()
        }
        .background(themeProvider.theme.backgroundPrimary)
    }
}

private struct InterestCard: View {
    let interest: UserInterest
    let isSelected: Bool
    let themeProvider: ThemeProvider
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? themeProvider.theme.accent : themeProvider.theme.accent.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: interest.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(isSelected ? .white : themeProvider.theme.accent)
                }
                
                VStack(spacing: 4) {
                    Text(interest.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(themeProvider.theme.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text(interest.subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeProvider.theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? themeProvider.theme.accent.opacity(0.1) : themeProvider.theme.backgroundSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? themeProvider.theme.accent : themeProvider.theme.borderLight, lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Universal User Interests

enum UserInterest: String, CaseIterable, Codable {
    case fitness = "fitness"
    case business = "business"
    case mindset = "mindset"
    case creativity = "creativity"
    case relationships = "relationships"
    case learning = "learning"
    case spirituality = "spirituality"
    case adventure = "adventure"
    case wealth = "wealth"
    case leadership = "leadership"
    case health = "health"
    case family = "family"
    
    var title: String {
        switch self {
        case .fitness: return "Fitness & Health"
        case .business: return "Business & Career"
        case .mindset: return "Mindset & Growth"
        case .creativity: return "Creativity & Arts"
        case .relationships: return "Relationships"
        case .learning: return "Learning & Skills"
        case .spirituality: return "Spirituality"
        case .adventure: return "Adventure & Travel"
        case .wealth: return "Wealth & Finance"
        case .leadership: return "Leadership"
        case .health: return "Mental Health"
        case .family: return "Family & Parenting"
        }
    }
    
    var subtitle: String {
        switch self {
        case .fitness: return "Workouts, nutrition, wellness"
        case .business: return "Career growth, entrepreneurship"
        case .mindset: return "Personal development, habits"
        case .creativity: return "Art, music, writing, design"
        case .relationships: return "Love, friendship, social skills"
        case .learning: return "Education, new skills, reading"
        case .spirituality: return "Meditation, purpose, meaning"
        case .adventure: return "Travel, exploration, experiences"
        case .wealth: return "Investing, financial freedom"
        case .leadership: return "Management, influence, impact"
        case .health: return "Mental wellness, therapy, balance"
        case .family: return "Parenting, family time, legacy"
        }
    }
    
    var icon: String {
        switch self {
        case .fitness: return "figure.run"
        case .business: return "briefcase.fill"
        case .mindset: return "brain.head.profile"
        case .creativity: return "paintbrush.fill"
        case .relationships: return "heart.fill"
        case .learning: return "book.fill"
        case .spirituality: return "leaf.fill"
        case .adventure: return "mountain.2.fill"
        case .wealth: return "dollarsign.circle.fill"
        case .leadership: return "crown.fill"
        case .health: return "mind.head.profile"
        case .family: return "house.fill"
        }
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
    @EnvironmentObject var themeProvider: ThemeProvider
    let fitness: FitnessPreferences
    let nutrition: NutritionPreferences
    let motivation: MotivationPreferences
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Success animation
            ZStack {
                Circle()
                    .fill(themeProvider.theme.accent.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .blur(radius: 20)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60, weight: .light))
                    .foregroundColor(themeProvider.theme.accent)
                    .shadow(color: themeProvider.theme.accent.opacity(0.3), radius: 10)
            }
            
            VStack(spacing: 16) {
                Text("🎉 You're all set!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(themeProvider.theme.textPrimary)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 8) {
                    Text("NexusGPT is now personalizing")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(themeProvider.theme.textPrimary)
                    
                    Text("your experience based on your interests")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(themeProvider.theme.textPrimary)
                }
                .multilineTextAlignment(.center)
                
                Text("Your app will adapt its interface, content, and personality to match what drives and motivates YOU.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeProvider.theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
            
            Spacer()
            
            Button(action: onComplete) {
                HStack(spacing: 12) {
                    Text("Enter Your Personalized NexusGPT")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 20))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(themeProvider.theme.accent)
                        .shadow(color: themeProvider.theme.accent.opacity(0.3), radius: 8, x: 0, y: 4)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 20)
            
            Spacer(minLength: 40)
        }
        .padding(.horizontal, 24)
        .background(themeProvider.theme.backgroundPrimary)
    }
}

#Preview {
    OnboardingContainerView()
        .environmentObject(AuthenticationService())
        .environmentObject(ThemeProvider())
}


