//
//  QuickCalorieAddView.swift
//  Flowmate
//
//  Quick calorie tracking component
//

import SwiftUI

struct QuickCalorieAddView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var nutritionService = NutritionService.shared
    
    @State private var calories: String = ""
    @State private var description: String = ""
    @State private var selectedMealType: MealType = .snack
    @State private var isLogging = false
    @State private var showingSuccess = false
    
    // Quick add presets
    private let quickPresets = [
        ("🍎", "Apple", 80),
        ("🍌", "Banana", 105),
        ("🥛", "Glass of Milk", 150),
        ("🍫", "Chocolate Bar", 250),
        ("☕️", "Coffee", 5),
        ("🥤", "Soda Can", 140),
        ("🍪", "Cookie", 150),
        ("🥜", "Handful Nuts", 200)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Manual Input Section
                    manualInputSection
                    
                    // Quick Presets
                    quickPresetsSection
                    
                    // Action Button
                    actionButton
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .background(ThemedBackground().environmentObject(themeProvider))
            .navigationTitle("Quick Add Calories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(themeProvider.theme.accent)
                }
            }
            .alert("Calories Added!", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Successfully added \(calories) calories to your log.")
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [themeProvider.theme.accent, themeProvider.theme.accent.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Quick Add Calories")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(themeProvider.theme.textPrimary)
            
            Text("Add calories when you don't have detailed nutrition info")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(themeProvider.theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    private var manualInputSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Manual Entry")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(themeProvider.theme.textPrimary)
            
            VStack(spacing: 16) {
                // Calories Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Calories")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeProvider.theme.textPrimary)
                    
                    TextField("Enter calories", text: $calories)
                        .keyboardType(.numberPad)
                        .textFieldStyle(CustomTextFieldStyle())
                        .environmentObject(themeProvider)
                }
                
                // Description Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description (Optional)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeProvider.theme.textPrimary)
                    
                    TextField("What did you eat?", text: $description)
                        .textFieldStyle(CustomTextFieldStyle())
                        .environmentObject(themeProvider)
                }
                
                // Meal Type Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Meal Type")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeProvider.theme.textPrimary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach([MealType.breakfast, .lunch, .dinner, .snack], id: \.self) { mealType in
                                Button {
                                    selectedMealType = mealType
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: mealType.icon)
                                        Text(mealType.displayName)
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    .foregroundColor(selectedMealType == mealType ? .white : themeProvider.theme.textPrimary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(selectedMealType == mealType ? themeProvider.theme.accent : themeProvider.theme.backgroundSecondary)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeProvider.theme.backgroundSecondary)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
        }
    }
    
    private var quickPresetsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Presets")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(themeProvider.theme.textPrimary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                ForEach(quickPresets.indices, id: \.self) { index in
                    let preset = quickPresets[index]
                    QuickPresetCard(
                        emoji: preset.0,
                        name: preset.1,
                        calories: preset.2
                    ) {
                        usePreset(preset.1, calories: preset.2)
                    }
                }
            }
        }
    }
    
    private var actionButton: some View {
        Button {
            Task { await addCalories() }
        } label: {
            HStack {
                if isLogging {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "plus.circle.fill")
                }
                Text(isLogging ? "Adding..." : "Add Calories")
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [themeProvider.theme.accent, themeProvider.theme.accent.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(calories.isEmpty || isLogging)
        .opacity(calories.isEmpty ? 0.6 : 1.0)
    }
    
    // MARK: - Helper Functions
    private func usePreset(_ name: String, calories: Int) {
        self.calories = String(calories)
        self.description = name
    }
    
    private func addCalories() async {
        guard let calorieAmount = Int(calories), calorieAmount > 0 else { return }
        
        await MainActor.run { isLogging = true }
        
        do {
            _ = try await nutritionService.quickAddCalories(
                calories: calorieAmount,
                description: description.isEmpty ? nil : description,
                mealType: selectedMealType
            )
            
            await MainActor.run {
                isLogging = false
                showingSuccess = true
            }
        } catch {
            await MainActor.run {
                isLogging = false
                // Could show error alert here
            }
            print("Failed to add calories: \(error)")
        }
    }
}

// MARK: - Supporting Views
struct QuickPresetCard: View {
    let emoji: String
    let name: String
    let calories: Int
    let action: () -> Void
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(emoji)
                    .font(.system(size: 32))
                
                Text(name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeProvider.theme.textPrimary)
                    .lineLimit(1)
                
                Text("\(calories) cal")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeProvider.theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeProvider.theme.backgroundSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(themeProvider.theme.accent.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    @EnvironmentObject var themeProvider: ThemeProvider
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(themeProvider.theme.backgroundPrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(themeProvider.theme.accent.opacity(0.3), lineWidth: 1)
                    )
            )
            .foregroundColor(themeProvider.theme.textPrimary)
    }
}

#Preview {
    QuickCalorieAddView()
        .environmentObject(ThemeProvider())
}
