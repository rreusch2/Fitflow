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
    
    @State private var selectedMealType: MealType = .breakfast
    @State private var mealName = ""
    @State private var searchText = ""
    @State private var selectedFoods: [FoodItem] = []
    @State private var searchResults: [FoodItem] = []
    @State private var isSearching = false
    @State private var showingFoodDetail: FoodItem?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
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
                            await saveMeal()
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
    
    // MARK: - Computed Properties
    
    private var canSave: Bool {
        !selectedFoods.isEmpty
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
        do {
            searchResults = try await nutritionService.searchFoodItems(query: searchText)
        } catch {
            print("Error searching foods: \(error)")
        }
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
    
    private func saveMeal() async {
        let meal = Meal(
            id: UUID(),
            name: mealName.isEmpty ? selectedMealType.displayName : mealName,
            type: selectedMealType,
            calories: Int(totalCalories),
            macros: Macros(
                protein: totalProtein,
                carbs: totalCarbs,
                fat: totalFat
            ),
            foods: selectedFoods,
            timestamp: Date(),
            description: selectedFoods.map { $0.name }.joined(separator: ", ")
        )
        
        do {
            try await nutritionService.logMeal(meal)
            dismiss()
        } catch {
            print("Error saving meal: \(error)")
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
                
                Text("\(food.quantity, specifier: "%.0f")g • \(Int(food.totalCalories)) cal")
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
