//
//  WeeklyMealPlanView.swift
//  Flowmate
//
//  Weekly meal plan display with beautiful UI
//

import SwiftUI

struct WeeklyMealPlanView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @Environment(\.dismiss) private var dismiss
    let mealPlan: NutritionAIService.WeeklyMealPlan
    @State private var selectedDay = 0
    @State private var showingShoppingList = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Day Selector
                    daySelector
                    
                    // Selected Day Meals
                    if selectedDay < mealPlan.days.count {
                        dayMealsSection
                    }
                    
                    // Shopping List Preview
                    shoppingListPreview
                    
                    // Prep Notes
                    prepNotesSection
                }
                .padding(.bottom, 100)
            }
            .background(ThemedBackground().environmentObject(themeProvider))
            .navigationTitle("Weekly Meal Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(themeProvider.theme.accent)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingShoppingList = true
                    } label: {
                        Image(systemName: "cart")
                            .foregroundColor(themeProvider.theme.accent)
                    }
                }
            }
        }
        .sheet(isPresented: $showingShoppingList) {
            ShoppingListView(items: mealPlan.shoppingList)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your AI Meal Plan")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(themeProvider.theme.textPrimary)
                    
                    Text("Personalized for your goals")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeProvider.theme.textSecondary)
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("🍽️")
                        .font(.system(size: 32))
                    Text("7 Days")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color.green)
                }
            }
            
            // Quick Stats
            HStack(spacing: 16) {
                StatCard(
                    title: "Days",
                    value: "\(mealPlan.days.count)",
                    color: .blue
                )
                StatCard(
                    title: "Meals",
                    value: "\(mealPlan.days.flatMap { $0.meals }.count)",
                    color: .orange
                )
                StatCard(
                    title: "Prep Time",
                    value: "\(mealPlan.prepNotes.isEmpty ? "30" : "45")m",
                    color: .green
                )
                if let cost = mealPlan.totalCost {
                    StatCard(
                        title: "Est. Cost",
                        value: "$\(Int(cost))",
                        color: .purple
                    )
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var daySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<mealPlan.days.count, id: \.self) { index in
                    Button {
                        selectedDay = index
                    } label: {
                        VStack(spacing: 4) {
                            Text(dayName(for: index))
                                .font(.system(size: 14, weight: .semibold))
                            Text(dayDate(for: index))
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(selectedDay == index ? .white : themeProvider.theme.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedDay == index ? themeProvider.theme.accent : themeProvider.theme.backgroundSecondary)
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var dayMealsSection: some View {
        let dayPlan = mealPlan.days[selectedDay]
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("\(dayName(for: selectedDay))'s Meals")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(themeProvider.theme.textPrimary)
                    .padding(.horizontal, 20)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(dayPlan.dayTotals.protein + dayPlan.dayTotals.carbs + dayPlan.dayTotals.fat * 9)) cal")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(themeProvider.theme.accent)
                    Text("Total")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeProvider.theme.textSecondary)
                }
                .padding(.horizontal, 20)
            }
            
            VStack(spacing: 12) {
                ForEach(dayPlan.meals, id: \.id) { meal in
                    MealPlanCard(meal: meal) {
                        // Add to today's plan
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var shoppingListPreview: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Shopping List")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(themeProvider.theme.textPrimary)
                
                Spacer()
                
                Button {
                    showingShoppingList = true
                } label: {
                    Text("View All")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeProvider.theme.accent)
                }
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(mealPlan.shoppingList.prefix(5).enumerated()), id: \.offset) { _, item in
                        ShoppingItemCard(item: item)
                    }
                    
                    if mealPlan.shoppingList.count > 5 {
                        Button {
                            showingShoppingList = true
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 24))
                                    .foregroundColor(themeProvider.theme.accent)
                                
                                Text("+\(mealPlan.shoppingList.count - 5) more")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(themeProvider.theme.textSecondary)
                            }
                            .frame(width: 100, height: 80)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(themeProvider.theme.accent, lineWidth: 2)
                                    .fill(themeProvider.theme.accent.opacity(0.05))
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var prepNotesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Prep Notes")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeProvider.theme.textPrimary)
                .padding(.horizontal, 20)
            
            Text(mealPlan.prepNotes.isEmpty ? "Follow your meal plan day by day for best results. Prep ingredients in advance when possible." : mealPlan.prepNotes)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(themeProvider.theme.textSecondary)
                .lineLimit(nil)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
        }
    }
    
    // MARK: - Helper Methods
    
    private func dayName(for index: Int) -> String {
        let date = Calendar.current.date(byAdding: .day, value: index, to: mealPlan.startDate) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private func dayDate(for index: Int) -> String {
        let date = Calendar.current.date(byAdding: .day, value: index, to: mealPlan.startDate) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(themeProvider.theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.1))
        )
    }
}

struct MealPlanCard: View {
    let meal: Meal
    let onAddToPlan: () -> Void
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(meal.type.displayName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(meal.type.color)
                        )
                    
                    Spacer()
                    
                    Text("\(meal.calories) cal")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(themeProvider.theme.accent)
                }
                
                Text(meal.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeProvider.theme.textPrimary)
                
                Text(meal.description)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(themeProvider.theme.textSecondary)
                    .lineLimit(2)
                
                HStack(spacing: 16) {
                    MacroTag(label: "P", value: "\(Int(meal.macros.protein))g", color: .red)
                    MacroTag(label: "C", value: "\(Int(meal.macros.carbs))g", color: .orange)
                    MacroTag(label: "F", value: "\(Int(meal.macros.fat))g", color: .green)
                    
                    Spacer()
                    
                    Button {
                        onAddToPlan()
                    } label: {
                        Text("Add")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(themeProvider.theme.accent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .stroke(themeProvider.theme.accent, lineWidth: 1)
                                    .fill(themeProvider.theme.accent.opacity(0.05))
                            )
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeProvider.theme.backgroundSecondary)
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
        )
    }
}

struct MacroTag: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(color.opacity(0.7))
        }
    }
}

struct ShoppingItemCard: View {
    let item: NutritionAIService.WeeklyMealPlan.ShoppingItem
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        VStack(spacing: 8) {
            Text(categoryEmoji(for: item.category))
                .font(.system(size: 24))
            
            Text(item.name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(themeProvider.theme.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            
            Text(item.quantity)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(themeProvider.theme.textSecondary)
            
            if let cost = item.estimatedCost {
                Text(String(format: "$%.2f", cost))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.green)
            }
        }
        .frame(width: 100, height: 100)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeProvider.theme.backgroundSecondary)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
    
    private func categoryEmoji(for category: String) -> String {
        switch category.lowercased() {
        case "produce": return "🥕"
        case "meat": return "🥩"
        case "dairy": return "🥛"
        case "grains": return "🌾"
        case "pantry": return "🥫"
        default: return "🛒"
        }
    }
}

#Preview {
    WeeklyMealPlanView(mealPlan: NutritionAIService.WeeklyMealPlan(
        id: UUID(),
        startDate: Date(),
        days: [],
        shoppingList: [],
        prepNotes: "Sample prep notes",
        totalCost: 85.0
    ))
    .environmentObject(ThemeProvider())
}
