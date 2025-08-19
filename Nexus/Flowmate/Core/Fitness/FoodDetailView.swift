//
//  FoodDetailView.swift
//  Flowmate
//
//  Detail view for editing food quantity and viewing nutrition info
//

import SwiftUI

struct FoodDetailView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @Environment(\.dismiss) private var dismiss
    
    @State private var food: FoodItem
    let onSave: (FoodItem) -> Void
    
    init(food: FoodItem, onSave: @escaping (FoodItem) -> Void) {
        self._food = State(initialValue: food)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Food header
                    foodHeaderSection
                    
                    // Quantity adjustment
                    quantitySection
                    
                    // Nutrition breakdown
                    nutritionSection
                    
                    // Per 100g reference
                    referenceSection
                }
                .padding(.bottom, 100)
            }
            .background(ThemedBackground().environmentObject(themeProvider))
            .navigationTitle("Food Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(themeProvider.theme.accent)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(food)
                        dismiss()
                    }
                    .foregroundColor(themeProvider.theme.accent)
                }
            }
        }
    }
    
    private var foodHeaderSection: some View {
        VStack(spacing: 16) {
            Text(food.name)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(themeProvider.theme.textPrimary)
                .multilineTextAlignment(.center)
            
            if let brand = food.brand {
                Text(brand)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeProvider.theme.textSecondary)
            }
            
            Text("\(Int(food.totalCalories)) calories")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeProvider.theme.accent)
        }
        .padding(.horizontal, 20)
    }
    
    private var quantitySection: some View {
        VStack(spacing: 16) {
            Text("Quantity")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeProvider.theme.textPrimary)
            
            HStack(spacing: 20) {
                Button {
                    if food.quantity > 10 {
                        food.quantity -= 10
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(themeProvider.theme.accent)
                }
                .disabled(food.quantity <= 10)
                
                VStack(spacing: 8) {
                    Text("\(food.quantity, specifier: "%.0f")g")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(themeProvider.theme.textPrimary)
                    
                    Slider(value: $food.quantity, in: 5...500, step: 5)
                        .accentColor(themeProvider.theme.accent)
                        .frame(width: 120)
                }
                
                Button {
                    if food.quantity < 500 {
                        food.quantity += 10
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(themeProvider.theme.accent)
                }
                .disabled(food.quantity >= 500)
            }
            
            // Quick quantity buttons
            HStack(spacing: 12) {
                ForEach([50, 100, 150, 200], id: \.self) { quantity in
                    Button {
                        food.quantity = Double(quantity)
                    } label: {
                        Text("\(quantity)g")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(food.quantity == Double(quantity) ? .white : themeProvider.theme.accent)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(food.quantity == Double(quantity) ? themeProvider.theme.accent : themeProvider.theme.accent.opacity(0.1))
                                    .stroke(themeProvider.theme.accent, lineWidth: 1)
                            )
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var nutritionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Nutrition Facts")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeProvider.theme.textPrimary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                NutritionFactRow(
                    label: "Calories",
                    value: "\(Int(food.totalCalories))",
                    unit: "cal",
                    color: .blue
                )
                
                NutritionFactRow(
                    label: "Protein",
                    value: "\(food.totalProtein, specifier: "%.1f")",
                    unit: "g",
                    color: .red
                )
                
                NutritionFactRow(
                    label: "Carbohydrates",
                    value: "\(food.totalCarbs, specifier: "%.1f")",
                    unit: "g",
                    color: .orange
                )
                
                NutritionFactRow(
                    label: "Fat",
                    value: "\(food.totalFat, specifier: "%.1f")",
                    unit: "g",
                    color: .green
                )
                
                if food.fiberPer100g > 0 {
                    NutritionFactRow(
                        label: "Fiber",
                        value: "\((food.fiberPer100g * food.quantity / 100), specifier: "%.1f")",
                        unit: "g",
                        color: .brown
                    )
                }
                
                if food.sugarPer100g > 0 {
                    NutritionFactRow(
                        label: "Sugar",
                        value: "\((food.sugarPer100g * food.quantity / 100), specifier: "%.1f")",
                        unit: "g",
                        color: .pink
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var referenceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Per 100g Reference")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeProvider.theme.textPrimary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 8) {
                ReferenceRow(label: "Calories", value: "\(Int(food.caloriesPer100g)) cal")
                ReferenceRow(label: "Protein", value: "\(food.proteinPer100g, specifier: "%.1f")g")
                ReferenceRow(label: "Carbs", value: "\(food.carbsPer100g, specifier: "%.1f")g")
                ReferenceRow(label: "Fat", value: "\(food.fatPer100g, specifier: "%.1f")g")
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeProvider.theme.backgroundSecondary.opacity(0.5))
                    .stroke(themeProvider.theme.textSecondary.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal, 20)
        }
    }
}

struct NutritionFactRow: View {
    let label: String
    let value: String
    let unit: String
    let color: Color
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
                
                Text(label)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeProvider.theme.textPrimary)
            }
            
            Spacer()
            
            Text("\(value) \(unit)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.05))
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

struct ReferenceRow: View {
    let label: String
    let value: String
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(themeProvider.theme.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(themeProvider.theme.textPrimary)
        }
    }
}

#Preview {
    FoodDetailView(
        food: FoodItem(
            id: UUID(),
            name: "Chicken Breast",
            brand: "Organic Valley",
            serving: "100g",
            calories: 165,
            macros: MacroBreakdown(protein: 31, carbs: 0, fat: 3.6, fiber: 0, sugar: 0, sodium: 70),
            tags: ["protein", "meat"],
            isPublic: true,
            source: "nutrition-database"
        )
    ) { _ in }
    .environmentObject(ThemeProvider())
}
