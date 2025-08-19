//
//  MealDetailView.swift
//  Flowmate
//
//  Detailed view for a logged meal with editing capabilities
//

import SwiftUI

struct MealDetailView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @Environment(\.dismiss) private var dismiss
    @StateObject private var nutritionService = NutritionService.shared
    
    let meal: Meal
    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with meal info
                    headerSection
                    
                    // Nutrition breakdown
                    nutritionBreakdownSection
                    
                    // Foods list
                    foodsSection
                    
                    // Timing info
                    timingSection
                }
                .padding(.bottom, 100)
            }
            .background(ThemedBackground().environmentObject(themeProvider))
            .navigationTitle("Meal Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(themeProvider.theme.accent)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            isEditing = true
                        } label: {
                            Label("Edit Meal", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete Meal", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(themeProvider.theme.accent)
                    }
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            EditMealView(meal: meal)
        }
        .alert("Delete Meal", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await deleteMeal()
                }
            }
        } message: {
            Text("Are you sure you want to delete this meal? This action cannot be undone.")
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(meal.type.displayName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(meal.type.color))
                        
                        Spacer()
                        
                        Text("\(meal.calories) cal")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(themeProvider.theme.accent)
                    }
                    
                    Text(meal.name)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(themeProvider.theme.textPrimary)
                    
                    if !meal.description.isEmpty {
                        Text(meal.description)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(themeProvider.theme.textSecondary)
                            .lineLimit(3)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text(meal.type.emoji)
                        .font(.system(size: 48))
                    
                    if let timestamp = meal.timestamp {
                        Text(timestamp.formatted(date: .omitted, time: .shortened))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(themeProvider.theme.textSecondary)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var nutritionBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Nutrition Breakdown")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeProvider.theme.textPrimary)
                .padding(.horizontal, 20)
            
            HStack(spacing: 16) {
                MacroCard(
                    title: "Protein",
                    value: meal.macros.protein,
                    percentage: proteinPercentage,
                    color: .red
                )
                
                MacroCard(
                    title: "Carbs",
                    value: meal.macros.carbs,
                    percentage: carbsPercentage,
                    color: .orange
                )
                
                MacroCard(
                    title: "Fat",
                    value: meal.macros.fat,
                    percentage: fatPercentage,
                    color: .green
                )
            }
            .padding(.horizontal, 20)
            
            // Macro distribution chart
            macroDistributionChart
        }
    }
    
    private var macroDistributionChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Macro Distribution")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(themeProvider.theme.textPrimary)
                .padding(.horizontal, 20)
            
            HStack(spacing: 0) {
                Rectangle()
                    .fill(.red)
                    .frame(height: 8)
                    .frame(maxWidth: .infinity, maxHeight: 8)
                    .scaleEffect(x: proteinPercentage / 100, anchor: .leading)
                
                Rectangle()
                    .fill(.orange)
                    .frame(height: 8)
                    .frame(maxWidth: .infinity, maxHeight: 8)
                    .scaleEffect(x: carbsPercentage / 100, anchor: .leading)
                
                Rectangle()
                    .fill(.green)
                    .frame(height: 8)
                    .frame(maxWidth: .infinity, maxHeight: 8)
                    .scaleEffect(x: fatPercentage / 100, anchor: .leading)
            }
            .clipShape(Capsule())
            .background(
                Capsule()
                    .fill(themeProvider.theme.backgroundSecondary)
            )
            .padding(.horizontal, 20)
            
            HStack {
                MacroLegendItem(color: .red, label: "Protein", percentage: proteinPercentage)
                Spacer()
                MacroLegendItem(color: .orange, label: "Carbs", percentage: carbsPercentage)
                Spacer()
                MacroLegendItem(color: .green, label: "Fat", percentage: fatPercentage)
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var foodsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Foods (\(meal.foods?.count ?? 0))")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeProvider.theme.textPrimary)
                .padding(.horizontal, 20)
            
            if let foods = meal.foods, !foods.isEmpty {
                VStack(spacing: 12) {
                    ForEach(foods, id: \.id) { food in
                        FoodItemCard(food: food)
                    }
                }
                .padding(.horizontal, 20)
            } else {
                Text("No individual food items recorded")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeProvider.theme.textSecondary)
                    .italic()
                    .padding(.horizontal, 20)
            }
        }
    }
    
    private var timingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Meal Info")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeProvider.theme.textPrimary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                InfoRow(
                    icon: "clock",
                    title: "Time",
                    value: meal.timestamp?.formatted(date: .abbreviated, time: .shortened) ?? "Not recorded"
                )
                
                InfoRow(
                    icon: "fork.knife",
                    title: "Meal Type",
                    value: meal.type.displayName
                )
                
                InfoRow(
                    icon: "flame",
                    title: "Calories",
                    value: "\(meal.calories) cal"
                )
                
                if meal.foods?.count ?? 0 > 0 {
                    InfoRow(
                        icon: "list.bullet",
                        title: "Food Items",
                        value: "\(meal.foods?.count ?? 0) items"
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Computed Properties
    
    private var totalMacroCalories: Double {
        (meal.macros.protein * 4) + (meal.macros.carbs * 4) + (meal.macros.fat * 9)
    }
    
    private var proteinPercentage: Double {
        guard totalMacroCalories > 0 else { return 0 }
        return (meal.macros.protein * 4 / totalMacroCalories) * 100
    }
    
    private var carbsPercentage: Double {
        guard totalMacroCalories > 0 else { return 0 }
        return (meal.macros.carbs * 4 / totalMacroCalories) * 100
    }
    
    private var fatPercentage: Double {
        guard totalMacroCalories > 0 else { return 0 }
        return (meal.macros.fat * 9 / totalMacroCalories) * 100
    }
    
    // MARK: - Methods
    
    private func deleteMeal() async {
        // Implementation would delete meal from database
        dismiss()
    }
}

struct MacroCard: View {
    let title: String
    let value: Double
    let percentage: Double
    let color: Color
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: percentage / 100)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: percentage)
                
                Text("\(Int(percentage))%")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(themeProvider.theme.textPrimary)
            }
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeProvider.theme.textPrimary)
                
                Text("\(Int(value))g")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(color)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.05))
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

struct MacroLegendItem: View {
    let color: Color
    let label: String
    let percentage: Double
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(themeProvider.theme.textPrimary)
            
            Text("\(Int(percentage))%")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(color)
        }
    }
}

struct FoodItemCard: View {
    let food: FoodItem
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(food.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeProvider.theme.textPrimary)
                
                Text("\(food.quantity, specifier: "%.0f")g")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeProvider.theme.textSecondary)
                
                HStack(spacing: 12) {
                    Text("P: \(Int(food.totalProtein))g")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                    Text("C: \(Int(food.totalCarbs))g")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.orange)
                    Text("F: \(Int(food.totalFat))g")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            Text("\(Int(food.totalCalories)) cal")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(themeProvider.theme.accent)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(themeProvider.theme.backgroundSecondary)
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
        )
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(themeProvider.theme.accent)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeProvider.theme.textSecondary)
                
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeProvider.theme.textPrimary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeProvider.theme.backgroundSecondary)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

struct EditMealView: View {
    let meal: Meal
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Text("Edit meal functionality coming soon")
                .navigationTitle("Edit Meal")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

#Preview {
    let meal = Meal(
        id: UUID(),
        type: .lunch,
        name: "Grilled Chicken Salad",
        description: "Mixed greens with grilled chicken breast",
        calories: 450,
        macros: MacroBreakdown(protein: 35, carbs: 15, fat: 28, fiber: 8, sugar: 5, sodium: 400),
        ingredients: [],
        instructions: [],
        prepTime: 15,
        cookTime: 10,
        servings: 1,
        difficulty: .beginner,
        tags: ["healthy", "protein"],
        imageUrl: nil
    )
    MealDetailView(meal: meal)
    .environmentObject(ThemeProvider())
}
