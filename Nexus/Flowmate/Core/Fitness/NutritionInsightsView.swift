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
    @State private var selectedMealType: MealType = .breakfast
    @State private var todaysMeals: [Meal] = []
    @State private var isGeneratingMeals = false
    @State private var isGeneratingPlan = false
    @State private var isAnalyzingDiet = false
    @State private var showMealPlan = false
    @State private var showDietAnalysis = false
    
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
                // Load today summary
                _ = try? await nutritionService.getSummary(start: Date(), end: Date())
                // Load AI suggestions for today
                let meals = (try? await aiService.getDailySuggestions(date: Date(), goals: nutritionService.goals)) ?? []
                todaysMeals = meals
                // Generate personalized tips
                _ = try? await aiService.generatePersonalizedTips(
                    summary: nutritionService.todaySummary,
                    goals: nutritionService.goals
                )
            }
            .sheet(isPresented: $showMealPlan) {
                MealPlanView()
                    .environmentObject(themeProvider)
            }
            .sheet(isPresented: $showDietAnalysis) {
                DietAnalysisView()
                    .environmentObject(themeProvider)
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
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                let s = nutritionService.todaySummary
                let g = nutritionService.goals
                NutritionCard(
                    title: "Calories",
                    current: s != nil ? String(Int(s!.calories)) : "—",
                    target: g?.targetCalories != nil ? String(g!.targetCalories!) : "—",
                    progress: progress(current: s?.calories as Double?, target: g?.targetCalories as Int?),
                    color: Color.blue
                )
                NutritionCard(
                    title: "Protein",
                    current: s != nil ? "\(Int(s!.protein))g" : "—",
                    target: g?.targetMacros?.protein != nil ? "\(Int(g!.targetMacros!.protein!))g" : "—",
                    progress: progress(current: s?.protein as Double?, target: g?.targetMacros?.protein as Double?),
                    color: Color.red
                )
                NutritionCard(
                    title: "Carbs",
                    current: s != nil ? "\(Int(s!.carbs))g" : "—",
                    target: g?.targetMacros?.carbs != nil ? "\(Int(g!.targetMacros!.carbs!))g" : "—",
                    progress: progress(current: s?.carbs as Double?, target: g?.targetMacros?.carbs as Double?),
                    color: Color.orange
                )
                NutritionCard(
                    title: "Fat",
                    current: s != nil ? "\(Int(s!.fat))g" : "—",
                    target: g?.targetMacros?.fat != nil ? "\(Int(g!.targetMacros!.fat!))g" : "—",
                    progress: progress(current: s?.fat as Double?, target: g?.targetMacros?.fat as Double?),
                    color: Color.green
                )
            }
            .padding(.horizontal, 20)
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
                    }
                }
                .padding(.horizontal, 20)
            }
            
            // Meal Cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(filteredMeals(for: selectedMealType), id: \.id) { meal in
                        MealCard(meal: meal) {
                            Task { _ = try? await nutritionService.savePlan(for: Date(), meals: [meal]) }
                        } onLogNow: {
                            Task { _ = try? await nutritionService.logMeal(mealType: meal.type, items: meal.ingredients, source: "ai_suggestion") }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var nutritionTips: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Personalized Tips")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(themeProvider.theme.textPrimary)
                
                Spacer()
                
                if aiService.personalizedTips.isEmpty {
                    Button {
                        Task {
                            _ = try? await aiService.generatePersonalizedTips(
                                summary: nutritionService.todaySummary,
                                goals: nutritionService.goals
                            )
                        }
                    } label: {
                        Label("Generate", systemImage: "sparkles")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(themeProvider.theme.accent)
                    }
                }
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                if aiService.personalizedTips.isEmpty {
                    // Default tips while loading
                    NutritionTip(
                        tip: "Track your meals consistently for better insights into your nutrition.",
                        type: .tip,
                        icon: "pencil.circle"
                    )
                    
                    NutritionTip(
                        tip: "Focus on whole foods and minimize processed items for optimal health.",
                        type: .tip,
                        icon: "leaf.fill"
                    )
                    
                    NutritionTip(
                        tip: "Stay hydrated throughout the day for better energy and focus.",
                        type: .tip,
                        icon: "drop.fill"
                    )
                } else {
                    // AI-generated tips
                    ForEach(aiService.personalizedTips, id: \.id) { tip in
                        NutritionTip(
                            tip: tip.text,
                            type: mapTipType(tip.type),
                            icon: tip.icon
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func mapTipType(_ type: NutritionAIService.NutritionTip.TipType) -> InsightType {
        switch type {
        case .suggestion: return .suggestion
        case .positive: return .positive
        case .warning: return .warning
        case .tip: return .tip
        }
    }
    
    private var aiMealPlanner: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Meal Planner")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeProvider.theme.textPrimary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                // Generate Weekly Meal Plan Button
                Button {
                    Task {
                        isGeneratingPlan = true
                        do {
                            let plan = try await aiService.generateWeeklyMealPlan(goals: nutritionService.goals)
                            showMealPlan = true
                            // Save the plan to database
                            if let firstDay = plan.meals.first {
                                _ = try? await nutritionService.savePlan(for: Date(), meals: [firstDay])
                            }
                        } catch {
                            print("Failed to generate meal plan: \(error)")
                        }
                        isGeneratingPlan = false
                    }
                } label: {
                    HStack {
                        if isGeneratingPlan {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "sparkles")
                        }
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
                .disabled(isGeneratingPlan)
                
                // Analyze Diet Button
                Button {
                    Task {
                        isAnalyzingDiet = true
                        do {
                            // Get recent meals for analysis
                            let recentMeals = nutritionService.recentMeals.isEmpty ? todaysMeals : nutritionService.recentMeals
                            let analysis = try await aiService.analyzeDiet(
                                recentMeals: recentMeals,
                                goals: nutritionService.goals
                            )
                            showDietAnalysis = true
                        } catch {
                            print("Failed to analyze diet: \(error)")
                        }
                        isAnalyzingDiet = false
                    }
                } label: {
                    HStack {
                        if isAnalyzingDiet {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: themeProvider.theme.accent))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "chart.bar.doc.horizontal")
                        }
                        Text("Analyze My Current Diet")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(themeProvider.theme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(themeProvider.theme.accent, lineWidth: 2)
                    )
                }
                .disabled(isAnalyzingDiet)
                
                // Generate Daily Suggestions Button
                Button {
                    Task {
                        isGeneratingMeals = true
                        do {
                            let meals = try await aiService.getDailySuggestions(
                                date: Date(),
                                goals: nutritionService.goals
                            )
                            todaysMeals = meals
                        } catch {
                            print("Failed to generate meal suggestions: \(error)")
                        }
                        isGeneratingMeals = false
                    }
                } label: {
                    HStack {
                        if isGeneratingMeals {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: themeProvider.theme.accent))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "wand.and.stars")
                        }
                        Text("Generate Today's Meal Suggestions")
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
                .disabled(isGeneratingMeals)
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Helpers
    private func filteredMeals(for type: MealType) -> [Meal] {
        todaysMeals.filter { $0.type == type }
    }
    
    private func progress(current: Double?, target: Int?) -> Double {
        guard let current = current, let target = target, target > 0 else { return 0 }
        return min(max(current / Double(target), 0), 1)
    }
    private func progress(current: Double?, target: Double?) -> Double {
        guard let current = current, let target = target, target > 0 else { return 0 }
        return min(max(current / target, 0), 1)
    }
}

// MARK: - MealType UI helpers (use built-in on MealType in models)

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

// Helper for macro totals used by MealCard
private struct NutritionTotals {
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
}

struct MealCard: View {
    let meal: Meal
    var onAddToPlan: () -> Void
    var onLogNow: () -> Void
    @EnvironmentObject var themeProvider: ThemeProvider
    
    private var totals: NutritionTotals {
        let calories = meal.ingredients.reduce(0) { $0 + $1.calories }
        let p = meal.ingredients.map { $0.macros.protein }.reduce(0, +)
        let c = meal.ingredients.map { $0.macros.carbs }.reduce(0, +)
        let f = meal.ingredients.map { $0.macros.fat }.reduce(0, +)
        return NutritionTotals(calories: calories, protein: p, carbs: c, fat: f)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(meal.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeProvider.theme.textPrimary)
                
                if let first = meal.ingredients.first {
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
