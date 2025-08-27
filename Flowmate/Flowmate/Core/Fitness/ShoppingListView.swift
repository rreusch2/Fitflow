//
//  ShoppingListView.swift
//  Flowmate
//
//  Shopping list view for weekly meal plans
//

import SwiftUI

struct ShoppingListView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @Environment(\.dismiss) private var dismiss
    let items: [NutritionAIService.WeeklyMealPlan.ShoppingItem]
    
    @State private var checkedItems: Set<UUID> = []
    @State private var selectedCategory = "All"
    
    private var categories: [String] {
        let allCategories = Set(items.map { $0.category })
        return ["All"] + allCategories.sorted()
    }
    
    private var filteredItems: [NutritionAIService.WeeklyMealPlan.ShoppingItem] {
        if selectedCategory == "All" {
            return items
        }
        return items.filter { $0.category == selectedCategory }
    }
    
    private var totalCost: Double {
        items.compactMap { $0.estimatedCost }.reduce(0, +)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with total cost
                headerSection
                
                // Category filter
                categoryFilter
                
                // Shopping list
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredItems, id: \.id) { item in
                            ShoppingItemRow(
                                item: item,
                                isChecked: checkedItems.contains(item.id),
                                onToggle: {
                                    if checkedItems.contains(item.id) {
                                        checkedItems.remove(item.id)
                                    } else {
                                        checkedItems.insert(item.id)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .background(ThemedBackground().environmentObject(themeProvider))
            .navigationTitle("Shopping List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(themeProvider.theme.accent)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // Share shopping list
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(themeProvider.theme.accent)
                    }
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Items")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeProvider.theme.textSecondary)
                    Text("\(items.count)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(themeProvider.theme.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Estimated Cost")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeProvider.theme.textSecondary)
                    Text(String(format: "$%.2f", totalCost))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.green)
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(themeProvider.theme.backgroundSecondary)
                        .frame(height: 4)
                        .clipShape(Capsule())
                    
                    Rectangle()
                        .fill(themeProvider.theme.accent)
                        .frame(width: geometry.size.width * (Double(checkedItems.count) / Double(items.count)), height: 4)
                        .clipShape(Capsule())
                        .animation(.easeInOut(duration: 0.3), value: checkedItems.count)
                }
            }
            .frame(height: 4)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(themeProvider.theme.backgroundPrimary)
    }
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories, id: \.self) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        HStack(spacing: 6) {
                            Text(categoryEmoji(for: category))
                                .font(.system(size: 14))
                            Text(category)
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(selectedCategory == category ? .white : themeProvider.theme.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(selectedCategory == category ? themeProvider.theme.accent : themeProvider.theme.backgroundSecondary)
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 12)
        .background(themeProvider.theme.backgroundPrimary)
    }
    
    private func categoryEmoji(for category: String) -> String {
        switch category.lowercased() {
        case "all": return "🛒"
        case "produce": return "🥕"
        case "meat": return "🥩"
        case "dairy": return "🥛"
        case "grains": return "🌾"
        case "pantry": return "🥫"
        case "beverages": return "🥤"
        case "frozen": return "🧊"
        case "snacks": return "🍿"
        default: return "📦"
        }
    }
}

struct ShoppingItemRow: View {
    let item: NutritionAIService.WeeklyMealPlan.ShoppingItem
    let isChecked: Bool
    let onToggle: () -> Void
    @EnvironmentObject var themeProvider: ThemeProvider
    
    var body: some View {
        HStack(spacing: 16) {
            Button {
                onToggle()
            } label: {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isChecked ? .green : themeProvider.theme.textSecondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isChecked ? themeProvider.theme.textSecondary : themeProvider.theme.textPrimary)
                    .strikethrough(isChecked)
                
                Text(item.quantity)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeProvider.theme.textSecondary)
                
                if let notes = item.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(themeProvider.theme.textSecondary.opacity(0.7))
                        .italic()
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let cost = item.estimatedCost {
                    Text(String(format: "$%.2f", cost))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isChecked ? themeProvider.theme.textSecondary : .green)
                        .strikethrough(isChecked)
                }
                
                Text(categoryEmoji(for: item.category))
                    .font(.system(size: 20))
                    .opacity(isChecked ? 0.5 : 1.0)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isChecked ? themeProvider.theme.backgroundSecondary.opacity(0.5) : themeProvider.theme.backgroundSecondary)
                .shadow(color: Color.black.opacity(isChecked ? 0.02 : 0.05), radius: 4, x: 0, y: 2)
        )
        .opacity(isChecked ? 0.7 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isChecked)
    }
    
    private func categoryEmoji(for category: String) -> String {
        switch category.lowercased() {
        case "produce": return "🥕"
        case "meat": return "🥩"
        case "dairy": return "🥛"
        case "grains": return "🌾"
        case "pantry": return "🥫"
        case "beverages": return "🥤"
        case "frozen": return "🧊"
        case "snacks": return "🍿"
        default: return "📦"
        }
    }
}

#Preview {
    ShoppingListView(items: [
        NutritionAIService.WeeklyMealPlan.ShoppingItem(
            id: UUID(),
            name: "Chicken Breast",
            quantity: "2 lbs",
            category: "Meat",
            estimatedCost: 12.99,
            notes: "Organic preferred"
        ),
        NutritionAIService.WeeklyMealPlan.ShoppingItem(
            id: UUID(),
            name: "Broccoli",
            quantity: "2 heads",
            category: "Produce",
            estimatedCost: 3.99,
            notes: nil
        )
    ])
    .environmentObject(ThemeProvider())
}
