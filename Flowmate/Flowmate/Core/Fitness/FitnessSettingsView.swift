//
//  FitnessSettingsView.swift
//  Flowmate
//
//  Created on 2025-01-13
//

import SwiftUI

struct FitnessSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var themeProvider: ThemeProvider
    @EnvironmentObject var authService: AuthenticationService
    
    @State private var fitnessLevel: FitnessLevel = .beginner
    @State private var preferredActivities: Set<ActivityType> = []
    @State private var availableEquipment: Set<Equipment> = []
    @State private var workoutDuration: WorkoutDuration = .medium
    @State private var workoutFrequency: WorkoutFrequency = .moderate
    @State private var limitations: String = ""
    @State private var isSaving = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Fitness Preferences")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(themeProvider.theme.textPrimary)
                        
                        Text("Customize your fitness journey")
                            .font(.subheadline)
                            .foregroundColor(themeProvider.theme.textSecondary)
                    }
                    .padding(.top)
                    
                    // Fitness Level
                    PreferenceSection(title: "Fitness Level", icon: "trophy.fill") {
                        VStack(spacing: 12) {
                            ForEach(FitnessLevel.allCases, id: \.self) { level in
                                PreferenceCard(
                                    title: level.displayName,
                                    subtitle: level.description,
                                    isSelected: fitnessLevel == level
                                ) {
                                    fitnessLevel = level
                                }
                            }
                        }
                    }
                    
                    // Workout Duration
                    PreferenceSection(title: "Workout Duration", icon: "clock.fill") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                            ForEach(WorkoutDuration.allCases, id: \.self) { duration in
                                CompactPreferenceCard(
                                    title: duration.displayName,
                                    isSelected: workoutDuration == duration
                                ) {
                                    workoutDuration = duration
                                }
                            }
                        }
                    }
                    
                    // Workout Frequency
                    PreferenceSection(title: "Workout Frequency", icon: "calendar.circle.fill") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                            ForEach(WorkoutFrequency.allCases, id: \.self) { frequency in
                                CompactPreferenceCard(
                                    title: frequency.displayName,
                                    isSelected: workoutFrequency == frequency
                                ) {
                                    workoutFrequency = frequency
                                }
                            }
                        }
                    }
                    
                    // Preferred Activities
                    PreferenceSection(title: "Preferred Activities", icon: "figure.run") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                            ForEach(ActivityType.allCases, id: \.self) { activity in
                                ActivityChip(
                                    activity: activity,
                                    isSelected: preferredActivities.contains(activity)
                                ) {
                                    if preferredActivities.contains(activity) {
                                        preferredActivities.remove(activity)
                                    } else {
                                        preferredActivities.insert(activity)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Available Equipment
                    PreferenceSection(title: "Available Equipment", icon: "dumbbell.fill") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                            ForEach(Equipment.allCases, id: \.self) { equipment in
                                CompactPreferenceCard(
                                    title: equipment.displayName,
                                    isSelected: availableEquipment.contains(equipment)
                                ) {
                                    if availableEquipment.contains(equipment) {
                                        availableEquipment.remove(equipment)
                                    } else {
                                        availableEquipment.insert(equipment)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Limitations
                    PreferenceSection(title: "Physical Limitations", icon: "heart.text.square.fill") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Any injuries, conditions, or areas to avoid")
                                .font(.caption)
                                .foregroundColor(themeProvider.theme.textSecondary)
                            
                            TextField("e.g., knee injury, lower back issues", text: $limitations, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(3...6)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .background(ThemedBackground().environmentObject(themeProvider))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        savePreferences()
                    }
                    .disabled(isSaving)
                }
            }
        }
        .onAppear {
            loadCurrentPreferences()
        }
    }
    
    private func loadCurrentPreferences() {
        if let prefs = authService.currentUser?.preferences?.fitness {
            fitnessLevel = prefs.level
            preferredActivities = Set(prefs.preferredActivities)
            availableEquipment = Set(prefs.availableEquipment)
            workoutDuration = prefs.workoutDuration
            workoutFrequency = prefs.workoutFrequency
            limitations = prefs.limitations.joined(separator: ", ")
        }
    }
    
    private func savePreferences() {
        isSaving = true
        
        let newPrefs = FitnessPreferences(
            level: fitnessLevel,
            preferredActivities: Array(preferredActivities),
            availableEquipment: Array(availableEquipment),
            workoutDuration: workoutDuration,
            workoutFrequency: workoutFrequency,
            limitations: limitations.isEmpty ? [] : limitations.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        )
        
        // Update user preferences via backend
        Task {
            await authService.updateFitnessPreferences(newPrefs)
            DispatchQueue.main.async {
                self.isSaving = false
                self.dismiss()
            }
        }
    }
}

// MARK: - Supporting Views

private struct PreferenceSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(themeProvider.theme.accent)
                    .font(.title2)
                
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(themeProvider.theme.textPrimary)
            }
            
            content
        }
    }
}

private struct PreferenceCard: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(themeProvider.theme.textPrimary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(themeProvider.theme.textSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(themeProvider.theme.accent)
                        .font(.title2)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? themeProvider.theme.accent.opacity(0.1) : themeProvider.theme.backgroundSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? themeProvider.theme.accent : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

private struct CompactPreferenceCard: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? .white : themeProvider.theme.textPrimary)
                .padding(.vertical, 12)
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? themeProvider.theme.accent : themeProvider.theme.backgroundSecondary)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct ActivityChip: View {
    let activity: ActivityType
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: activity.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : themeProvider.theme.accent)
                
                Text(activity.displayName)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white : themeProvider.theme.textPrimary)
                    .lineLimit(1)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? themeProvider.theme.accent : themeProvider.theme.backgroundSecondary)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FitnessSettingsView()
        .environmentObject(ThemeProvider())
        .environmentObject(AuthenticationService())
}
