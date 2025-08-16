//
//  NutritionPreferencesView.swift
//  Flowmate
//
//  Comprehensive nutrition preferences management
//

import SwiftUI

struct NutritionPreferencesView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var nutritionService = NutritionService.shared
    
    @State private var preferences = NutritionPreferences()
    @State private var isLoading = false
    @State private var isSaving = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                // Dietary Restrictions Section
                Section("Dietary Restrictions") {
                    ForEach(DietaryRestriction.allCases, id: \.self) { restriction in
                        Toggle(restriction.displayName, isOn: binding(for: restriction))
                            .toggleStyle(SwitchToggleStyle(tint: themeProvider.theme.accent))
                    }
                }
                
                // Food Preferences Section
                Section("Food Preferences") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Preferred Cuisines")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(themeProvider.theme.textPrimary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                            ForEach(CuisineType.allCases, id: \.self) { cuisine in
                                PreferenceChip(
                                    title: cuisine.displayName,
                                    isSelected: preferences.preferredCuisines.contains(cuisine),
                                    color: themeProvider.theme.accent
                                ) {
                                    toggleCuisine(cuisine)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Disliked Foods")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(themeProvider.theme.textPrimary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                            ForEach(CommonFood.allCases, id: \.self) { food in
                                PreferenceChip(
                                    title: food.displayName,
                                    isSelected: preferences.dislikedFoods.contains(food),
                                    color: Color.red
                                ) {
                                    toggleDislikedFood(food)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Meal Planning Preferences
                Section("Meal Planning") {
                    HStack {
                        Text("Meals per Day")
                        Spacer()
                        Stepper("\(preferences.mealsPerDay)", value: $preferences.mealsPerDay, in: 2...6)
                            .foregroundColor(themeProvider.theme.accent)
                    }
                    
                    HStack {
                        Text("Prep Time Preference")
                        Spacer()
                        Picker("Prep Time", selection: $preferences.maxPrepTime) {
                            ForEach(PrepTimePreference.allCases, id: \.self) { time in
                                Text(time.displayName).tag(time)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .foregroundColor(themeProvider.theme.accent)
                    }
                    
                    HStack {
                        Text("Cooking Skill Level")
                        Spacer()
                        Picker("Skill Level", selection: $preferences.cookingSkill) {
                            ForEach(CookingSkill.allCases, id: \.self) { skill in
                                Text(skill.displayName).tag(skill)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .foregroundColor(themeProvider.theme.accent)
                    }
                    
                    Toggle("Include Snacks", isOn: $preferences.includeSnacks)
                        .toggleStyle(SwitchToggleStyle(tint: themeProvider.theme.accent))
                    
                    Toggle("Meal Prep Friendly", isOn: $preferences.mealPrepFriendly)
                        .toggleStyle(SwitchToggleStyle(tint: themeProvider.theme.accent))
                }
                
                // Budget Section
                Section("Budget Preferences") {
                    HStack {
                        Text("Budget Level")
                        Spacer()
                        Picker("Budget", selection: $preferences.budgetLevel) {
                            ForEach(BudgetLevel.allCases, id: \.self) { budget in
                                Text(budget.displayName).tag(budget)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .foregroundColor(themeProvider.theme.accent)
                    }
                    
                    Toggle("Prefer Local/Seasonal", isOn: $preferences.preferLocalSeasonal)
                        .toggleStyle(SwitchToggleStyle(tint: themeProvider.theme.accent))
                }
                
                // Health Goals Integration
                Section("Health Integration") {
                    Toggle("Consider Workout Schedule", isOn: $preferences.considerWorkoutSchedule)
                        .toggleStyle(SwitchToggleStyle(tint: themeProvider.theme.accent))
                    
                    Toggle("Optimize for Recovery", isOn: $preferences.optimizeForRecovery)
                        .toggleStyle(SwitchToggleStyle(tint: themeProvider.theme.accent))
                    
                    Toggle("Include Supplements", isOn: $preferences.includeSupplements)
                        .toggleStyle(SwitchToggleStyle(tint: themeProvider.theme.accent))
                }
            }
            .scrollContentBackground(.hidden)
            .background(ThemedBackground().environmentObject(themeProvider))
            .navigationTitle("Nutrition Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(themeProvider.theme.accent)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await savePreferences() }
                    } label: {
                        if isSaving {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundColor(themeProvider.theme.accent)
                    .disabled(isSaving)
                }
            }
            .task {
                await loadPreferences()
            }
            .alert("Preferences", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // MARK: - Helper Functions
    private func binding(for restriction: DietaryRestriction) -> Binding<Bool> {
        Binding(
            get: { preferences.dietaryRestrictions.contains(restriction) },
            set: { isSelected in
                if isSelected {
                    preferences.dietaryRestrictions.insert(restriction)
                } else {
                    preferences.dietaryRestrictions.remove(restriction)
                }
            }
        )
    }
    
    private func toggleCuisine(_ cuisine: CuisineType) {
        if preferences.preferredCuisines.contains(cuisine) {
            preferences.preferredCuisines.remove(cuisine)
        } else {
            preferences.preferredCuisines.insert(cuisine)
        }
    }
    
    private func toggleDislikedFood(_ food: CommonFood) {
        if preferences.dislikedFoods.contains(food) {
            preferences.dislikedFoods.remove(food)
        } else {
            preferences.dislikedFoods.insert(food)
        }
    }
    
    private func loadPreferences() async {
        await MainActor.run { isLoading = true }
        
        do {
            // Load from backend or use defaults
            if let saved = try await nutritionService.getNutritionPreferences() {
                await MainActor.run {
                    self.preferences = saved
                }
            }
        } catch {
            print("Failed to load preferences: \(error)")
        }
        
        await MainActor.run { isLoading = false }
    }
    
    private func savePreferences() async {
        await MainActor.run { isSaving = true }
        
        do {
            try await nutritionService.saveNutritionPreferences(preferences)
            await MainActor.run {
                self.isSaving = false
                self.alertMessage = "Preferences saved successfully!"
                self.showingAlert = true
            }
        } catch {
            await MainActor.run {
                self.isSaving = false
                self.alertMessage = "Failed to save preferences: \(error.localizedDescription)"
                self.showingAlert = true
            }
        }
    }
}

// MARK: - Supporting Views
struct PreferenceChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? color : color.opacity(0.1))
                        .overlay(
                            Capsule()
                                .stroke(color.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// WrapHStack moved to shared components to avoid duplication

// MARK: - Preview
struct NutritionPreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        NutritionPreferencesView()
            .environmentObject(ThemeProvider())
    }
}
