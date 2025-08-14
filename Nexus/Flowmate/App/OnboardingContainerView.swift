//
//  OnboardingContainerView.swift
//  Flowmate
//
//  Created on 2025-01-13
//

import SwiftUI

struct OnboardingContainerView: View {
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var themeProvider: ThemeProvider
    
    @State private var step: Int = 0
    @State private var fitnessPrefs = FitnessPreferences(
        level: FitnessLevel.beginner,
        preferredActivities: [],
        availableEquipment: [],
        workoutDuration: WorkoutDuration.short,
        workoutFrequency: WorkoutFrequency.light,
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
    @State private var selectedInterests: Set<UserInterest> = []
    @State private var showResumePrompt: Bool = false
    // Additional category-specific onboarding state
    @State private var businessFocus: BusinessFocus = .productivity
    @State private var workStyle: WorkStyle = .remote
    @State private var weeklyBusinessHours: Int = 10
    
    @State private var creativeMediums: Set<CreativeMedium> = []
    @State private var creativeHoursPerWeek: Int = 5
    @State private var creativeTools: Set<CreativeTool> = []
    
    // New categories
    @State private var mindsetFocuses: Set<MindsetFocus> = []
    @State private var reflection: ReflectionPreference = .weekly
    
    @State private var wealthGoals: Set<WealthGoal> = []
    @State private var riskTolerance: RiskTolerance = .moderate
    @State private var monthlyBudget: Int = 500
    
    @State private var relationshipFocuses: Set<RelationshipFocus> = []
    @State private var weeklySocialHours: Int = 5
    
    // Theme preview selection
    @State private var selectedStyle: ThemeStyle = .energetic
    @State private var selectedAccent: AccentColorChoice = .coral

    // Dynamic pages model
    private enum OnboardingPage: Hashable {
        case welcome
        case interests
        case theme
        case fitness
        case nutrition
        case business
        case creativity
        case mindset
        case wealth
        case relationships
        case summary
    }
    
    private func buildPages() -> [OnboardingPage] {
        var pages: [OnboardingPage] = [.welcome, .interests, .theme]
        if selectedInterests.contains(.fitness) { pages.append(.fitness) }
        if selectedInterests.contains(.fitness) || selectedInterests.contains(.health) { pages.append(.nutrition) }
        if selectedInterests.contains(.business) { pages.append(.business) }
        if selectedInterests.contains(.creativity) { pages.append(.creativity) }
        if selectedInterests.contains(.mindset) { pages.append(.mindset) }
        if selectedInterests.contains(.wealth) { pages.append(.wealth) }
        if selectedInterests.contains(.relationships) { pages.append(.relationships) }
        pages.append(.summary)
        return pages
    }

    private func nextStep() {
        let count = buildPages().count
        step = min(step + 1, max(0, count - 1))
    }

    // MARK: - Draft Persistence
    private let onboardingDraftKey = "onboarding_draft_v1"
    private struct OnboardingDraft: Codable {
        let step: Int
        let selectedInterests: [UserInterest]
        let selectedStyle: ThemeStyle
        let selectedAccent: AccentColorChoice
        let fitnessPrefs: FitnessPreferences
        let nutritionPrefs: NutritionPreferences
        let motivationPrefs: MotivationPreferences
        let businessFocus: BusinessFocus
        let workStyle: WorkStyle
        let weeklyBusinessHours: Int
        let creativeMediums: [CreativeMedium]
        let creativeTools: [CreativeTool]
        let creativeHoursPerWeek: Int
        let mindsetFocuses: [MindsetFocus]
        let reflection: ReflectionPreference
        let wealthGoals: [WealthGoal]
        let riskTolerance: RiskTolerance
        let monthlyBudget: Int
        let relationshipFocuses: [RelationshipFocus]
        let weeklySocialHours: Int
    }
    
    private func saveDraft() {
        let draft = OnboardingDraft(
            step: step,
            selectedInterests: Array(selectedInterests),
            selectedStyle: selectedStyle,
            selectedAccent: selectedAccent,
            fitnessPrefs: fitnessPrefs,
            nutritionPrefs: nutritionPrefs,
            motivationPrefs: motivationPrefs,
            businessFocus: businessFocus,
            workStyle: workStyle,
            weeklyBusinessHours: weeklyBusinessHours,
            creativeMediums: Array(creativeMediums),
            creativeTools: Array(creativeTools),
            creativeHoursPerWeek: creativeHoursPerWeek,
            mindsetFocuses: Array(mindsetFocuses),
            reflection: reflection,
            wealthGoals: Array(wealthGoals),
            riskTolerance: riskTolerance,
            monthlyBudget: monthlyBudget,
            relationshipFocuses: Array(relationshipFocuses),
            weeklySocialHours: weeklySocialHours
        )
        if let data = try? JSONEncoder().encode(draft) {
            UserDefaults.standard.set(data, forKey: onboardingDraftKey)
        }
    }
    
    private func loadDraft() {
        guard let data = UserDefaults.standard.data(forKey: onboardingDraftKey),
              let draft = try? JSONDecoder().decode(OnboardingDraft.self, from: data) else { return }
        step = min(draft.step, buildPages().count - 1)
        selectedInterests = Set(draft.selectedInterests)
        selectedStyle = draft.selectedStyle
        selectedAccent = draft.selectedAccent
        fitnessPrefs = draft.fitnessPrefs
        nutritionPrefs = draft.nutritionPrefs
        motivationPrefs = draft.motivationPrefs
        businessFocus = draft.businessFocus
        workStyle = draft.workStyle
        weeklyBusinessHours = draft.weeklyBusinessHours
        creativeMediums = Set(draft.creativeMediums)
        creativeTools = Set(draft.creativeTools)
        creativeHoursPerWeek = draft.creativeHoursPerWeek
        mindsetFocuses = Set(draft.mindsetFocuses)
        reflection = draft.reflection
        wealthGoals = Set(draft.wealthGoals)
        riskTolerance = draft.riskTolerance
        monthlyBudget = draft.monthlyBudget
        relationshipFocuses = Set(draft.relationshipFocuses)
        weeklySocialHours = draft.weeklySocialHours
    }
    
    private func clearDraft() {
        UserDefaults.standard.removeObject(forKey: onboardingDraftKey)
    }
    
    // Lightweight token that summarizes draft changes for a single onChange listener
    private var draftChangeToken: Int {
        let draft = OnboardingDraft(
            step: step,
            selectedInterests: Array(selectedInterests),
            selectedStyle: selectedStyle,
            selectedAccent: selectedAccent,
            fitnessPrefs: fitnessPrefs,
            nutritionPrefs: nutritionPrefs,
            motivationPrefs: motivationPrefs,
            businessFocus: businessFocus,
            workStyle: workStyle,
            weeklyBusinessHours: weeklyBusinessHours,
            creativeMediums: Array(creativeMediums),
            creativeTools: Array(creativeTools),
            creativeHoursPerWeek: creativeHoursPerWeek,
            mindsetFocuses: Array(mindsetFocuses),
            reflection: reflection,
            wealthGoals: Array(wealthGoals),
            riskTolerance: riskTolerance,
            monthlyBudget: monthlyBudget,
            relationshipFocuses: Array(relationshipFocuses),
            weeklySocialHours: weeklySocialHours
        )
        if let data = try? JSONEncoder().encode(draft) {
            return data.count
        }
        return 0
    }
    
    // MARK: - View Components
    private var backgroundView: some View {
        ThemedBackground()
            .environmentObject(themeProvider)
    }
    
    private var contentView: some View {
        VStack(spacing: 16) {
            progressIndicatorView
            onboardingTabView
        }
    }
    
    private var progressIndicatorView: some View {
        let pages = buildPages()
        return StepIndicator(progress: pages.isEmpty ? 0 : Double(step + 1) / Double(pages.count))
            .padding(.horizontal, 24)
            .padding(.top, 8)
    }
    
    private var onboardingTabView: some View {
        let pages = buildPages()
        return TabView(selection: $step) {
            ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                pageContentView(for: page)
                    .tag(index)
            }
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .automatic))
        .animation(.easeInOut(duration: 0.2), value: step) // Faster, smoother animation
    }
    
    @ViewBuilder
    private func pageContentView(for page: OnboardingPage) -> some View {
        switch page {
        case .welcome:
            WelcomeSlide(onContinue: nextStep)
        case .interests:
            InterestsSlide(selectedInterests: $selectedInterests, onContinue: nextStep)
        case .theme:
            ThemeStyleSlide(style: $selectedStyle, accent: $selectedAccent, onContinue: nextStep)
        case .fitness:
            FitnessSlide(prefs: $fitnessPrefs, isRelevant: selectedInterests.contains(.fitness))
        case .nutrition:
            NutritionSlide(prefs: $nutritionPrefs, onSkip: nextStep)
        case .business:
            BusinessSlide(focus: $businessFocus, workStyle: $workStyle, hoursPerWeek: $weeklyBusinessHours, onSkip: nextStep)
        case .creativity:
            CreativitySlide(mediums: $creativeMediums, tools: $creativeTools, hoursPerWeek: $creativeHoursPerWeek, onSkip: nextStep)
        case .mindset:
            MindsetSlide(focuses: $mindsetFocuses, reflection: $reflection, onSkip: nextStep)
        case .wealth:
            WealthSlide(goals: $wealthGoals, risk: $riskTolerance, monthlyBudget: $monthlyBudget, onSkip: nextStep)
        case .relationships:
            RelationshipsSlide(focuses: $relationshipFocuses, weeklyHours: $weeklySocialHours, onSkip: nextStep)
        case .summary:
            summarySlideView
        }
    }
    
    private var summarySlideView: some View {
        SummarySlide(
            selectedInterests: selectedInterests,
            selectedStyle: selectedStyle,
            selectedAccent: selectedAccent,
            fitness: fitnessPrefs,
            nutrition: nutritionPrefs,
            motivation: motivationPrefs,
            onEditInterests: { step = indexOf(.interests) },
            onEditTheme: { step = indexOf(.theme) },
            onEditFitness: { step = indexOf(.fitness) },
            onEditNutrition: { step = indexOf(.nutrition) },
            onEditBusiness: { step = indexOf(.business) },
            onEditCreativity: { step = indexOf(.creativity) },
            onComplete: completeOnboarding
        )
    }
    
    private var mainNavigationView: some View {
        NavigationStack {
            ZStack {
                backgroundView
                contentView
            }
            .navigationTitle("Get Started")
        }
    }

    var body: some View {
        let themed = mainNavigationView
            .onChange(of: motivationPrefs.communicationStyle) { _, _ in
                themeProvider.applyTheme(for: authService.currentUser)
            }
            .onAppear {
                if UserDefaults.standard.data(forKey: onboardingDraftKey) != nil {
                    showResumePrompt = true
                }
                selectedStyle = themeProvider.style
                selectedAccent = themeProvider.accentChoice
                themeProvider.setTheme(style: selectedStyle, accent: selectedAccent)
            }
            .onChange(of: selectedStyle) { _, new in
                themeProvider.setTheme(style: new, accent: selectedAccent)
                saveDraft()
            }
            .onChange(of: selectedAccent) { _, new in
                themeProvider.setTheme(style: selectedStyle, accent: new)
                saveDraft()
            }

        return themed
            .onChange(of: draftChangeToken) { _, _ in
                let count = buildPages().count
                if step >= count { step = max(0, count - 1) }
                saveDraft()
            }
            .alert("Resume your setup?", isPresented: $showResumePrompt) {
                Button("Start Over", role: .destructive) { clearDraft() }
                Button("Resume") { loadDraft() }
            } message: {
                Text("We found a saved onboarding session. Would you like to continue where you left off?")
            }
    }

    private func indexOf(_ page: OnboardingPage) -> Int {
        let pages = buildPages()
        return pages.firstIndex(of: page) ?? max(0, pages.count - 1)
    }
    
    private func completeOnboarding() {
        let businessPrefs: BusinessPreferences? = selectedInterests.contains(.business) ? BusinessPreferences(focus: businessFocus, workStyle: workStyle, weeklyHours: weeklyBusinessHours) : nil
        let creativityPrefs: CreativityPreferences? = selectedInterests.contains(.creativity) ? CreativityPreferences(mediums: Array(creativeMediums), tools: Array(creativeTools), weeklyHours: creativeHoursPerWeek) : nil
        let mindsetPrefs: MindsetPreferences? = selectedInterests.contains(.mindset) ? MindsetPreferences(focuses: Array(mindsetFocuses), reflection: reflection) : nil
        let wealthPrefs: WealthPreferences? = selectedInterests.contains(.wealth) ? WealthPreferences(goals: Array(wealthGoals), risk: riskTolerance, monthlyBudget: monthlyBudget) : nil
        let relationshipsPrefs: RelationshipPreferences? = selectedInterests.contains(.relationships) ? RelationshipPreferences(focuses: Array(relationshipFocuses), weeklySocialHours: weeklySocialHours) : nil
        
        // Revolutionary theme persistence for complete personalization
        let themePrefs = ThemePreferences(
            style: selectedStyle,
            accent: selectedAccent,
            selectedInterests: Array(selectedInterests),
            tabVisibility: TabVisibilityPreferences(
                visibleTabs: Array(selectedInterests),
                tabOrder: [.flow, .fitness, .business, .mindset, .creativity, .wealth, .relationships],
                maxVisibleTabs: min(selectedInterests.count + 1, 5) // Include flow tab + selected interests, max 5
            )
        )
        
        let userPreferences = UserPreferences(
            fitness: fitnessPrefs,
            nutrition: nutritionPrefs,
            motivation: motivationPrefs,
            business: businessPrefs,
            creativity: creativityPrefs,
            mindset: mindsetPrefs,
            wealth: wealthPrefs,
            relationships: relationshipsPrefs,
            theme: themePrefs,
            goals: [],
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Apply the selected theme immediately
        themeProvider.setTheme(style: selectedStyle, accent: selectedAccent)
        Task { await authService.completeOnboarding(preferences: userPreferences, healthProfile: nil) }
    }
}

private struct BusinessSlide: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @Binding var focus: BusinessFocus
    @Binding var workStyle: WorkStyle
    @Binding var hoursPerWeek: Int
    var onSkip: () -> Void = {}
    
    var body: some View {
        Form {
            Picker("Main focus", selection: $focus) {
                ForEach(BusinessFocus.allCases) { f in
                    Text(f.displayName).tag(f)
                }
            }
            Picker("Work style", selection: $workStyle) {
                ForEach(WorkStyle.allCases) { ws in
                    Text(ws.displayName).tag(ws)
                }
            }
            Stepper(value: $hoursPerWeek, in: 1...80) {
                Text("Weekly hours for growth: \(hoursPerWeek)")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .listStyle(.insetGrouped)
        .tint(themeProvider.theme.accent)
        .overlay(alignment: .topLeading) {
            Image(systemName: "briefcase.fill")
                .foregroundStyle(themeProvider.theme.accent)
                .padding(.leading, 24)
        }
        .safeAreaInset(edge: .bottom) {
            Button("Skip for now") { onSkip() }
                .font(.caption)
                .foregroundColor(.textSecondary)
                .padding(.vertical, 8)
        }
    }
}

private struct CreativitySlide: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @Binding var mediums: Set<CreativeMedium>
    @Binding var tools: Set<CreativeTool>
    @Binding var hoursPerWeek: Int
    var onSkip: () -> Void = {}
    
    var body: some View {
        Form {
            Section("Mediums") {
                ForEach(CreativeMedium.allCases) { m in
                    Toggle(m.displayName, isOn: Binding(
                        get: { mediums.contains(m) },
                        set: { on in
                            if on { mediums.insert(m) } else { mediums.remove(m) }
                        }
                    ))
                }
            }
            Section("Tools") {
                ForEach(CreativeTool.allCases) { t in
                    Toggle(t.displayName, isOn: Binding(
                        get: { tools.contains(t) },
                        set: { on in
                            if on { tools.insert(t) } else { tools.remove(t) }
                        }
                    ))
                }
            }
            Stepper(value: $hoursPerWeek, in: 1...50) {
                Text("Weekly creative hours: \(hoursPerWeek)")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .listStyle(.insetGrouped)
        .tint(themeProvider.theme.accent)
        .overlay(alignment: .topLeading) {
            Image(systemName: "paintbrush.fill")
                .foregroundStyle(themeProvider.theme.accent)
                .padding(.leading, 24)
        }
        .safeAreaInset(edge: .bottom) {
            Button("Skip for now") { onSkip() }
                .font(.caption)
                .foregroundColor(.textSecondary)
                .padding(.vertical, 8)
        }
    }
}

// MARK: - Nutrition Placeholder when not selected
private struct NutritionPlaceholder: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    var body: some View {
        VStack(spacing: 12) {
            Text("We’ll skip nutrition details")
                .font(.headline)
                .foregroundColor(themeProvider.theme.textPrimary)
            Text("You didn’t choose nutrition/health as a focus. You can always add it later from Profile.")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
        .glassCard()
    }
}

// MARK: - Slides

private struct WelcomeSlide: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    var onContinue: () -> Void = {}
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Dynamic icon with gradient background
            ZStack {
                Circle()
                    .fill(themeProvider.theme.accent.opacity(0.25))
                    .frame(width: 120, height: 120)
                    .blur(radius: 16)
                Circle()
                    .fill(themeProvider.theme.backgroundSecondary.opacity(0.6))
                    .frame(width: 90, height: 90)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 60, weight: .light))
                    .foregroundColor(themeProvider.theme.textPrimary)
                    .shadow(color: Color.black.opacity(0.1), radius: 8)
            }
            
            VStack(spacing: 12) {
                Text("Welcome to Flowmate")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .readableText()
                    .readableTextBackdrop()
                    .multilineTextAlignment(.center)
                
                Text("Your AI assistant that adapts to YOUR passions")
                    .font(.system(size: 18, weight: .medium))
                    .readableText()
                    .readableTextBackdrop()
                    .multilineTextAlignment(.center)
                
                Text("Fitness • Business • Mindset • Creativity • Goals")
                    .font(.system(size: 14, weight: .medium))
                    .readableText()
                    .readableTextBackdrop()
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                Text("Let's personalize your experience")
                    .font(.system(size: 16, weight: .semibold))
                    .readableText()
                    .readableTextBackdrop()
                
                Text("Takes less than 2 minutes")
                    .font(.system(size: 14))
                    .readableText()
                    .readableTextBackdrop()
            }
            .overlay(alignment: .topLeading) {
                Image(systemName: "sparkles")
                    .foregroundStyle(themeProvider.theme.accent)
                    .padding(.leading, 12)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .background(Color.clear)
        .safeAreaInset(edge: .bottom) {
            HStack {
                Spacer()
                Button(action: onContinue) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(themeProvider.theme.accent)
                        .clipShape(Circle())
                        .shadow(color: themeProvider.theme.accent.opacity(0.35), radius: 10, x: 0, y: 6)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.trailing, 20)
                .padding(.bottom, 6)
            }
        }
    }
}

// MARK: - Revolutionary Interests Selection

private struct InterestsSlide: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @Binding var selectedInterests: Set<UserInterest>
    var onContinue: () -> Void = {}
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Text("What drives you?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .readableText()
                    .readableTextBackdrop()
                    .multilineTextAlignment(.center)
                
                Text("Select all that inspire and motivate you")
                    .font(.system(size: 16, weight: .medium))
                    .readableText()
                    .readableTextBackdrop()
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 20)
            .overlay(alignment: .topLeading) {
                // Subtle icon header matching splash theme
                Image(systemName: "sparkles")
                    .foregroundStyle(themeProvider.theme.accent)
                    .padding(.leading, 12)
            }
            
            ScrollView {
                // Beautiful flowing grid with consistent sizing
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], 
                    spacing: 16
                ) {
                    ForEach(UserInterest.allCases, id: \.self) { interest in
                        InterestCard(
                            interest: interest,
                            isSelected: selectedInterests.contains(interest),
                            themeProvider: themeProvider
                        ) {
                            withAnimation(.bouncy) {
                                if selectedInterests.contains(interest) {
                                    selectedInterests.remove(interest)
                                } else {
                                    selectedInterests.insert(interest)
                                }
                            }
                            HapticFeedback.light()
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
            
            Spacer()
        }
        .background(Color.clear)
        .safeAreaInset(edge: .bottom) {
            HStack {
                Spacer()
                Button(action: onContinue) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(themeProvider.theme.accent)
                        .clipShape(Circle())
                        .shadow(color: themeProvider.theme.accent.opacity(0.35), radius: 10, x: 0, y: 6)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.trailing, 20)
                .padding(.bottom, 6)
            }
        }
    }
}

private struct InterestCard: View {
    let interest: UserInterest
    let isSelected: Bool
    let themeProvider: ThemeProvider
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 14) {
                // Beautiful icon with dynamic sizing
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isSelected ? 
                                    [themeProvider.theme.accent, themeProvider.theme.accent.opacity(0.8)] :
                                    [themeProvider.theme.accent.opacity(0.15), themeProvider.theme.accent.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .shadow(
                            color: isSelected ? themeProvider.theme.accent.opacity(0.3) : .clear,
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                    
                    Image(systemName: interest.icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(isSelected ? .white : themeProvider.theme.accent)
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                        .animation(.bouncy, value: isSelected)
                }
                
                // Consistent text layout
                VStack(spacing: 6) {
                    Text(interest.title)
                        .font(.system(size: 15, weight: .semibold))
                        .readableText()
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(interest.subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .readableText()
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxHeight: 60, alignment: .top)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140) // Consistent height for all cards
            .padding(.horizontal, 14)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: isSelected ?
                                [themeProvider.theme.accent.opacity(0.1), themeProvider.theme.accent.opacity(0.05)] :
                                [themeProvider.theme.backgroundSecondary, Color.white],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: isSelected ?
                                        [themeProvider.theme.accent, themeProvider.theme.accent.opacity(0.6)] :
                                        [Color.borderMedium, Color.borderLight],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: isSelected ? 2.5 : 1
                            )
                    )
                    .shadow(
                        color: isSelected ? themeProvider.theme.accent.opacity(0.2) : Color.black.opacity(0.05),
                        radius: isSelected ? 12 : 4,
                        x: 0,
                        y: isSelected ? 6 : 2
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.bouncy, value: isSelected)
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
    @EnvironmentObject var themeProvider: ThemeProvider
    @Binding var prefs: FitnessPreferences
    let isRelevant: Bool
    
    var body: some View {
        Group {
            if isRelevant {
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
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .listStyle(.insetGrouped)
                .tint(themeProvider.theme.accent)
                .overlay(alignment: .topLeading) {
                    Image(systemName: "figure.run")
                        .foregroundStyle(themeProvider.theme.accent)
                        .padding(.leading, 24)
                }
            } else {
                VStack(spacing: 12) {
                    Text("We’ll skip fitness details")
                        .font(.headline)
                    Text("You didn’t choose fitness as a focus. You can always add it later from Profile.")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .glassCard()
            }
        }
    }
}

private struct NutritionSlide: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @Binding var prefs: NutritionPreferences
    var onSkip: () -> Void = {}
    
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
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .listStyle(.insetGrouped)
        .tint(themeProvider.theme.accent)
        .safeAreaInset(edge: .bottom) {
            Button("Skip for now") { onSkip() }
                .font(.caption)
                .foregroundColor(.textSecondary)
                .padding(.vertical, 8)
        }
    }
}

// MotivationSlide removed: Reminders tab temporarily disabled per design

// MARK: - Revolutionary Theme Style Selection
private struct ThemeStyleSlide: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @Binding var style: ThemeStyle
    @Binding var accent: AccentColorChoice
    var onContinue: () -> Void = {}
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
            // Beautiful header
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "paintpalette.fill")
                        .foregroundStyle(themeProvider.theme.accent)
                        .font(.title2)
                    Text("Choose Your Flowmate Style")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(themeProvider.theme.textPrimary)
                    Spacer()
                }
                
                Text("Pick a visual style that matches your energy and personality")
                    .font(.system(size: 16, weight: .medium))
                    .readableText()
                    .readableTextBackdrop()
                    .multilineTextAlignment(.leading)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            // Enhanced Preview Card
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "eye.fill")
                        .foregroundStyle(themeProvider.theme.accent)
                        .font(.title3)
                    Text("Live Preview")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(themeProvider.theme.textPrimary)
                    Spacer()
                }
                
                // Beautiful preview card with actual Flowmate content
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [themeProvider.theme.backgroundPrimary, themeProvider.theme.backgroundSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 160)
                    .overlay(
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Circle()
                                    .fill(themeProvider.theme.accent)
                                    .frame(width: 12, height: 12)
                                Text("Accent Color")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(themeProvider.theme.accent)
                                Spacer()
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Good morning! Ready to flow?")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(themeProvider.theme.textPrimary)
                                
                                Text("Your Flowmate is here to guide you through an amazing day of growth and achievement.")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(themeProvider.theme.textSecondary)
                                    .lineLimit(2)
                            }
                            
                            HStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(themeProvider.theme.accent.opacity(0.2))
                                    .frame(width: 60, height: 24)
                                    .overlay(
                                        Text("Action")
                                            .font(.caption)
                                            .foregroundColor(themeProvider.theme.accent)
                                    )
                                Spacer()
                            }
                        }
                        .padding(20)
                    )
                    .shadow(
                        color: themeProvider.theme.accent.opacity(0.15),
                        radius: 12,
                        x: 0,
                        y: 6
                    )
            }
            .padding(.horizontal, 24)
            
            // Style Selection Grid
            VStack(spacing: 16) {
                HStack {
                    Text("Visual Styles")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(themeProvider.theme.textPrimary)
                    Spacer()
                }
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                    ForEach(ThemeStyle.allCases, id: \.self) { themeStyle in
                        StyleCard(
                            style: themeStyle,
                            isSelected: style == themeStyle,
                            themeProvider: themeProvider
                        ) {
                            withAnimation(.bouncy) {
                                style = themeStyle
                                themeProvider.setTheme(style: themeStyle, accent: accent)
                            }
                            HapticFeedback.light()
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            
            // Accent Color Selection
            VStack(spacing: 16) {
                HStack {
                    Text("Accent Colors")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(themeProvider.theme.textPrimary)
                    Spacer()
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(AccentColorChoice.allCases, id: \.self) { accentColor in
                            AccentColorCard(
                                accent: accentColor,
                                isSelected: accent == accentColor,
                                themeProvider: themeProvider
                            ) {
                                withAnimation(.bouncy) {
                                    accent = accentColor
                                    themeProvider.setTheme(style: style, accent: accentColor)
                                }
                                HapticFeedback.light()
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            
            // Subtle tip without blocking preview
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(themeProvider.theme.accent.opacity(0.7))
                    .font(.caption)
                Text("You can change these anytime in Settings")
                    .font(.caption)
                    .readableText()
                    .readableTextBackdrop(cornerRadius: 8)
                Spacer()
            }
            .padding(.horizontal, 24)
            
            Spacer()
            }
            .padding(.bottom, 24)
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                Spacer()
                Button(action: onContinue) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(themeProvider.theme.accent)
                        .clipShape(Circle())
                        .shadow(color: themeProvider.theme.accent.opacity(0.35), radius: 10, x: 0, y: 6)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.trailing, 20)
                .padding(.bottom, 6)
            }
        }
        .onChange(of: style) { _, new in
            themeProvider.setTheme(style: new, accent: accent)
        }
        .onChange(of: accent) { _, new in
            themeProvider.setTheme(style: style, accent: new)
        }
    }
}

// MARK: - Beautiful Style Selection Cards
struct StyleCard: View {
    let style: ThemeStyle
    let isSelected: Bool
    let themeProvider: ThemeProvider
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                // Dynamic visual representation of the style
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(styleGradient)
                        .frame(height: 60)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    isSelected ? themeProvider.theme.accent : Color.borderLight,
                                    lineWidth: isSelected ? 2.5 : 1
                                )
                        )
                    
                    // Style-specific visual elements
                    HStack(spacing: 6) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(themeProvider.theme.accent.opacity(0.7 - Double(index) * 0.2))
                                .frame(width: 8, height: 8)
                        }
                    }
                }
                
                VStack(spacing: 4) {
                    Text(style.displayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeProvider.theme.textPrimary)
                    
                    Text(style.description)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(themeProvider.theme.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected ?
                            themeProvider.theme.accent.opacity(0.1) :
                            themeProvider.theme.backgroundSecondary
                    )
                    .shadow(
                        color: isSelected ? themeProvider.theme.accent.opacity(0.2) : Color.black.opacity(0.05),
                        radius: isSelected ? 8 : 2,
                        x: 0,
                        y: isSelected ? 4 : 1
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.bouncy, value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var styleGradient: LinearGradient {
        switch style {
        case .energetic:
            // Electric coral-to-sunset gradient (matches ThemedBackground)
            return LinearGradient(
                colors: [
                    Color(red: 255/255, green: 107/255, blue: 107/255), // Electric coral
                    Color(red: 255/255, green: 154/255, blue: 158/255), // Coral light
                    Color(red: 255/255, green: 183/255, blue: 77/255),  // Warm gold
                    Color(red: 255/255, green: 204/255, blue: 128/255)  // Golden cream
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .professional:
            // Sophisticated blue-steel gradient (matches ThemedBackground)
            return LinearGradient(
                colors: [
                    Color(red: 116/255, green: 185/255, blue: 255/255), // Business blue bright
                    Color(red: 72/255, green: 126/255, blue: 176/255),  // Deep ocean
                    Color(red: 162/255, green: 155/255, blue: 254/255), // Business purple
                    Color(red: 244/255, green: 247/255, blue: 251/255)  // Cool mist
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .creative:
            // Ethereal pink-to-lavender gradient (matches ThemedBackground)
            return LinearGradient(
                colors: [
                    Color(red: 255/255, green: 107/255, blue: 129/255), // Creative pink
                    Color(red: 196/255, green: 69/255, blue: 105/255),  // Creative violet
                    Color(red: 253/255, green: 203/255, blue: 110/255), // Mindset lavender
                    Color(red: 255/255, green: 182/255, blue: 193/255)  // Soft rose
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .minimal:
            // Clean minimalist gradient
            return LinearGradient(
                colors: [
                    Color(red: 246/255, green: 248/255, blue: 250/255), // Light gray
                    Color.white,                                        // Pure white
                    Color(red: 249/255, green: 250/255, blue: 251/255)  // Off-white
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .playful:
            // Vibrant rainbow-burst gradient (matches ThemedBackground)
            return LinearGradient(
                colors: [
                    Color(red: 255/255, green: 107/255, blue: 129/255), // Creative pink
                    Color(red: 255/255, green: 154/255, blue: 158/255), // Coral light
                    Color(red: 255/255, green: 183/255, blue: 77/255),  // Warm gold
                    Color(red: 85/255, green: 239/255, blue: 196/255)   // Fitness green
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .dark:
            // Sophisticated dark gradient (matches ThemedBackground)
            return LinearGradient(
                colors: [
                    Color(red: 44/255, green: 44/255, blue: 46/255),   // iOS dark tertiary
                    Color(red: 28/255, green: 28/255, blue: 30/255),   // iOS dark secondary
                    Color(red: 0/255, green: 0/255, blue: 0/255)       // Pure black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .vibrancy:
            return Color.vibrancyGradient
        case .prism:
            return Color.prismGradient
        case .sunset:
            return Color.sunsetGradient
        case .ocean:
            return Color.oceanGradient
        case .neon:
            return LinearGradient(
                colors: [
                    Color(red: 57/255, green: 255/255, blue: 20/255),
                    Color(red: 255/255, green: 0/255, blue: 150/255),
                    Color(red: 0/255, green: 200/255, blue: 255/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

struct AccentColorCard: View {
    let accent: AccentColorChoice
    let isSelected: Bool
    let themeProvider: ThemeProvider
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Beautiful color preview
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: isSelected ? 56 : 48, height: isSelected ? 56 : 48)
                    .overlay(
                        Circle()
                            .stroke(
                                Color.white,
                                lineWidth: isSelected ? 3 : 0
                            )
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                themeProvider.theme.accent.opacity(0.3),
                                lineWidth: isSelected ? 2 : 0
                            )
                            .scaleEffect(1.2)
                    )
                    .shadow(
                        color: accentColor.opacity(0.4),
                        radius: isSelected ? 8 : 4,
                        x: 0,
                        y: isSelected ? 4 : 2
                    )
                
                Text(accent.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeProvider.theme.textPrimary)
                    .lineLimit(1)
            }
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .animation(.bouncy, value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var accentColor: Color {
        switch accent {
        case .coral: return .primaryCoral
        case .gold: return .warmGold
        case .ocean: return .deepOcean
        case .fitness: return .fitnessGreen
        case .business: return .businessBlue
        case .mindset: return .mindsetLavender
        case .creative: return .creativePink
        case .vibrancy: return .primaryCoral
        case .prism: return .businessBlue
        case .sunset: return .warmGold
        case .neon: return .fitnessGreen
        case .cosmic: return .deepOceanDark
        }
    }
}

// MARK: - Theme Style Extensions
extension ThemeStyle {
    var displayName: String {
        switch self {
        case .energetic: return "Energetic"
        case .professional: return "Professional"
        case .creative: return "Creative"
        case .minimal: return "Minimal"
        case .playful: return "Playful"
        case .dark: return "Dark"
        case .vibrancy: return "Vibrancy"
        case .prism: return "Prism"
        case .sunset: return "Sunset"
        case .ocean: return "Ocean"
        case .neon: return "Neon"
        }
    }
    
    var description: String {
        switch self {
        case .energetic: return "Electric coral sunset vibes"
        case .professional: return "Sophisticated blue steel"
        case .creative: return "Ethereal pink lavender dreams"
        case .minimal: return "Pure elegant simplicity"
        case .playful: return "Vibrant rainbow burst"
        case .dark: return "Sleek sophisticated dark"
        case .vibrancy: return "Vibrant multi-color energy"
        case .prism: return "Spectrum light refraction"
        case .sunset: return "Warm golden hour magic"
        case .ocean: return "Deep oceanic tranquility"
        case .neon: return "Cyberpunk electric glow"
        }
    }
}

extension AccentColorChoice {
    var displayName: String {
        switch self {
        case .coral: return "Coral"
        case .gold: return "Gold"
        case .ocean: return "Ocean"
        case .fitness: return "Fitness"
        case .business: return "Business"
        case .mindset: return "Mindset"
        case .creative: return "Creative"
        case .vibrancy: return "Vibrancy"
        case .prism: return "Prism"
        case .sunset: return "Sunset"
        case .neon: return "Neon"
        case .cosmic: return "Cosmic"
        }
    }
}

// MARK: - Mindset Slide
private struct MindsetSlide: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @Binding var focuses: Set<MindsetFocus>
    @Binding var reflection: ReflectionPreference
    var onSkip: () -> Void = {}
    
    var body: some View {
        Form {
            Section("Focus Areas") {
                ForEach(MindsetFocus.allCases) { f in
                    Toggle(f.displayName, isOn: Binding(
                        get: { focuses.contains(f) },
                        set: { on in
                            if on { focuses.insert(f) } else { focuses.remove(f) }
                        }
                    ))
                }
            }
            Picker("Reflection", selection: $reflection) {
                ForEach(ReflectionPreference.allCases) { r in
                    Text(r.displayName).tag(r)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .listStyle(.insetGrouped)
        .tint(themeProvider.theme.accent)
        .overlay(alignment: .topLeading) {
            Image(systemName: "brain.head.profile")
                .foregroundStyle(themeProvider.theme.accent)
                .padding(.leading, 24)
        }
        .safeAreaInset(edge: .bottom) {
            Button("Skip for now") { onSkip() }
                .font(.caption)
                .foregroundColor(.textSecondary)
                .padding(.vertical, 8)
        }
    }
}

// MARK: - Wealth Slide
private struct WealthSlide: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @Binding var goals: Set<WealthGoal>
    @Binding var risk: RiskTolerance
    @Binding var monthlyBudget: Int
    var onSkip: () -> Void = {}
    
    var body: some View {
        Form {
            Section("Goals") {
                ForEach(WealthGoal.allCases) { g in
                    Toggle(g.displayName, isOn: Binding(
                        get: { goals.contains(g) },
                        set: { on in
                            if on { goals.insert(g) } else { goals.remove(g) }
                        }
                    ))
                }
            }
            Picker("Risk Tolerance", selection: $risk) {
                ForEach(RiskTolerance.allCases) { r in
                    Text(r.displayName).tag(r)
                }
            }
            Stepper(value: $monthlyBudget, in: 0...10000, step: 50) {
                Text("Monthly budget: $\(monthlyBudget)")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .listStyle(.insetGrouped)
        .tint(themeProvider.theme.accent)
        .overlay(alignment: .topLeading) {
            Image(systemName: "dollarsign.circle.fill")
                .foregroundStyle(themeProvider.theme.accent)
                .padding(.leading, 24)
        }
        .safeAreaInset(edge: .bottom) {
            Button("Skip for now") { onSkip() }
                .font(.caption)
                .foregroundColor(.textSecondary)
                .padding(.vertical, 8)
        }
    }
}

// MARK: - Relationships Slide
private struct RelationshipsSlide: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @Binding var focuses: Set<RelationshipFocus>
    @Binding var weeklyHours: Int
    var onSkip: () -> Void = {}
    
    var body: some View {
        Form {
            Section("Focus Areas") {
                ForEach(RelationshipFocus.allCases) { f in
                    Toggle(f.displayName, isOn: Binding(
                        get: { focuses.contains(f) },
                        set: { on in
                            if on { focuses.insert(f) } else { focuses.remove(f) }
                        }
                    ))
                }
            }
            Stepper(value: $weeklyHours, in: 0...40) {
                Text("Weekly social hours: \(weeklyHours)")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .listStyle(.insetGrouped)
        .tint(themeProvider.theme.accent)
        .overlay(alignment: .topLeading) {
            Image(systemName: "heart.fill")
                .foregroundStyle(themeProvider.theme.accent)
                .padding(.leading, 24)
        }
        .safeAreaInset(edge: .bottom) {
            Button("Skip for now") { onSkip() }
                .font(.caption)
                .foregroundColor(.textSecondary)
                .padding(.vertical, 8)
        }
    }
}

private struct SummarySlide: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    let selectedInterests: Set<UserInterest>
    let selectedStyle: ThemeStyle
    let selectedAccent: AccentColorChoice
    let fitness: FitnessPreferences
    let nutrition: NutritionPreferences
    let motivation: MotivationPreferences
    let onEditInterests: () -> Void
    let onEditTheme: () -> Void
    let onEditFitness: () -> Void
    let onEditNutrition: () -> Void
    let onEditBusiness: () -> Void
    let onEditCreativity: () -> Void
    let onComplete: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Beautiful success animation with particles
                ZStack {
                    // Animated background circles
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        themeProvider.theme.accent.opacity(0.3),
                                        themeProvider.theme.accent.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120 - CGFloat(index * 20), height: 120 - CGFloat(index * 20))
                            .blur(radius: 10 + CGFloat(index * 5))
                            .scaleEffect(1.0 + sin(Date().timeIntervalSince1970 + Double(index)) * 0.1)
                            .animation(.easeInOut(duration: 2.0 + Double(index)).repeatForever(autoreverses: true), value: UUID())
                    }
                    
                    // Central success icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [themeProvider.theme.accent, themeProvider.theme.accent.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .shadow(color: themeProvider.theme.accent.opacity(0.4), radius: 12, x: 0, y: 6)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                // Revolutionary messaging
                VStack(spacing: 12) {
                    Text("🎉 Welcome to your flow!")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [themeProvider.theme.textPrimary, themeProvider.theme.accent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .multilineTextAlignment(.center)
                    Text("Flowmate is now personalizing your entire experience")
                        .font(.system(size: 16, weight: .semibold))
                        .readableText()
                        .multilineTextAlignment(.center)
                    Text("Your AI companion adapts interface, personality, and guidance to match what truly drives you.")
                        .font(.system(size: 14, weight: .medium))
                        .readableText()
                        .readableTextBackdrop()
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .padding(.top, 2)
                }
                .padding(.horizontal, 8)
                
                // Beautiful personalization summary
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundStyle(themeProvider.theme.accent)
                            .font(.title2)
                        Text("Your Personalized Setup")
                            .font(.system(size: 18, weight: .bold))
                            .readableText()
                            .readableTextBackdrop()
                        Spacer()
                    }
                    
                    // Dynamic interest pills
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                        ForEach(Array(selectedInterests), id: \.self) { interest in
                            HStack(spacing: 6) {
                                Image(systemName: interest.icon)
                                    .font(.caption)
                                    .foregroundColor(themeProvider.theme.accent)
                                Text(interest.title)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(themeProvider.theme.textPrimary)
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(themeProvider.theme.accent.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(themeProvider.theme.accent.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                    }
                    
                    // Theme preview
                    HStack {
                        Image(systemName: "paintpalette.fill")
                            .foregroundColor(themeProvider.theme.accent)
                            .font(.caption)
                        Text("\(selectedStyle.displayName) • \(selectedAccent.displayName)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(themeProvider.theme.textSecondary)
                        Spacer()
                        Circle()
                            .fill(themeProvider.theme.accent)
                            .frame(width: 16, height: 16)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(themeProvider.theme.backgroundSecondary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.borderLight, lineWidth: 1)
                            )
                    )
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [themeProvider.theme.backgroundSecondary, themeProvider.theme.backgroundPrimary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                )
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 100)
        }
        .safeAreaInset(edge: .bottom) {
            Button(action: onComplete) {
                HStack(spacing: 16) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 24, weight: .medium))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Enter Your Flowmate")
                            .font(.system(size: 18, weight: .bold))
                        Text("Start your personalized journey")
                            .font(.system(size: 14, weight: .medium))
                            .opacity(0.9)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 24))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [
                            themeProvider.theme.accent,
                            themeProvider.theme.accent.opacity(0.85),
                            themeProvider.theme.emphasis
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: themeProvider.theme.accent.opacity(0.4), radius: 12, x: 0, y: 6)
                )
                .scaleEffect(1.0)
                .animation(.bouncy, value: UUID())
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
    }
}

#Preview {
    OnboardingContainerView()
        .environmentObject(AuthenticationService())
        .environmentObject(ThemeProvider())
}

// MARK: - Step Indicator Component
private struct StepIndicator: View {
    let progress: Double
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        VStack(spacing: 0) {
            // Beautiful progress bar without step text
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: themeProvider.theme.accent))
                .frame(height: 4)
                .clipShape(RoundedRectangle(cornerRadius: 2))
                .background(
                    RoundedRectangle(cornerRadius: 2)
                        .fill(themeProvider.theme.accent.opacity(0.15))
                        .frame(height: 4)
                )
                .shadow(
                    color: themeProvider.theme.accent.opacity(0.3),
                    radius: 2,
                    x: 0,
                    y: 1
                )
        }
    }
}
