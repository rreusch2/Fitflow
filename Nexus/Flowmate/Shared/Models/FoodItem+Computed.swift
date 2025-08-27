//
//  FoodItem+Computed.swift
//  Flowmate
//
//  Adds convenience computed properties and mapping helpers for FoodItem used by fitness views.
//

import Foundation

extension FoodItem {
    // Quantity in grams used by UI (backed by servingSize)
    var quantity: Double { servingSize }
    
    // Per 100g values (FoodItem already stores per-100g reference)
    var caloriesPer100g: Double { Double(calories) }
    var proteinPer100g: Double { Double(macros.protein) }
    var carbsPer100g: Double { Double(macros.carbs) }
    var fatPer100g: Double { Double(macros.fat) }
    
    // Totals based on current quantity (servingSize)
    var totalCalories: Double { Double(calories) * servingSize / 100.0 }
    var totalProtein: Double { Double(macros.protein) * servingSize / 100.0 }
    var totalCarbs: Double { Double(macros.carbs) * servingSize / 100.0 }
    var totalFat: Double { Double(macros.fat) * servingSize / 100.0 }
    
    // Map to Ingredient for meal logging
    func toIngredient() -> Ingredient {
        Ingredient(
            id: id,
            name: name,
            amount: servingSize,
            unit: "g",
            calories: Int(totalCalories.rounded()),
            macros: MacroBreakdown(
                protein: Int(totalProtein.rounded()),
                carbs: Int(totalCarbs.rounded()),
                fat: Int(totalFat.rounded()),
                fiber: macros.fiber
            ),
            isOptional: false,
            substitutes: []
        )
    }

    // Return a copy with updated serving size (used by FoodDetailView)
    func withServingSize(_ grams: Double) -> FoodItem {
        FoodItem(
            id: id,
            name: name,
            brand: brand,
            calories: calories,
            macros: macros,
            micronutrients: micronutrients,
            servingSize: grams,
            servingSizeUnit: servingSizeUnit,
            barcode: barcode,
            verified: verified,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
