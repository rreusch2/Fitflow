//
//  NutritionModels.swift
//  Flowmate
//
//  Created on 2025-08-14
//

import Foundation

// MARK: - Core Models

public struct NutritionGoals: Codable {
    public var targetCalories: Int?
    public var targetMacros: Macros?
    public var dietPreferences: [String: AnyCodable]?
    public var exclusions: [String]?
    public var optInDailyAI: Bool
    public var preferredTimeLocal: String? // "HH:mm:ss"
    public var preferredTimezone: String?
}

public struct Macros: Codable, Equatable {
    public var protein: Double?
    public var carbs: Double?
    public var fat: Double?
}

public struct NutritionMealItem: Codable, Identifiable, Equatable {
    public var id: UUID? // optional if custom
    public var name: String
    public var serving: String?
    public var calories: Int
    public var macros: Macros?
}

public enum NutritionMealType: String, Codable, CaseIterable {
    case breakfast, lunch, dinner, snack
}

public struct NutritionMeal: Codable, Identifiable, Equatable {
    public var id: UUID = UUID()
    public var title: String
    public var mealType: NutritionMealType
    public var items: [NutritionMealItem]
    public var totals: NutritionTotals {
        let cals = items.reduce(0) { $0 + $1.calories }
        let p = items.compactMap { $0.macros?.protein }.reduce(0, +)
        let c = items.compactMap { $0.macros?.carbs }.reduce(0, +)
        let f = items.compactMap { $0.macros?.fat }.reduce(0, +)
        return NutritionTotals(calories: cals, protein: p, carbs: c, fat: f)
    }
}

public struct NutritionTotals: Codable, Equatable {
    public var calories: Int
    public var protein: Double
    public var carbs: Double
    public var fat: Double
}

public struct NutritionMealLog: Codable, Identifiable, Equatable {
    public var id: UUID
    public var date: Date
    public var mealType: NutritionMealType
    public var items: [NutritionMealItem]
    public var totals: NutritionTotals
    public var source: String? // manual | ai_suggestion | planned
}

public struct NutritionPlannedMeals: Codable, Equatable {
    public var date: Date
    public var meals: [NutritionMeal]
}

public struct NutritionSummaryDay: Codable, Equatable, Identifiable {
    public var id: Date { day }
    public var day: Date
    public var calories: Int
    public var protein: Double
    public var carbs: Double
    public var fat: Double
}

// MARK: - AnyCodable helper (for JSONB-like dicts)
public struct AnyCodable: Codable {
    public let value: Any
    public init(_ value: Any) { self.value = value }
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let v = try? container.decode(Bool.self) { value = v; return }
        if let v = try? container.decode(Int.self) { value = v; return }
        if let v = try? container.decode(Double.self) { value = v; return }
        if let v = try? container.decode(String.self) { value = v; return }
        if let v = try? container.decode([String: AnyCodable].self) { value = v; return }
        if let v = try? container.decode([AnyCodable].self) { value = v; return }
        value = NSNull()
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let v as Bool: try container.encode(v)
        case let v as Int: try container.encode(v)
        case let v as Double: try container.encode(v)
        case let v as String: try container.encode(v)
        case let v as [String: AnyCodable]: try container.encode(v)
        case let v as [AnyCodable]: try container.encode(v)
        default: try container.encodeNil()
        }
    }
}
