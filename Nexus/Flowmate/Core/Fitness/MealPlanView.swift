//
//  MealPlanView.swift
//  Flowmate
//
//  Created on 2025-01-15
//

import SwiftUI

struct MealPlanView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var aiService = NutritionAIService.shared
    @ObservedObject private var nutritionService = NutritionService.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let plan = aiService.weeklyMealPlan {
                        // Header
                        VStack(spacing: 8) {
                            Text("Your Weekly Meal Plan")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(themeProvider.theme.textPrimary)
                            
                            Text("AI-generated based on your nutrition goals")
                                .font(.system(size: 16))
                                .foregroundColor(themeProvider.theme.textSecondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Meal Plan Days
                        ForEach(Array(plan.meals.enumerated()), id: \.offset) { index, dayMeal in
                            DayMealCard(
                                day: getDayName(index: index),
                                meal: dayMeal
                            )
                            .environmentObject(themeProvider)
                        }
                        
                        // Save to Calendar Button
                        Button {
                            Task {
                                for (index, meal) in plan.meals.enumerated() {
                                    let date = Calendar.current.date(byAdding: .day, value: index, to: Date()) ?? Date()
                                    _ = try? await nutritionService.savePlan(for: date, meals: [meal])
                                }
                                dismiss()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "calendar.badge.plus")
                                Text("Save to Meal Calendar")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color.green, Color.green.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 20)
                        
                    } else {
                        // Loading or empty state
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(1.5)
                            
                            Text("Generating your meal plan...")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(themeProvider.theme.textSecondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 100)
                    }
                }
                .padding(.bottom, 40)
            }
            .background(ThemedBackground().environmentObject(themeProvider))
            .navigationTitle("Weekly Meal Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(themeProvider.theme.accent)
                }
            }
        }
    }
    
    private func getDayName(index: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let date = Calendar.current.date(byAdding: .day, value: index, to: Date()) ?? Date()
        return formatter.string(from: date)
    }
}

struct DayMealCard: View {
    let day: String
    let meal: Meal
    @EnvironmentObject var themeProvider: ThemeProvider
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Day Header
            HStack {
                Text(day)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(themeProvider.theme.textPrimary)
                
                Spacer()
                
                // Calories Badge
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12))
                    Text("\(Int(meal.calories)) cal")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.orange)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.1))
                .clipShape(Capsule())
                
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(themeProvider.theme.textSecondary)
                }
            }
            
            // Meal Summary
            HStack(spacing: 16) {
                MacroIndicator(
                    label: "Protein",
                    value: "\(Int(meal.protein))g",
                    color: .blue
                )
                
                MacroIndicator(
                    label: "Carbs",
                    value: "\(Int(meal.carbs))g",
                    color: .orange
                )
                
                MacroIndicator(
                    label: "Fats",
                    value: "\(Int(meal.fats))g",
                    color: .purple
                )
            }
            
            if isExpanded {
                // Detailed Ingredients
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ingredients")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(themeProvider.theme.textPrimary)
                        .padding(.top, 8)
                    
                    ForEach(meal.ingredients, id: \.id) { ingredient in
                        HStack {
                            Circle()
                                .fill(themeProvider.theme.accent.opacity(0.3))
                                .frame(width: 6, height: 6)
                            
                            Text(ingredient.name)
                                .font(.system(size: 14))
                                .foregroundColor(themeProvider.theme.textPrimary)
                            
                            Spacer()
                            
                            Text("\(Int(ingredient.amount))\(ingredient.unit)")
                                .font(.system(size: 12))
                                .foregroundColor(themeProvider.theme.textSecondary)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeProvider.theme.cardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, 20)
    }
}

struct MacroIndicator: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
