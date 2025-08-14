//
//  NutritionInsightsView.swift
//  Flowmate
//
//  Created on 2025-01-13
//

import SwiftUI

struct NutritionInsightsView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var nutritionService = NutritionService.shared
    @ObservedObject private var aiService = NutritionAIService.shared
    @State private var selectedMealType: NutritionMealType = .breakfast
    @State private var todaysMeals: [NutritionMeal] = []
    // Predefine grid columns to aid SwiftUI type inference
    private let overviewColumns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    nutritionHeader
                    
                    // Daily Overview
                    dailyOverview
                    
                    // Meal Suggestions
                    mealSuggestions
                    
                    // Nutrition Tips
                    nutritionTips
                    
                    // AI Meal Planner
                    aiMealPlanner
                }
                .padding(.bottom, 100)
            }
            .background(ThemedBackground().environmentObject(themeProvider))
            .navigationTitle("Nutrition AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(themeProvider.theme.accent)
                }
            }
            .task {
                await nutritionService.fetchGoals()
                // Load today summary if backend wired later
                _ = try? await nutritionService.getSummary(start: Date(), end: Date())
                // Load AI suggestions for today
                let meals = (try? await aiService.getDailySuggestions(date: Date(), goals: nutritionService.goals)) ?? []
                todaysMeals = meals
            }
        }
    }
    
    private var nutritionHeader: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nutrition Insights")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(themeProvider.theme.textPrimary)
                    
                    Text("AI-powered meal optimization")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeProvider.theme.textSecondary)
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("🥗")
                        .font(.system(size: 32))
                    Text("Healthy")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color.green)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var dailyOverview: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Overview")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeProvider.theme.textPrimary)
                .padding(.horizontal, 20)
            overviewGrid
        }
    }

    private var overviewGrid: some View {
        LazyVGrid(columns: overviewColumns, spacing: 12) {
            NutritionCard(
                title: "Calories",
                current: nutritionService.todaySummary != nil ? String(Int(nutritionService.todaySummary!.calories)) : "—",
                target: nutritionService.goals?.targetCalories != nil ? String(nutritionService.goals!.targetCalories!) : "—",
                progress: progress(current: nutritionService.todaySummary?.calories as Double?, target: (nutritionService.goals?.targetCalories).map(Double.init)),
                color: Color.blue
            )
            NutritionCard(
                title: "Protein",
                current: nutritionService.todaySummary != nil ? "\(Int(nutritionService.todaySummary!.protein))g" : "—",
                target: nutritionService.goals?.targetMacros?.protein != nil ? "\(Int(nutritionService.goals!.targetMacros!.protein!))g" : "—",
                progress: progress(current: nutritionService.todaySummary?.protein as Double?, target: nutritionService.goals?.targetMacros?.protein as Double?),
                color: Color.red
            )
            NutritionCard(
                title: "Carbs",
                current: nutritionService.todaySummary != nil ? "\(Int(nutritionService.todaySummary!.carbs))g" : "—",
                target: nutritionService.goals?.targetMacros?.carbs != nil ? "\(Int(nutritionService.goals!.targetMacros!.carbs!))g" : "—",
                progress: progress(current: nutritionService.todaySummary?.carbs as Double?, target: nutritionService.goals?.targetMacros?.carbs as Double?),
                color: Color.orange
            )
            NutritionCard(
                title: "Fat",
                current: nutritionService.todaySummary != nil ? "\(Int(nutritionService.todaySummary!.fat))g" : "—",
                target: nutritionService.goals?.targetMacros?.fat != nil ? "\(Int(nutritionService.goals!.targetMacros!.fat!))g" : "—",
                progress: progress(current: nutritionService.todaySummary?.fat as Double?, target: nutritionService.goals?.targetMacros?.fat as Double?),
                color: Color.green
            )
        }
    }
    
    private var mealSuggestions: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Meal Suggestions")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeProvider.theme.textPrimary)
                .padding(.horizontal, 20)
            
            // Meal Type Selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Limit to the four types supported by models
                    ForEach([NutritionMealType.breakfast, .lunch, .dinner, .snack], id: \.self) { mealType in
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
                    }
                }
                .padding(.horizontal, 20)
            }
            
            // Meal Cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(filteredMeals(for: selectedMealType), id: \.title) { meal in
                        MealCard(meal: meal) {
                            Task { _ = try? await nutritionService.savePlan(for: Date(), meals: [meal]) }
                        } onLogNow: {
                            Task { _ = try? await nutritionService.logMeal(mealType: meal.mealType, items: meal.items, source: "ai_suggestion") }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var nutritionTips: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Personalized Tips")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeProvider.theme.textPrimary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                NutritionTip(
                    tip: "Add 20g more protein to reach your daily goal. Try Greek yogurt or a protein shake.",
                    type: .suggestion,
                    icon: "target"
                )
                
                NutritionTip(
                    tip: "Great job staying hydrated! You're 85% to your water goal.",
                    type: .positive,
                    icon: "drop.fill"
                )
                
                NutritionTip(
                    tip: "Consider timing your carbs around workouts for better performance.",
                    type: .tip,
                    icon: "clock.fill"
                )
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var aiMealPlanner: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Meal Planner")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeProvider.theme.textPrimary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                Button {
                    Task {
                        let meals = (try? await aiService.getDailySuggestions(date: Date(), goals: nutritionService.goals)) ?? []
                        todaysMeals = meals
                    }
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Generate Weekly Meal Plan")
                            .font(.system(size: 16, weight: .semibold))
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
                
                Button {
                    // Placeholder for analysis flow
                } label: {
                    HStack {
                        Image(systemName: "chart.bar.doc.horizontal")
                        Text("Analyze My Current Diet")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(themeProvider.theme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(themeProvider.theme.accent, lineWidth: 2)
                            .fill(themeProvider.theme.accent.opacity(0.05))
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Helpers
    private func filteredMeals(for type: NutritionMealType) -> [NutritionMeal] {
        todaysMeals.filter { $0.mealType == type }
    }
    
    private func progress(current: Double?, target: Double?) -> Double {
        guard let current = current, let target = target, target > 0 else { return 0 }
        return min(max(current / target, 0), 1)
    }
}

// MARK: - MealType UI helpers
private extension NutritionMealType {
    var displayName: String {
        switch self {
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .snack: return "Snack"
        }
    }
    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "fork.knife"
        case .dinner: return "moon.stars.fill"
        case .snack: return "takeoutbag.and.cup.and.straw.fill"
        }
    }
}

// Removed MealSuggestion in favor of real Meal from models

struct NutritionCard: View {
    let title: String
    let current: String
    let target: String
    let progress: Double
    let color: Color
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeProvider.theme.textPrimary)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(current)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(color)
                
                Text("of \(target)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(themeProvider.theme.textSecondary)
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.2))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * progress, height: 6)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                }
            }
            .frame(height: 6)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeProvider.theme.backgroundSecondary)
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
        )
    }
}

struct MealCard: View {
    let meal: NutritionMeal
    var onAddToPlan: () -> Void
    var onLogNow: () -> Void
    @EnvironmentObject var themeProvider: ThemeProvider
    
    private var totals: NutritionTotals {
        let calories = meal.items.reduce(0) { $0 + $1.calories }
        let p = meal.items.compactMap { $0.macros?.protein }.reduce(0, +)
        let c = meal.items.compactMap { $0.macros?.carbs }.reduce(0, +)
        let f = meal.items.compactMap { $0.macros?.fat }.reduce(0, +)
        return NutritionTotals(calories: calories, protein: p, carbs: c, fat: f)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(meal.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeProvider.theme.textPrimary)
                
                if let first = meal.items.first {
                    Text(first.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeProvider.theme.textSecondary)
                        .lineLimit(2)
                }
            }
            
            VStack(spacing: 8) {
                HStack {
                    MacroItem(label: "Cal", value: "\(totals.calories)")
                    MacroItem(label: "P", value: "\(Int(totals.protein))g")
                    MacroItem(label: "C", value: "\(Int(totals.carbs))g")
                    MacroItem(label: "F", value: "\(Int(totals.fat))g")
                }
                
                Button {
                    onAddToPlan()
                } label: {
                    Text("Add to Plan")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(themeProvider.theme.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(themeProvider.theme.accent, lineWidth: 1)
                                .fill(themeProvider.theme.accent.opacity(0.05))
                        )
                }
                Button {
                    onLogNow()
                } label: {
                    Text("Log Now")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(themeProvider.theme.accent)
                        )
                }
            }
        }
        .padding(16)
        .frame(width: 200)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeProvider.theme.backgroundSecondary)
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
        )
    }
}

struct MacroItem: View {
    let label: String
    let value: String
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(themeProvider.theme.textPrimary)
            
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(themeProvider.theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct NutritionTip: View {
    let tip: String
    let type: InsightType
    let icon: String
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(type.color)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(type.color.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(type.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(type.color)
                
                Text(tip)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeProvider.theme.textPrimary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeProvider.theme.backgroundSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(type.color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    NutritionInsightsView()
        .environmentObject(ThemeProvider())
}
