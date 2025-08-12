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
    @State private var selectedStyle: ThemeStyle = .balanced
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
        case motivation
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
        pages.append(.motivation)
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
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .animation(.smooth, value: step)
        .transition(.scaleAndFade)
    }
    
    @ViewBuilder
    private func pageContentView(for page: OnboardingPage) -> some View {
        switch page {
        case .welcome:
            WelcomeSlide()
        case .interests:
            InterestsSlide(selectedInterests: $selectedInterests)
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
        case .motivation:
            MotivationSlide(prefs: $motivationPrefs)
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
            onEditMotivation: { step = indexOf(.motivation) },
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
        
        let userPreferences = UserPreferences(
            fitness: fitnessPrefs,
            nutrition: nutritionPrefs,
            motivation: motivationPrefs,
            business: businessPrefs,
            creativity: creativityPrefs,
            mindset: mindsetPrefs,
            wealth: wealthPrefs,
            relationships: relationshipsPrefs,
            goals: [],
            createdAt: Date(),
            updatedAt: Date()
        )
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
            .overlay(alignment: .topLeading) {
                Image(systemName: "sparkles")
                    .foregroundStyle(themeProvider.theme.accent)
                    .padding(.leading, 12)
            }
        }
        .padding(.horizontal, 24)
        .background(Color.clear)
    }
}

// MARK: - Revolutionary Interests Selection

private struct InterestsSlide: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @Binding var selectedInterests: Set<UserInterest>
    
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
            .overlay(alignment: .topLeading) {
                // Subtle icon header matching splash theme
                Image(systemName: "sparkles")
                    .foregroundStyle(themeProvider.theme.accent)
                    .padding(.leading, 12)
            }
            
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
                .padding(.vertical, 16)
                .glassCard(cornerRadius: CornerRadius.xl)
                .padding(.horizontal, 20)
                .sensoryFeedback(.impact(weight: .light, intensity: 0.5), trigger: selectedInterests)
            }
            
            Spacer()
        }
        .background(Color.clear)
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
                            .stroke(isSelected ? themeProvider.theme.accent : .borderMedium, lineWidth: isSelected ? 2 : 1)
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

private struct MotivationSlide: View {
    @EnvironmentObject var themeProvider: ThemeProvider
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
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .listStyle(.insetGrouped)
        .tint(themeProvider.theme.accent)
        .overlay(alignment: .topLeading) {
            Image(systemName: "bolt.heart.fill")
                .foregroundStyle(themeProvider.theme.accent)
                .padding(.leading, 24)
        }
        .tipBanner(icon: "lightbulb", text: "Choose a style. You can change this anytime in Profile > Theme.")
    }
}

// MARK: - Theme Style Slide
private struct ThemeStyleSlide: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @Binding var style: ThemeStyle
    @Binding var accent: AccentColorChoice
    var onContinue: () -> Void = {}
    
    var body: some View {
        VStack(spacing: 16) {
            // Preview card reflects selected style/accent via ThemeProvider
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Preview")
                        .font(.headline)
                        .foregroundColor(themeProvider.theme.textPrimary)
                    Spacer()
                }
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeProvider.theme.backgroundPrimary)
                    .frame(height: 140)
                    .overlay(
                        VStack(spacing: 8) {
                            HStack {
                                Circle().fill(themeProvider.theme.accent).frame(width: 10, height: 10)
                                Text("Accent")
                                    .foregroundColor(themeProvider.theme.textPrimary)
                                Spacer()
                            }
                            HStack {
                                Text("Title example")
                                    .foregroundColor(themeProvider.theme.textPrimary)
                                    .font(.headline)
                                Spacer()
                            }
                            HStack {
                                Text("Body example with secondary text")
                                    .foregroundColor(themeProvider.theme.textSecondary)
                                Spacer()
                            }
                        }
                        .padding()
                    )
            }
            .glassCard()
            .overlay(alignment: .topLeading) {
                Image(systemName: "paintpalette.fill")
                    .foregroundStyle(themeProvider.theme.accent)
                    .padding(.leading, 24)
            }
            .tipBanner(icon: "lightbulb", text: "Preview themes. You can tweak this anytime in Profile > Theme.")
            
            // Pickers
            Form {
                Picker("Style", selection: $style) {
                    ForEach(ThemeStyle.allCases, id: \.self) { s in
                        Text(String(describing: s).capitalized).tag(s)
                    }
                }
                Picker("Accent", selection: $accent) {
                    ForEach(AccentColorChoice.allCases, id: \.self) { a in
                        Text(String(describing: a).capitalized).tag(a)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .listStyle(.insetGrouped)
            .tint(themeProvider.theme.accent)
            
            Button("Continue") { onContinue() }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal)
        }
        .onChange(of: style) { _, new in
            themeProvider.setTheme(style: new, accent: accent)
        }
        .onChange(of: accent) { _, new in
            themeProvider.setTheme(style: style, accent: new)
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
    let onEditMotivation: () -> Void
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
            
            // Quick summary panel with edit shortcuts
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "star.fill").foregroundStyle(themeProvider.theme.accent)
                    Text("Summary")
                        .font(.headline)
                        .foregroundColor(themeProvider.theme.textPrimary)
                }
                
                VStack(spacing: 8) {
                    HStack {
                        Text("Interests: \(selectedInterests.map { $0.title }.joined(separator: ", "))")
                            .foregroundColor(themeProvider.theme.textPrimary)
                        Spacer()
                        Button("Edit") { onEditInterests() }
                            .font(.caption)
                    }
                    HStack {
                        Text("Theme: \(String(describing: selectedStyle).capitalized) / \(String(describing: selectedAccent).capitalized)")
                            .foregroundColor(themeProvider.theme.textPrimary)
                        Spacer()
                        Button("Edit") { onEditTheme() }
                            .font(.caption)
                    }
                    HStack {
                        Text("Fitness: \(fitness.level.displayName)")
                            .foregroundColor(themeProvider.theme.textPrimary)
                        Spacer()
                        Button("Edit") { onEditFitness() }
                            .font(.caption)
                    }
                    HStack {
                        Text("Nutrition: \(nutrition.calorieGoal.displayName)")
                            .foregroundColor(themeProvider.theme.textPrimary)
                        Spacer()
                        Button("Edit") { onEditNutrition() }
                            .font(.caption)
                    }
                    HStack {
                        Text("Motivation: \(motivation.communicationStyle.displayName)")
                            .foregroundColor(themeProvider.theme.textPrimary)
                        Spacer()
                        Button("Edit") { onEditMotivation() }
                            .font(.caption)
                    }
                }
            }
            .padding()
            .glassCard()
            .overlay(alignment: .topLeading) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(themeProvider.theme.accent)
                    .padding(.leading, 12)
            }
            
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
                    LinearGradient(colors: [themeProvider.theme.accent, themeProvider.theme.accent.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: themeProvider.theme.accent.opacity(0.3), radius: 8, x: 0, y: 4)
                )
                .sensoryFeedback(.success, trigger: UUID())
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 20)
            
            Spacer(minLength: 40)
        }
        .padding(.horizontal, 24)
        .glassCard(cornerRadius: CornerRadius.xl)
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
        VStack(spacing: 4) {
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: themeProvider.theme.accent))
                .frame(height: 3)
                .clipShape(RoundedRectangle(cornerRadius: 2))
            
            HStack {
                Text("Step \(Int(progress * 10)) of \(10)")
                    .font(.caption2)
                    .foregroundColor(themeProvider.theme.textSecondary)
                Spacer()
            }
        }
    }
}
