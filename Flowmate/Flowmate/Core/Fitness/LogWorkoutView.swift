//
//  LogWorkoutView.swift
//  Flowmate
//
//  Created on 2025-09-10
//

import SwiftUI

struct LogWorkoutView: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = "Manual Workout"
    @State private var durationMinutes: Int = 45
    @State private var selectedGroups: Set<MuscleGroup> = []
    @State private var notes: String = ""
    @State private var isSaving = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Details")) {
                    TextField("Title", text: $title)
                    Stepper(value: $durationMinutes, in: 5...180, step: 5) {
                        HStack {
                            Image(systemName: "clock.fill").foregroundColor(themeProvider.theme.accent)
                            Text("Duration: \(durationMinutes) min")
                        }
                    }
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(1...4)
                }
                
                Section(header: Text("Muscle Groups")) {
                    FlowLayout(items: MuscleGroup.allCases, spacing: 8) { group in
                        let isSelected = selectedGroups.contains(group)
                        Button {
                            if isSelected { selectedGroups.remove(group) } else { selectedGroups.insert(group) }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: group.icon)
                                Text(group.displayName)
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(isSelected ? themeProvider.theme.accent : themeProvider.theme.backgroundSecondary)
                            )
                            .foregroundColor(isSelected ? .white : themeProvider.theme.textPrimary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Log Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(themeProvider.theme.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: save) {
                        if isSaving { ProgressView().tint(themeProvider.theme.accent) } else { Text("Save") }
                    }
                    .disabled(isSaving || title.trimmingCharacters(in: .whitespaces).isEmpty)
                    .foregroundColor(themeProvider.theme.accent)
                }
            }
            .background(ThemedBackground().environmentObject(themeProvider))
        }
    }
    
    private func save() {
        guard !isSaving else { return }
        isSaving = true
        let duration = TimeInterval(durationMinutes * 60)
        let exercises: [CompletedExercise] = []
        FitnessProgressService.shared.completeWorkout(
            title: title,
            duration: duration,
            exercises: exercises,
            muscleGroups: Array(selectedGroups)
        )
        HapticFeedback.success()
        isSaving = false
        dismiss()
    }
}

// Simple flow layout for chips
struct FlowLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let items: Data
    let spacing: CGFloat
    let content: (Data.Element) -> Content
    
    init(items: Data, spacing: CGFloat = 8, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.items = items
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        return GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                ForEach(Array(items), id: \.self) { item in
                    content(item)
                        .padding(.trailing, spacing)
                        .padding(.bottom, spacing)
                        .alignmentGuide(.leading, computeValue: { d in
                            if abs(width - d.width) > geometry.size.width {
                                width = 0
                                height -= d.height
                            }
                            let result = width
                            if item == items.last { width = 0 } else { width -= d.width }
                            return result
                        })
                        .alignmentGuide(.top, computeValue: { _ in
                            let result = height
                            if item == items.last { height = 0 }
                            return result
                        })
                }
            }
        }
        .frame(minHeight: 44)
    }
}

#Preview {
    LogWorkoutView()
        .environmentObject(ThemeProvider())
}
