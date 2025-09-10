import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @State private var preferences: [String: Any] = [:]
    @State private var selectedMotivations: [String] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    // Expandable sections state
    @State private var expandedSections: Set<String> = []
    
    // Preference categories state
    @State private var aestheticsPrefs = AestheticsPreferences()
    @State private var performancePrefs = PerformancePreferences()
    @State private var weightPrefs = WeightManagementPreferences()
    @State private var longevityPrefs = LongevityPreferences()
    @State private var mindsetPrefs = MindsetStressPreferences()

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    VStack {
                        ProgressView()
                        Text("Loading preferences...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text("Unable to load preferences")
                            .font(.headline)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task { await loadPreferences() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    preferencesContent
                }
            }
            .navigationTitle("Preferences")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await loadPreferences()
            }
        }
    }
    
    private var preferencesContent: some View {
        List {
            // Header section
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Personalization")
                        .font(.headline)
                    Text("Your selections shape how AI personalizes workouts, nutrition, and guidance.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            
            // Dynamic sections based on selected motivations
            ForEach(selectedMotivations, id: \.self) { motivation in
                motivationSection(for: motivation)
            }
            
            // Add new motivations section
            Section {
                Button(action: { /* TODO: Allow adding new motivations */ }) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Add motivation focus")
                        Spacer()
                    }
                    .foregroundColor(themeProvider.theme.accent)
                }
            } header: {
                Text("Add Focus Areas")
            }
        }
        .listStyle(.insetGrouped)
    }
    
    @ViewBuilder
    private func motivationSection(for motivation: String) -> some View {
        let isExpanded = expandedSections.contains(motivation)
        
        Section {
            DisclosureGroup(
                isExpanded: Binding(
                    get: { isExpanded },
                    set: { expanded in
                        if expanded {
                            expandedSections.insert(motivation)
                        } else {
                            expandedSections.remove(motivation)
                        }
                    }
                )
            ) {
                motivationContent(for: motivation)
            } label: {
                HStack {
                    Image(systemName: motivationIcon(for: motivation))
                        .foregroundColor(themeProvider.theme.accent)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(motivationTitle(for: motivation))
                            .font(.subheadline.weight(.medium))
                        Text(motivationDescription(for: motivation))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    @ViewBuilder
    private func motivationContent(for motivation: String) -> some View {
        switch motivation {
        case "aesthetics":
            aestheticsPreferencesView
        case "performance":
            performancePreferencesView
        case "weight":
            weightManagementPreferencesView
        case "longevity":
            longevityPreferencesView
        case "mindset":
            mindsetStressPreferencesView
        default:
            Text("Preferences for \(motivation)")
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Preference Sections
    
    private var aestheticsPreferencesView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Primary focus", selection: $aestheticsPrefs.primaryFocus) {
                ForEach(AestheticsPreferences.Focus.allCases, id: \.self) { focus in
                    Text(focus.displayName).tag(focus)
                }
            }
            .pickerStyle(.segmented)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Muscle emphasis")
                    .font(.subheadline.weight(.medium))
                ForEach(AestheticsPreferences.MuscleEmphasis.allCases, id: \.self) { emphasis in
                    Toggle(emphasis.displayName, isOn: Binding(
                        get: { aestheticsPrefs.muscleEmphasis.contains(emphasis) },
                        set: { isOn in
                            if isOn {
                                aestheticsPrefs.muscleEmphasis.insert(emphasis)
                            } else {
                                aestheticsPrefs.muscleEmphasis.remove(emphasis)
                            }
                        }
                    ))
                }
            }
            
            Button("Save Aesthetics Preferences") {
                Task { await savePreferences(for: "aesthetics") }
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 8)
    }
    
    private var performancePreferencesView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Training focus", selection: $performancePrefs.trainingFocus) {
                ForEach(PerformancePreferences.TrainingFocus.allCases, id: \.self) { focus in
                    Text(focus.displayName).tag(focus)
                }
            }
            .pickerStyle(.segmented)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Goal types")
                    .font(.subheadline.weight(.medium))
                ForEach(PerformancePreferences.GoalType.allCases, id: \.self) { goal in
                    Toggle(goal.displayName, isOn: Binding(
                        get: { performancePrefs.goalTypes.contains(goal) },
                        set: { isOn in
                            if isOn {
                                performancePrefs.goalTypes.insert(goal)
                            } else {
                                performancePrefs.goalTypes.remove(goal)
                            }
                        }
                    ))
                }
            }
            
            Button("Save Performance Preferences") {
                Task { await savePreferences(for: "performance") }
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 8)
    }
    
    private var weightManagementPreferencesView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Primary goal", selection: $weightPrefs.primaryGoal) {
                ForEach(WeightManagementPreferences.Goal.allCases, id: \.self) { goal in
                    Text(goal.displayName).tag(goal)
                }
            }
            .pickerStyle(.segmented)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Adherence strategy")
                    .font(.subheadline.weight(.medium))
                Picker("Strategy", selection: $weightPrefs.adherenceStrategy) {
                    ForEach(WeightManagementPreferences.AdherenceStrategy.allCases, id: \.self) { strategy in
                        Text(strategy.displayName).tag(strategy)
                    }
                }
                .pickerStyle(.menu)
            }
            
            Button("Save Weight Management Preferences") {
                Task { await savePreferences(for: "weight") }
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 8)
    }
    
    private var longevityPreferencesView: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Focus areas")
                    .font(.subheadline.weight(.medium))
                ForEach(LongevityPreferences.FocusArea.allCases, id: \.self) { area in
                    Toggle(area.displayName, isOn: Binding(
                        get: { longevityPrefs.focusAreas.contains(area) },
                        set: { isOn in
                            if isOn {
                                longevityPrefs.focusAreas.insert(area)
                            } else {
                                longevityPrefs.focusAreas.remove(area)
                            }
                        }
                    ))
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Recovery priority")
                    .font(.subheadline.weight(.medium))
                Picker("Priority", selection: $longevityPrefs.recoveryPriority) {
                    ForEach(LongevityPreferences.RecoveryPriority.allCases, id: \.self) { priority in
                        Text(priority.displayName).tag(priority)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Button("Save Longevity Preferences") {
                Task { await savePreferences(for: "longevity") }
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 8)
    }
    
    private var mindsetStressPreferencesView: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Session length preference")
                    .font(.subheadline.weight(.medium))
                Picker("Length", selection: $mindsetPrefs.sessionLength) {
                    ForEach(MindsetStressPreferences.SessionLength.allCases, id: \.self) { length in
                        Text(length.displayName).tag(length)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Stress relief methods")
                    .font(.subheadline.weight(.medium))
                ForEach(MindsetStressPreferences.StressRelief.allCases, id: \.self) { method in
                    Toggle(method.displayName, isOn: Binding(
                        get: { mindsetPrefs.stressReliefMethods.contains(method) },
                        set: { isOn in
                            if isOn {
                                mindsetPrefs.stressReliefMethods.insert(method)
                            } else {
                                mindsetPrefs.stressReliefMethods.remove(method)
                            }
                        }
                    ))
                }
            }
            
            Button("Save Mindset Preferences") {
                Task { await savePreferences(for: "mindset") }
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Helper Methods
    
    private func motivationIcon(for motivation: String) -> String {
        switch motivation {
        case "aesthetics": return "person.crop.circle"
        case "performance": return "bolt.fill"
        case "weight": return "scalemass"
        case "longevity": return "heart.text.square"
        case "mindset": return "brain.head.profile"
        default: return "circle"
        }
    }
    
    private func motivationTitle(for motivation: String) -> String {
        switch motivation {
        case "aesthetics": return "Aesthetics"
        case "performance": return "Performance"
        case "weight": return "Weight Management"
        case "longevity": return "Longevity & Health"
        case "mindset": return "Mindset & Stress"
        default: return motivation.capitalized
        }
    }
    
    private func motivationDescription(for motivation: String) -> String {
        switch motivation {
        case "aesthetics": return "Body composition and visual goals"
        case "performance": return "Strength, endurance, and PRs"
        case "weight": return "Cutting, bulking, and adherence"
        case "longevity": return "Mobility, recovery, and health"
        case "mindset": return "Stress management and routine"
        default: return "Personalization options"
        }
    }
    
    private func loadPreferences() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // This would fetch from BackendAPIClient.shared.getPreferences() in real implementation
            // For now, mock the response
            await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Mock preferences data
            let mockPrefs: [String: Any] = [
                "motivation": ["aesthetics", "performance", "weight"]
            ]
            
            await MainActor.run {
                self.preferences = mockPrefs
                if let motivations = mockPrefs["motivation"] as? [String] {
                    self.selectedMotivations = motivations
                }
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    private func savePreferences(for motivation: String) async {
        // Create the appropriate preference object based on motivation
        var prefsToSave: [String: Any] = [:]
        
        switch motivation {
        case "aesthetics":
            prefsToSave = [
                "aesthetics": [
                    "primaryFocus": aestheticsPrefs.primaryFocus.rawValue,
                    "muscleEmphasis": aestheticsPrefs.muscleEmphasis.map { $0.rawValue }
                ]
            ]
        case "performance":
            prefsToSave = [
                "performance": [
                    "trainingFocus": performancePrefs.trainingFocus.rawValue,
                    "goalTypes": performancePrefs.goalTypes.map { $0.rawValue }
                ]
            ]
        case "weight":
            prefsToSave = [
                "weight": [
                    "primaryGoal": weightPrefs.primaryGoal.rawValue,
                    "adherenceStrategy": weightPrefs.adherenceStrategy.rawValue
                ]
            ]
        case "longevity":
            prefsToSave = [
                "longevity": [
                    "focusAreas": longevityPrefs.focusAreas.map { $0.rawValue },
                    "recoveryPriority": longevityPrefs.recoveryPriority.rawValue
                ]
            ]
        case "mindset":
            prefsToSave = [
                "mindset": [
                    "sessionLength": mindsetPrefs.sessionLength.rawValue,
                    "stressReliefMethods": mindsetPrefs.stressReliefMethods.map { $0.rawValue }
                ]
            ]
        default:
            return
        }
        
        do {
            _ = try await BackendAPIClient.shared.updatePreferences(prefsToSave)
            // Show success feedback
        } catch {
            // Show error feedback
            print("Failed to save preferences: \(error)")
        }
    }
}

// MARK: - Preference Models

struct AestheticsPreferences {
    var primaryFocus: Focus = .bodyComposition
    var muscleEmphasis: Set<MuscleEmphasis> = []
    
    enum Focus: String, CaseIterable {
        case bodyComposition = "body_composition"
        case muscleTone = "muscle_tone"
        case definition = "definition"
        
        var displayName: String {
            switch self {
            case .bodyComposition: return "Body Comp"
            case .muscleTone: return "Muscle Tone"
            case .definition: return "Definition"
            }
        }
    }
    
    enum MuscleEmphasis: String, CaseIterable {
        case upper = "upper"
        case lower = "lower"
        case core = "core"
        case shoulders = "shoulders"
        case arms = "arms"
        
        var displayName: String {
            switch self {
            case .upper: return "Upper Body"
            case .lower: return "Lower Body"
            case .core: return "Core"
            case .shoulders: return "Shoulders"
            case .arms: return "Arms"
            }
        }
    }
}

struct PerformancePreferences {
    var trainingFocus: TrainingFocus = .strength
    var goalTypes: Set<GoalType> = []
    
    enum TrainingFocus: String, CaseIterable {
        case strength = "strength"
        case endurance = "endurance"
        case power = "power"
        
        var displayName: String {
            switch self {
            case .strength: return "Strength"
            case .endurance: return "Endurance"
            case .power: return "Power"
            }
        }
    }
    
    enum GoalType: String, CaseIterable {
        case prs = "prs"
        case cardio = "cardio"
        case athletic = "athletic"
        case functional = "functional"
        
        var displayName: String {
            switch self {
            case .prs: return "Personal Records"
            case .cardio: return "Cardio Performance"
            case .athletic: return "Athletic Performance"
            case .functional: return "Functional Fitness"
            }
        }
    }
}

struct WeightManagementPreferences {
    var primaryGoal: Goal = .maintenance
    var adherenceStrategy: AdherenceStrategy = .flexible
    
    enum Goal: String, CaseIterable {
        case cutting = "cutting"
        case bulking = "bulking"
        case maintenance = "maintenance"
        
        var displayName: String {
            switch self {
            case .cutting: return "Cutting"
            case .bulking: return "Bulking"
            case .maintenance: return "Maintenance"
            }
        }
    }
    
    enum AdherenceStrategy: String, CaseIterable {
        case strict = "strict"
        case flexible = "flexible"
        case intuitive = "intuitive"
        
        var displayName: String {
            switch self {
            case .strict: return "Strict tracking"
            case .flexible: return "Flexible approach"
            case .intuitive: return "Intuitive eating"
            }
        }
    }
}

struct LongevityPreferences {
    var focusAreas: Set<FocusArea> = []
    var recoveryPriority: RecoveryPriority = .moderate
    
    enum FocusArea: String, CaseIterable {
        case mobility = "mobility"
        case stability = "stability"
        case balance = "balance"
        case cardiovascular = "cardiovascular"
        case cognitive = "cognitive"
        
        var displayName: String {
            switch self {
            case .mobility: return "Mobility"
            case .stability: return "Stability"
            case .balance: return "Balance"
            case .cardiovascular: return "Cardiovascular Health"
            case .cognitive: return "Cognitive Health"
            }
        }
    }
    
    enum RecoveryPriority: String, CaseIterable {
        case low = "low"
        case moderate = "moderate"
        case high = "high"
        
        var displayName: String {
            switch self {
            case .low: return "Low Priority"
            case .moderate: return "Moderate"
            case .high: return "High Priority"
            }
        }
    }
}

struct MindsetStressPreferences {
    var sessionLength: SessionLength = .medium
    var stressReliefMethods: Set<StressRelief> = []
    
    enum SessionLength: String, CaseIterable {
        case short = "short"
        case medium = "medium"
        case long = "long"
        
        var displayName: String {
            switch self {
            case .short: return "15-30 min"
            case .medium: return "30-45 min"
            case .long: return "45+ min"
            }
        }
    }
    
    enum StressRelief: String, CaseIterable {
        case meditation = "meditation"
        case breathing = "breathing"
        case gentle = "gentle"
        case music = "music"
        
        var displayName: String {
            switch self {
            case .meditation: return "Meditation"
            case .breathing: return "Breathing exercises"
            case .gentle: return "Gentle movement"
            case .music: return "Music/audio"
            }
        }
    }
}

#Preview {
    PreferencesView()
        .environmentObject(ThemeProvider())
}
