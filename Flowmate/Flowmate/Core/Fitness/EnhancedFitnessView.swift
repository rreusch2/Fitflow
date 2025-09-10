//
//  EnhancedFitnessView.swift
//  Flowmate
//
//  Created on 2025-01-13
//

import SwiftUI
import Combine

struct EnhancedFitnessView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @EnvironmentObject var authService: AuthenticationService
    @State private var selectedMuscleGroups: Set<MuscleGroup> = []
    @State private var selectedWorkoutType: WorkoutType = .strength
    @State private var selectedDifficulty: DifficultyLevel = .intermediate
    @State private var selectedDuration: AIWorkoutDuration = .medium
    @State private var isGeneratingWorkout = false
    @State private var generatedWorkout: WorkoutPlanResponse?
    @State private var showWorkoutPlan = false
    @StateObject private var workoutService = WorkoutService.shared
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var showLogWorkout = false
    @State private var showProgressTracker = false
    @State private var showNutritionInsights = false
    @State private var showFitnessSettings = false
    
    private var fitnessPrefs: FitnessPreferences? {
        authService.currentUser?.preferences?.fitness
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Enhanced Header with Stats
                    headerSection
                    
                    // Professional Stats Grid
                    enhancedStatsGrid
                    
                    // Log Workout Button
                    HStack {
                        Button {
                            showLogWorkout = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.pencil")
                                Text("Log Workout")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(themeProvider.theme.accent)
                            )
                            .shadow(color: themeProvider.theme.accent.opacity(0.25), radius: 6, x: 0, y: 3)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)

                    // AI Workout Generator
                    workoutGeneratorSection
                    
                    // Quick Actions
                    quickActionsSection
                    
                    // Progress Insights
                    progressInsightsSection
                    
                    // AI Coach Integration
                    aiCoachSection
                }
                .padding(.bottom, 100) // Account for tab bar
            }
            .background(ThemedBackground().environmentObject(themeProvider))
            .navigationTitle("Fitness")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showFitnessSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(themeProvider.theme.accent)
                    }
                }
            }
            .sheet(isPresented: $showWorkoutPlan) {
                if let workout = generatedWorkout {
                    AIWorkoutPlanView(workout: workout)
                        .environmentObject(themeProvider)
                }
            }
            .sheet(isPresented: $showLogWorkout) {
                LogWorkoutSheet()
                    .environmentObject(themeProvider)
            }
            .sheet(isPresented: $showProgressTracker) {
                ProgressTrackerView()
                    .environmentObject(themeProvider)
            }
            .sheet(isPresented: $showNutritionInsights) {
                NutritionInsightsView()
                    .environmentObject(themeProvider)
            }
            .sheet(isPresented: $showFitnessSettings) {
                FitnessSettingsView()
                    .environmentObject(themeProvider)
                    .environmentObject(authService)
            }
            .alert("Workout Generation Failed", isPresented: $showErrorAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Fitness Journey")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(themeProvider.theme.textPrimary)
                    
                    Text("Powered by AI • Personalized for you")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeProvider.theme.accent)
                }
                
                Spacer()
                
                // Streak indicator
                VStack(spacing: 4) {
                    Text("🔥")
                        .font(.system(size: 24))
                    Text("7 days")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(themeProvider.theme.accent)
                }
                .padding(12)
                .background(
                    Circle()
                        .fill(themeProvider.theme.accent.opacity(0.1))
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }
    
    // MARK: - Enhanced Stats Grid
    private var enhancedStatsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
            EnhancedStatsCard(
                title: "Fitness Level",
                value: fitnessPrefs?.level.displayName ?? "Beginner",
                icon: "trophy.fill",
                gradient: [Color.orange, Color.red],
                subtitle: "Keep pushing!"
            )
            
            EnhancedStatsCard(
                title: "Weekly Goal",
                value: fitnessPrefs?.workoutFrequency.displayName ?? "3-4 times per week",
                icon: "target",
                gradient: [Color.blue, Color.purple],
                subtitle: "On track"
            )
            
            EnhancedStatsCard(
                title: "Avg Duration",
                value: fitnessPrefs?.workoutDuration.displayName ?? "45 min",
                icon: "clock.fill",
                gradient: [Color.green, Color.teal],
                subtitle: "Perfect pace"
            )
            
            EnhancedStatsCard(
                title: "Activities",
                value: "\(fitnessPrefs?.preferredActivities.count ?? 3) types",
                icon: "heart.fill",
                gradient: [Color.pink, Color.purple],
                subtitle: "Variety is key"
            )
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Workout Generator Section
    private var workoutGeneratorSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Workout Generator")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(themeProvider.theme.textPrimary)
                    
                    Text("Create personalized workouts instantly")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeProvider.theme.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(themeProvider.theme.accent)
            }
            
            // Muscle Group Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Target Muscle Groups")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeProvider.theme.textPrimary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(MuscleGroup.allCases, id: \.self) { group in
                        MuscleGroupButton(
                            group: group,
                            isSelected: selectedMuscleGroups.contains(group)
                        ) {
                            if selectedMuscleGroups.contains(group) {
                                selectedMuscleGroups.remove(group)
                            } else {
                                selectedMuscleGroups.insert(group)
                            }
                        }
                    }
                }
            }
            
            // Workout Type & Settings
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Type")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(themeProvider.theme.textSecondary)
                        
                        Menu {
                            ForEach(WorkoutType.allCases, id: \.self) { type in
                                Button(type.displayName) {
                                    selectedWorkoutType = type
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedWorkoutType.displayName)
                                    .font(.system(size: 14, weight: .medium))
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(themeProvider.theme.textPrimary)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(themeProvider.theme.backgroundSecondary)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Duration")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(themeProvider.theme.textSecondary)
                        
                        Menu {
                            ForEach(AIWorkoutDuration.allCases, id: \.self) { duration in
                                Button(duration.displayName) {
                                    selectedDuration = duration
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedDuration.displayName)
                                    .font(.system(size: 14, weight: .medium))
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(themeProvider.theme.textPrimary)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(themeProvider.theme.backgroundSecondary)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                }
            }
            
            // Generate Button
            Button {
                print("🔥 DEBUG: Generate AI Workout button pressed!")
                print("🔥 DEBUG: Selected muscle groups: \(selectedMuscleGroups)")
                Task {
                    await generateWorkout()
                }
            } label: {
                HStack {
                    if workoutService.isGeneratingWorkout {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                        Text("Generating with AI...")
                    } else {
                        Image(systemName: "sparkles")
                        Text("Generate AI Workout")
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: selectedMuscleGroups.isEmpty ? 
                            [Color.gray, Color.gray.opacity(0.8)] :
                            [themeProvider.theme.accent, themeProvider.theme.accent.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: themeProvider.theme.accent.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(selectedMuscleGroups.isEmpty || workoutService.isGeneratingWorkout)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeProvider.theme.backgroundSecondary)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeProvider.theme.textPrimary)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    QuickActionCard(
                        title: "Progress Tracker",
                        subtitle: "View your journey",
                        icon: "chart.line.uptrend.xyaxis",
                        gradient: [Color.blue, Color.cyan]
                    ) {
                        showProgressTracker = true
                    }
                    
                    QuickActionCard(
                        title: "Nutrition AI",
                        subtitle: "Meal insights",
                        icon: "leaf.fill",
                        gradient: [Color.green, Color.mint]
                    ) {
                        showNutritionInsights = true
                    }
                    
                    QuickActionCard(
                        title: "Form Check",
                        subtitle: "Perfect technique",
                        icon: "figure.strengthtraining.traditional",
                        gradient: [Color.orange, Color.yellow]
                    ) {
                        // Form check action
                    }
                    
                    QuickActionCard(
                        title: "Recovery",
                        subtitle: "Rest & restore",
                        icon: "bed.double.fill",
                        gradient: [Color.purple, Color.pink]
                    ) {
                        // Recovery action
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Progress Insights
    private var progressInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("AI Insights")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(themeProvider.theme.textPrimary)
                
                Spacer()
                
                Text("Updated now")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeProvider.theme.textSecondary)
            }
            
            VStack(spacing: 12) {
                InsightCard(
                    insight: "Your consistency has improved 40% this month! Keep up the momentum.",
                    type: .positive,
                    icon: "arrow.up.circle.fill"
                )
                
                InsightCard(
                    insight: "Consider adding more cardio to balance your strength training routine.",
                    type: .suggestion,
                    icon: "lightbulb.fill"
                )
                
                InsightCard(
                    insight: "Your rest periods between sets could be optimized for better gains.",
                    type: .tip,
                    icon: "clock.badge.checkmark.fill"
                )
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - AI Coach Section
    private var aiCoachSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Fitness Coach")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeProvider.theme.textPrimary)
                .padding(.horizontal, 20)

            // Simple card with CTA to open the full Coach chat
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "brain.head.profile")
                        .foregroundStyle(themeProvider.theme.accent)
                    Text("Get personalized workout guidance, form tips, and recovery advice.")
                        .foregroundColor(themeProvider.theme.textSecondary)
                        .font(.subheadline)
                }

                NavigationLink {
                    CoachChatView()
                        .environmentObject(themeProvider)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "message.fill")
                        Text("Open Coach")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(themeProvider.theme.accent)
                    )
                }
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Functions
    private func generateWorkout() async {
        print("🔥 DEBUG: generateWorkout() function called")
        
        guard !selectedMuscleGroups.isEmpty else { 
            print("🔥 DEBUG: No muscle groups selected, returning early")
            return 
        }
        
        print("🔥 DEBUG: About to call workoutService.generateWorkout")
        
        do {
            let workout = try await workoutService.generateWorkout(
                muscleGroups: Array(selectedMuscleGroups),
                workoutType: selectedWorkoutType,
                duration: selectedDuration,
                difficulty: selectedDifficulty
            )
            
            print("🔥 DEBUG: Workout generation successful!")
            
            await MainActor.run {
                generatedWorkout = workout
                showWorkoutPlan = true
                HapticFeedback.success()
            }
            
        } catch {
            print("🔥 DEBUG: Workout generation failed: \(error)")
            await MainActor.run {
                errorMessage = error.localizedDescription
                showErrorAlert = true
                HapticFeedback.error()
            }
        }
    }
}

// MARK: - Supporting Models

enum WorkoutType: String, CaseIterable {
    case strength = "strength"
    case cardio = "cardio"
    case hiit = "hiit"
    case yoga = "yoga"
    case mobility = "mobility"
    
    var displayName: String {
        switch self {
        case .strength: return "Strength"
        case .cardio: return "Cardio"
        case .hiit: return "HIIT"
        case .yoga: return "Yoga"
        case .mobility: return "Mobility"
        }
    }
}

enum DifficultyLevel: String, CaseIterable {
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
}

enum AIWorkoutDuration: String, CaseIterable {
    case short = "short"
    case medium = "medium"
    case long = "long"
    
    var displayName: String {
        switch self {
        case .short: return "30 min"
        case .medium: return "45 min"
        case .long: return "60+ min"
        }
    }
}

struct AIWorkoutPlan {
    let title: String
    let muscleGroups: [MuscleGroup]
    let duration: AIWorkoutDuration
    let difficulty: DifficultyLevel
    let exercises: [AIExercise]
}

struct AIExercise {
    let name: String
    let sets: Int
    let reps: String
    let rest: String
    let notes: String
}

#Preview {
    EnhancedFitnessView()
        .environmentObject(ThemeProvider())
        .environmentObject(AuthenticationService())
}
