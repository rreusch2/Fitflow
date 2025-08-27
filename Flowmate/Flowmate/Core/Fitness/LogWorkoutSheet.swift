//
//  LogWorkoutSheet.swift
//  Flowmate
//
//  Created on 2025-08-13
//

import SwiftUI

struct LogWorkoutSheet: View {
    @EnvironmentObject var themeProvider: ThemeProvider
    @Environment(\.dismiss) private var dismiss

    // Form state
    @State private var title: String = ""
    @State private var date: Date = Date()
    @State private var durationMinutes: Int = 45
    @State private var selectedMuscleGroups: Set<MuscleGroup> = []
    @State private var notes: String = ""

    // Exercise editor
    @State private var exercises: [ExerciseDraft] = [ExerciseDraft()]

    // Feedback
    @State private var isSaving = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Overview")) {
                    TextField("Workout title (e.g., Push Day)", text: $title)
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    Stepper(value: $durationMinutes, in: 5...240, step: 5) {
                        HStack {
                            Text("Duration")
                            Spacer()
                            Text("\(durationMinutes) min").foregroundColor(.secondary)
                        }
                    }

                    // Muscle groups grid
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(MuscleGroup.allCases, id: \.self) { group in
                                let selected = selectedMuscleGroups.contains(group)
                                Button(action: {
                                    if selected { selectedMuscleGroups.remove(group) } else { selectedMuscleGroups.insert(group) }
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: group.icon)
                                        Text(group.displayName)
                                    }
                                    .font(.system(size: 12, weight: .semibold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule().fill(selected ? themeProvider.theme.accent : themeProvider.theme.backgroundSecondary)
                                    )
                                    .foregroundColor(selected ? .white : themeProvider.theme.textPrimary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(1...4)
                }

                Section(header: Text("Exercises")) {
                    ForEach(exercises.indices, id: \.self) { i in
                        ExerciseEditorRow(draft: $exercises[i]) {
                            exercises.remove(at: i)
                        }
                    }
                    Button {
                        exercises.append(ExerciseDraft())
                    } label: {
                        Label("Add Exercise", systemImage: "plus.circle.fill")
                    }
                }
            }
            .navigationTitle("Log Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: save) {
                        if isSaving { ProgressView() } else { Text("Save") }
                    }
                    .disabled(isSaving || !isValid)
                }
            }
            .alert("Couldn't save workout", isPresented: .constant(error != nil), actions: {
                Button("OK") { error = nil }
            }, message: {
                Text(error ?? "")
            })
        }
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !exercises.isEmpty
    }

    private func save() {
        isSaving = true
        error = nil
        let completed: [CompletedExercise] = exercises.compactMap { ex in
            guard !ex.name.trimmingCharacters(in: .whitespaces).isEmpty, ex.sets > 0, ex.reps > 0 else { return nil }
            return CompletedExercise(
                name: ex.name,
                sets: ex.sets,
                reps: ex.reps,
                weight: ex.weight,
                restTime: TimeInterval(ex.restSeconds),
                completed: false,
                notes: ex.notes.isEmpty ? nil : ex.notes
            )
        }
        let duration = TimeInterval(durationMinutes * 60)
        // Simple calorie estimation to match service heuristic (8 kcal/min for strength)
        let calories = Int((duration / 60.0) * 8.0)
        let session = WorkoutSession(
            id: UUID(),
            title: title,
            date: date,
            duration: duration,
            exercises: completed,
            muscleGroups: Array(selectedMuscleGroups),
            caloriesBurned: calories,
            averageHeartRate: Int.random(in: 125...160),
            notes: notes.isEmpty ? nil : notes
        )
        FitnessProgressService.shared.logWorkout(session)
        HapticFeedback.success()
        isSaving = false
        dismiss()
    }
}

private struct ExerciseEditorRow: View {
    @Binding var draft: ExerciseDraft
    var onDelete: () -> Void
    @EnvironmentObject var themeProvider: ThemeProvider

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("Exercise name", text: $draft.name)
                Button(role: .destructive) { onDelete() } label: {
                    Image(systemName: "trash")
                }
            }
            HStack(spacing: 12) {
                Stepper("Sets: \(draft.sets)", value: $draft.sets, in: 1...10)
                Stepper("Reps: \(draft.reps)", value: $draft.reps, in: 1...50)
            }
            HStack(spacing: 12) {
                TextField("Weight (optional)", value: $draft.weight, format: .number)
                    .keyboardType(.decimalPad)
                Stepper("Rest: \(draft.restSeconds)s", value: $draft.restSeconds, in: 15...600, step: 15)
            }
            TextField("Notes (optional)", text: $draft.notes)
        }
    }
}

private struct ExerciseDraft: Identifiable {
    let id = UUID()
    var name: String = ""
    var sets: Int = 3
    var reps: Int = 10
    var weight: Double? = nil
    var restSeconds: Int = 90
    var notes: String = ""
}

// MARK: - Preview
#Preview {
    LogWorkoutSheet()
        .environmentObject(ThemeProvider())
}
