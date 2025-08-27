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
    @State private var personalizedTips: [NutritionAIService.NutritionTip] = []
    @State private var showingWeeklyPlan = false
    @State private var showingDietAnalysis = false
    @State private var showingCalorieTracking = false
    @State private var showingAddMeal = false
    @State private var generatedWeeklyPlan: NutritionAIService.WeeklyMealPlan?
    @State private var dietAnalysis: NutritionAIService.DietAnalysis?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Daily Overview
                    dailyOverview
                    
                    // Quick Actions
                    quickActionsSection
                    
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
                await loadInitialData()
            }
            .sheet(isPresented: $showingWeeklyPlan) {
                if let plan = generatedWeeklyPlan {
                    WeeklyMealPlanView(mealPlan: plan)
                }
            }
            .sheet(isPresented: $showingDietAnalysis) {
                if let analysis = dietAnalysis {
                    DietAnalysisView(analysis: analysis)
                }
            }
            .sheet(isPresented: $showingCalorieTracking) {
                CalorieTrackingView()
            }
            .sheet(isPresented: $showingAddMeal) {
                AddMealView()
            }
        }
    }
    
    // Proxy for older call sites expecting `headerSection`
    private var headerSection: some View { nutritionHeader }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeProvider.theme.textPrimary)
                .padding(.horizontal, 20)
            
            HStack(spacing: 12) {
                QuickActionButton(
                    title: "Add Meal",
                    icon: "plus.circle.fill",
                    color: .green
                ) {
                    showingAddMeal = true
                }
                
                QuickActionButton(
                    title: "Track Calories",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .blue
                ) {
                    showingCalorieTracking = true
                }
            }
            .padding(.horizontal, 20)
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
            Text("Personalized Tips")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(themeProvider.theme.textPrimary)
                .padding(.horizontal, 20)
            
            if aiService.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Generating personalized tips...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeProvider.theme.textSecondary)
                    Spacer()
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(personalizedTips, id: \.id) { tip in
                        NutritionTipView(
                            tip: tip.description,
                            type: tip.type,
                            icon: tip.icon
                        )
                    }
                    
                    if personalizedTips.isEmpty {
                        Button {
                            Task {
                                await loadPersonalizedTips()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "sparkles")
                                Text("Generate Personalized Tips")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(themeProvider.theme.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(themeProvider.theme.accent, lineWidth: 1)
                                    .fill(themeProvider.theme.accent.opacity(0.05))
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
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
                        await generateWeeklyMealPlan()
                    }
                } label: {
                    HStack {
                        if aiService.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        }
                        Image(systemName: "sparkles")
                        Text(aiService.isLoading ? "Generating..." : "Generate Weekly Meal Plan")
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
                .disabled(aiService.isLoading)
                
                Button {
                    Task {
                        await analyzeDiet()
                    }
                } label: {
                    HStack {
                        if aiService.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(themeProvider.theme.accent)
                        }
                        Image(systemName: "chart.bar.doc.horizontal")
                        Text(aiService.isLoading ? "Analyzing..." : "Analyze My Current Diet")
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
                .disabled(aiService.isLoading)
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
    
    // MARK: - Data Loading Methods
    
    private func loadInitialData() async {
        await nutritionService.loadUserData()
        
        // Load AI suggestions for today
        do {
            let meals = try await aiService.getDailySuggestions(date: Date(), goals: nutritionService.goals)
            todaysMeals = meals
        } catch {
            print("Error loading daily suggestions: \(error)")
        }
        
        // Load personalized tips
        await loadPersonalizedTips()
    }
    
    private func loadPersonalizedTips() async {
        do {
            personalizedTips = try await aiService.getPersonalizedTips()
        } catch {
            print("Error loading personalized tips: \(error)")
            aiService.errorMessage = error.localizedDescription
        }
    }
    
    private func generateWeeklyMealPlan() async {
        guard let goals = nutritionService.goals else {
            aiService.errorMessage = "Please set your nutrition goals first"
            return
        }
        
        let preferences = MealPlanPreferences(
            targetCalories: goals.targetCalories,
            dietType: goals.dietPreferences?.dietType,
            allergies: goals.dietPreferences?.allergies ?? [],
            dislikes: goals.dietPreferences?.dislikes ?? [],
            cuisinePreferences: goals.dietPreferences?.cuisinePreferences ?? [],
            mealCount: 4, // 3 meals + 1 snack
            prepTimePreference: 30
        )
        
        do {
            generatedWeeklyPlan = try await aiService.generateWeeklyMealPlan(preferences: preferences)
            showingWeeklyPlan = true
        } catch {
            print("Error generating weekly meal plan: \(error)")
            aiService.errorMessage = error.localizedDescription
        }
    }
    
    private func analyzeDiet() async {
        do {
            dietAnalysis = try await aiService.analyzeDiet(days: 7)
            showingDietAnalysis = true
        } catch {
            print("Error analyzing diet: \(error)")
            aiService.errorMessage = error.localizedDescription
        }
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

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [color, color.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
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

struct NutritionTipView: View {
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
