//
//  AddMealView.swift
//  Flowmate
//
//  Add and log meals with food search and macro calculation
//

import SwiftUI

struct AddMealView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @Environment(\.dismiss) private var dismiss
    @StateObject private var nutritionService = NutritionService.shared
    @ObservedObject private var aiService = NutritionAIService.shared
    
    @State private var selectedMealType: MealType = .breakfast
    @State private var mealName = ""
    @State private var searchText = ""
    @State private var selectedFoods: [FoodItem] = []
    @State private var searchResults: [FoodItem] = []
    @State private var isSearching = false
    @State private var showingFoodDetail: FoodItem?
    
    // Modes
    enum AddMode: String, CaseIterable { case build = "Build", ai = "AI", quick = "Quick" }

// Reusable labeled text field for Quick Add
private struct LabeledTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(themeProvider.theme.textSecondary)
            TextField(placeholder, text: $text)
                .keyboardType(keyboard)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}
    @State private var mode: AddMode = .build
    
    // AI mode state
    @State private var aiMeals: [Meal] = []
    @State private var isLoadingAI = false
    
    // Quick mode state
    @State private var quickCalories: String = ""
    @State private var quickProtein: String = ""
    @State private var quickCarbs: String = ""
    @State private var quickFat: String = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Mode Selector
                    modeSelector

                    if mode == .build {
                        // Meal Type Selector
                        mealTypeSelector
                        
                        // Meal Name Input
                        mealNameSection
                        
                        // Food Search
                        foodSearchSection
                        
                        // Selected Foods
                        if !selectedFoods.isEmpty {
                            selectedFoodsSection
                        }
                        
                        // Nutrition Summary
                        if !selectedFoods.isEmpty {
                            nutritionSummarySection
                        }
                    } else if mode == .ai {
                        aiSuggestionsSection
                    } else if mode == .quick {
                        quickAddSection
                    }
                }
                .padding(.bottom, 100)
            }
            .background(ThemedBackground().environmentObject(themeProvider))
            .navigationTitle("Add Meal")
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
                        Task {
                            await saveCurrentMode()
                        }
                    }
                    .foregroundColor(canSave ? themeProvider.theme.accent : themeProvider.theme.textSecondary)
                    .disabled(!canSave)
                }
            }
        }
        .sheet(item: $showingFoodDetail) { food in
            FoodDetailView(food: food) { updatedFood in
                if let index = selectedFoods.firstIndex(where: { $0.id == updatedFood.id }) {
                    selectedFoods[index] = updatedFood
                }
            }
        }
    }
    
    // MARK: - Mode Selector
    private var modeSelector: some View {
        HStack(spacing: 8) {
            ForEach(AddMode.allCases, id: \.self) { m in
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { mode = m }
                    if m == .ai { Task { await loadAISuggestions() } }
                } label: {
                    Text(m.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(mode == m ? .white : themeProvider.theme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(mode == m ? themeProvider.theme.accent : themeProvider.theme.backgroundSecondary)
                        )
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var mealTypeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Meal Type")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(themeProvider.theme.textPrimary)
                .padding(.horizontal, 20)
            
            HStack(spacing: 12) {
                ForEach(MealType.allCases, id: \.self) { type in
                    Button {
                        selectedMealType = type
                    } label: {
                        VStack(spacing: 8) {
                            Text(type.emoji)
                                .font(.system(size: 24))
                            
                            Text(type.displayName)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(selectedMealType == type ? .white : themeProvider.theme.textPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedMealType == type ? type.color : themeProvider.theme.backgroundSecondary)
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var mealNameSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Meal Name (Optional)")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(themeProvider.theme.textPrimary)
                .padding(.horizontal, 20)
            
            TextField("e.g., Grilled Chicken Salad", text: $mealName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal, 20)
        }
    }
    
    private var foodSearchSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Foods")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(themeProvider.theme.textPrimary)
                .padding(.horizontal, 20)
            
            HStack {
                TextField("Search for foods...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        Task {
                            await searchFoods()
                        }
                    }
                
                Button {
                    Task {
                        await searchFoods()
                    }
                } label: {
                    if isSearching {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "magnifyingglass")
                    }
                }
                .foregroundColor(themeProvider.theme.accent)
                .disabled(isSearching || searchText.isEmpty)
            }
            .padding(.horizontal, 20)
            
            if !searchResults.isEmpty {
                Text("Search Results")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeProvider.theme.textPrimary)
                    .padding(.horizontal, 20)
                
                VStack(spacing: 8) {
                    ForEach(searchResults.prefix(5), id: \.id) { food in
                        FoodSearchResultCard(food: food) {
                            addFood(food)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var selectedFoodsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Selected Foods")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(themeProvider.theme.textPrimary)
                
                Spacer()
                
                Text("\(selectedFoods.count) item\(selectedFoods.count == 1 ? "" : "s")")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeProvider.theme.textSecondary)
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 8) {
                ForEach(selectedFoods, id: \.id) { food in
                    SelectedFoodCard(food: food) {
                        showingFoodDetail = food
                    } onRemove: {
                        removeFood(food)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var nutritionSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Nutrition Summary")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(themeProvider.theme.textPrimary)
                .padding(.horizontal, 20)
            
            HStack(spacing: 16) {
                NutritionSummaryCard(
                    title: "Calories",
                    value: totalCalories,
                    unit: "cal",
                    color: .blue
                )
                
                NutritionSummaryCard(
                    title: "Protein",
                    value: totalProtein,
                    unit: "g",
                    color: .red
                )
                
                NutritionSummaryCard(
                    title: "Carbs",
                    value: totalCarbs,
                    unit: "g",
                    color: .orange
                )
                
                NutritionSummaryCard(
                    title: "Fat",
                    value: totalFat,
                    unit: "g",
                    color: .green
                )
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - AI Suggestions
    private var aiSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Meal Suggestions")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(themeProvider.theme.textPrimary)
                .padding(.horizontal, 20)
            
            // Meal Type Selector (limit to 4 types)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach([MealType.breakfast, .lunch, .dinner, .snack], id: \.self) { type in
                        Button {
                            selectedMealType = type
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: type.icon)
                                Text(type.displayName)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(selectedMealType == type ? .white : themeProvider.theme.textPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule().fill(selectedMealType == type ? themeProvider.theme.accent : themeProvider.theme.backgroundSecondary)
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            
            if isLoadingAI {
                HStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.9)
                    Text("Generating suggestions...")
                        .foregroundColor(themeProvider.theme.textSecondary)
                    Spacer()
                }
                .padding(.vertical, 12)
            } else if aiMeals.isEmpty {
                VStack(spacing: 10) {
                    Text("No suggestions yet")
                        .foregroundColor(themeProvider.theme.textSecondary)
                    Button {
                        Task { await loadAISuggestions() }
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Get Today's Suggestions")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .background(RoundedRectangle(cornerRadius: 10).fill(themeProvider.theme.accent))
                    }
                }
                .padding(.horizontal, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(aiMeals.filter { $0.type == selectedMealType }, id: \.id) { meal in
                            VStack(alignment: .leading, spacing: 12) {
                                MealCard(meal: meal, onAddToPlan: {
                                    Task { _ = try? await nutritionService.savePlan(for: Date(), meals: [meal]) }
                                }, onLogNow: {
                                    Task {
                                        _ = try? await nutritionService.logMeal(mealType: meal.type, items: meal.ingredients, source: "ai_suggestion", notes: meal.name)
                                        await MainActor.run { dismiss() }
                                    }
                                })
                            }
                            .environmentObject(themeProvider)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
    
    // MARK: - Quick Add
    private var quickAddSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Add")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(themeProvider.theme.textPrimary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                mealTypeSelector
                mealNameSection
                
                VStack(spacing: 12) {
                    LabeledTextField(label: "Calories", placeholder: "e.g. 450", text: $quickCalories, keyboard: .numberPad)
                    HStack(spacing: 12) {
                        LabeledTextField(label: "Protein (g)", placeholder: "30", text: $quickProtein, keyboard: .numberPad)
                        LabeledTextField(label: "Carbs (g)", placeholder: "45", text: $quickCarbs, keyboard: .numberPad)
                        LabeledTextField(label: "Fat (g)", placeholder: "12", text: $quickFat, keyboard: .numberPad)
                    }
                }
                .padding(.horizontal, 20)
                
                HStack {
                    Spacer()
                    Button {
                        Task { await saveQuickMeal() }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "tray.and.arrow.down.fill")
                            Text("Save Meal")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(RoundedRectangle(cornerRadius: 12).fill(themeProvider.theme.accent))
                    }
                    .disabled(!quickCanSave)
                    Spacer()
                }
                .padding(.top, 6)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var canSave: Bool {
        switch mode {
        case .build: return !selectedFoods.isEmpty
        case .ai: return false // actions are inline per suggestion
        case .quick: return quickCanSave
        }
    }
    
    private var quickCanSave: Bool {
        (Int(quickCalories) ?? 0) > 0
    }
    
    private var totalCalories: Double {
        selectedFoods.reduce(0) { $0 + $1.totalCalories }
    }
    
    private var totalProtein: Double {
        selectedFoods.reduce(0) { $0 + $1.totalProtein }
    }
    
    private var totalCarbs: Double {
        selectedFoods.reduce(0) { $0 + $1.totalCarbs }
    }
    
    private var totalFat: Double {
        selectedFoods.reduce(0) { $0 + $1.totalFat }
    }
    
    // MARK: - Methods
    
    private func searchFoods() async {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        searchResults = await nutritionService.searchFoodItems(query: searchText)
        isSearching = false
    }
    
    private func addFood(_ food: FoodItem) {
        selectedFoods.append(food)
        searchText = ""
        searchResults = []
    }
    
    private func removeFood(_ food: FoodItem) {
        selectedFoods.removeAll { $0.id == food.id }
    }
    
    private func saveCurrentMode() async {
        switch mode {
        case .build:
            let items: [Ingredient] = selectedFoods.map { $0.toIngredient() }
            do {
                _ = try await nutritionService.logMeal(
                    mealType: selectedMealType,
                    items: items,
                    source: "manual",
                    notes: mealName.isEmpty ? nil : mealName
                )
                dismiss()
            } catch {
                print("Error saving meal: \(error)")
            }
        case .ai:
            // Save handled via per-card action (Log Now)
            break
        case .quick:
            await saveQuickMeal()
        }
    }
    
    private func saveQuickMeal() async {
        let calories = Int(quickCalories) ?? 0
        let protein = Int(quickProtein) ?? 0
        let carbs = Int(quickCarbs) ?? 0
        let fat = Int(quickFat) ?? 0
        guard calories > 0 else { return }
        
        let quickIngredient = Ingredient(
            id: UUID(),
            name: mealName.isEmpty ? "Quick Meal" : mealName,
            amount: 1,
            unit: "serving",
            calories: calories,
            macros: MacroBreakdown(protein: protein, carbs: carbs, fat: fat, fiber: 0),
            isOptional: false,
            substitutes: []
        )
        do {
            _ = try await nutritionService.logMeal(
                mealType: selectedMealType,
                items: [quickIngredient],
                source: "manual",
                notes: mealName.isEmpty ? nil : mealName
            )
            dismiss()
        } catch {
            print("Error saving quick meal: \(error)")
        }
    }
    
    private func loadAISuggestions() async {
        guard !isLoadingAI else { return }
        isLoadingAI = true
        defer { isLoadingAI = false }
        do {
            let meals = try await aiService.getDailySuggestions(date: Date(), goals: nutritionService.goals)
            aiMeals = meals
        } catch {
            print("Error loading AI suggestions: \(error)")
        }
    }
}

struct FoodSearchResultCard: View {
    let food: FoodItem
    let onAdd: () -> Void
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(food.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeProvider.theme.textPrimary)
                
                Text("\(Int(food.caloriesPer100g)) cal per 100g")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeProvider.theme.textSecondary)
                
                HStack(spacing: 12) {
                    Text("P: \(Int(food.proteinPer100g))g")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                    Text("C: \(Int(food.carbsPer100g))g")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.orange)
                    Text("F: \(Int(food.fatPer100g))g")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            Button {
                onAdd()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(themeProvider.theme.accent)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(themeProvider.theme.backgroundSecondary)
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
        )
    }
}

struct SelectedFoodCard: View {
    let food: FoodItem
    let onEdit: () -> Void
    let onRemove: () -> Void
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(food.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeProvider.theme.textPrimary)
                
                Text("\(String(format: "%.0f", food.quantity))g • \(Int(food.totalCalories)) cal")
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
            
            HStack(spacing: 8) {
                Button {
                    onEdit()
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 16))
                        .foregroundColor(themeProvider.theme.accent)
                }
                
                Button {
                    onRemove()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(themeProvider.theme.backgroundSecondary)
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
        )
    }
}

struct NutritionSummaryCard: View {
    let title: String
    let value: Double
    let unit: String
    let color: Color
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(themeProvider.theme.textSecondary)
            
            Text("\(Int(value))")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
            
            Text(unit)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(themeProvider.theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

#Preview {
    AddMealView()
        .environmentObject(ThemeProvider())
}
