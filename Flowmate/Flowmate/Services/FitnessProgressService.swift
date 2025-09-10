//
//  FitnessProgressService.swift
//  Flowmate
//
//  Created on 2025-01-13
//

import Foundation
import SwiftUI

class FitnessProgressService: ObservableObject {
    static let shared = FitnessProgressService()
    
    @Published var workoutHistory: [WorkoutSession] = []
    @Published var achievements: [FitnessAchievement] = []
    
    // Simple achievement status flags
    @Published var hasFirstWorkout = false
    @Published var hasWeekWarrior = false
    @Published var hasConsistencyKing = false
    @Published var streakCount: Int = 0
    @Published var weeklyStats: WeeklyStats = WeeklyStats()
    
    @MainActor
    private var authService: AuthenticationService {
        AuthenticationService.shared
    }
    private let databaseService = DatabaseService.shared
    
    private init() {
        Task { @MainActor in
            await loadFromBackend()
            setupInitialAchievements()
        }
    }
    
    // MARK: - Workout Logging
    
    func logWorkout(_ session: WorkoutSession) {
        workoutHistory.append(session)
        updateStreak()
        updateWeeklyStats()
        checkForNewAchievements(session)
        Task { await persistProgressAsync() }
    }
    
    // Log an AI-generated plan by mapping to a WorkoutSession
    func logAIWorkout(_ plan: AIWorkoutPlan) {
        let completedExercises: [CompletedExercise] = plan.exercises.map { ex in
            CompletedExercise(
                name: ex.name,
                sets: ex.sets,
                reps: Self.parseFirstInt(from: ex.reps) ?? 10,
                weight: nil,
                restTime: Self.parseRestTime(ex.rest),
                completed: false,
                notes: ex.notes.isEmpty ? nil : ex.notes
            )
        }
        let durationMinutes: Int = Self.durationMinutes(from: plan.duration)
        let durationSec: TimeInterval = TimeInterval(durationMinutes * 60)
        let calories = estimateCalories(duration: durationSec, exercises: completedExercises)
        let session = WorkoutSession(
            id: UUID(),
            title: "AI: \(plan.title)",
            date: Date(),
            duration: durationSec,
            exercises: completedExercises,
            muscleGroups: plan.muscleGroups,
            caloriesBurned: calories,
            averageHeartRate: Int.random(in: 130...160)
        )
        logWorkout(session)
    }
    
    func completeWorkout(title: String, duration: TimeInterval, exercises: [CompletedExercise], muscleGroups: [MuscleGroup]) {
        let session = WorkoutSession(
            id: UUID(),
            title: title,
            date: Date(),
            duration: duration,
            exercises: exercises,
            muscleGroups: muscleGroups,
            caloriesBurned: estimateCalories(duration: duration, exercises: exercises),
            averageHeartRate: Int.random(in: 130...160) // Would integrate with HealthKit in real app
        )
        
        logWorkout(session)
    }
    
    // MARK: - Progress Calculations
    
    func getWorkoutFrequency(for timeframe: TimeFrame) -> Double {
        let calendar = Calendar.current
        let now = Date()
        
        let startDate: Date
        switch timeframe {
        case .week:
            startDate = calendar.startOfWeek(for: now)
        case .month:
            startDate = calendar.startOfMonth(for: now)
        case .year:
            startDate = calendar.startOfYear(for: now)
        }
        
        let workoutsInPeriod = workoutHistory.filter { $0.date >= startDate }
        let daysInPeriod = calendar.numberOfDays(from: startDate, to: now)
        
        return Double(workoutsInPeriod.count) / Double(daysInPeriod) * 7 // Convert to weekly frequency
    }
    
    func getConsistencyScore(for timeframe: TimeFrame) -> Double {
        let calendar = Calendar.current
        let now = Date()
        
        let startDate: Date
        let expectedWorkouts: Int
        
        switch timeframe {
        case .week:
            startDate = calendar.startOfWeek(for: now)
            expectedWorkouts = 4 // Expected workouts per week
        case .month:
            startDate = calendar.startOfMonth(for: now)
            expectedWorkouts = 16 // Expected workouts per month
        case .year:
            startDate = calendar.startOfYear(for: now)
            expectedWorkouts = 200 // Expected workouts per year
        }
        
        let actualWorkouts = workoutHistory.filter { $0.date >= startDate }.count
        return min(Double(actualWorkouts) / Double(expectedWorkouts), 1.0)
    }
    
    func getStrengthProgress(for timeframe: TimeFrame) -> Double {
        // Calculate strength progression based on exercise improvements
        let calendar = Calendar.current
        let now = Date()
        
        let startDate: Date
        switch timeframe {
        case .week:
            startDate = calendar.date(byAdding: .weekOfYear, value: -2, to: now) ?? now
        case .month:
            startDate = calendar.date(byAdding: .month, value: -2, to: now) ?? now
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
        
        let recentWorkouts = workoutHistory.filter { $0.date >= startDate }
        let olderWorkouts = workoutHistory.filter { $0.date < startDate }
        
        guard !recentWorkouts.isEmpty && !olderWorkouts.isEmpty else { return 0.0 }
        
        // Simple strength calculation - would be more sophisticated in real app
        let recentAvgWeight = recentWorkouts.flatMap { $0.exercises }.compactMap { $0.weight }.average()
        let olderAvgWeight = olderWorkouts.flatMap { $0.exercises }.compactMap { $0.weight }.average()
        
        return ((recentAvgWeight - olderAvgWeight) / olderAvgWeight).clamped(to: -0.5...0.5)
    }
    
    func getTotalWorkoutTime(for timeframe: TimeFrame) -> TimeInterval {
        let calendar = Calendar.current
        let now = Date()
        
        let startDate: Date
        switch timeframe {
        case .week:
            startDate = calendar.startOfWeek(for: now)
        case .month:
            startDate = calendar.startOfMonth(for: now)
        case .year:
            startDate = calendar.startOfYear(for: now)
        }
        
        return workoutHistory
            .filter { $0.date >= startDate }
            .map { $0.duration }
            .reduce(0, +)
    }
    
    func getTotalCaloriesBurned(for timeframe: TimeFrame) -> Int {
        let calendar = Calendar.current
        let now = Date()
        
        let startDate: Date
        switch timeframe {
        case .week:
            startDate = calendar.startOfWeek(for: now)
        case .month:
            startDate = calendar.startOfMonth(for: now)
        case .year:
            startDate = calendar.startOfYear(for: now)
        }
        
        return workoutHistory
            .filter { $0.date >= startDate }
            .map { $0.caloriesBurned }
            .reduce(0, +)
    }
    
    func getAverageHeartRate(for timeframe: TimeFrame) -> Int {
        let calendar = Calendar.current
        let now = Date()
        
        let startDate: Date
        switch timeframe {
        case .week:
            startDate = calendar.startOfWeek(for: now)
        case .month:
            startDate = calendar.startOfMonth(for: now)
        case .year:
            startDate = calendar.startOfYear(for: now)
        }
        
        let heartRates = workoutHistory
            .filter { $0.date >= startDate && $0.averageHeartRate > 0 }
            .map { $0.averageHeartRate }
        
        return heartRates.isEmpty ? 0 : Int(heartRates.average())
    }
    
    // MARK: - Achievements
    
    private func setupInitialAchievements() {
        // Initialize simple flags instead of complex array
        hasFirstWorkout = !workoutHistory.isEmpty
        hasWeekWarrior = streakCount >= 5
        hasConsistencyKing = streakCount >= 30
    }
    
    private func checkForNewAchievements(_ session: WorkoutSession) {
        // Update simple achievement flags
        hasFirstWorkout = !workoutHistory.isEmpty
        hasWeekWarrior = getWorkoutsThisWeek() >= 5
        hasConsistencyKing = streakCount >= 30
        Task { await persistProgressAsync() }
    }
    
    // MARK: - Helper Methods
    
    private func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Check if there's a workout today or yesterday
        let hasWorkoutToday = workoutHistory.contains { calendar.isDate($0.date, inSameDayAs: today) }
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let hasWorkoutYesterday = workoutHistory.contains { calendar.isDate($0.date, inSameDayAs: yesterday) }
        
        if hasWorkoutToday {
            // Continue or start streak
            if !hasWorkoutYesterday && streakCount == 0 {
                streakCount = 1
            } else if hasWorkoutYesterday {
                // Streak continues (but don't increment multiple times for same day)
                let lastWorkoutToday = workoutHistory.last { calendar.isDate($0.date, inSameDayAs: today) }
                if let lastWorkout = lastWorkoutToday,
                   calendar.isDate(lastWorkout.date, inSameDayAs: today) &&
                   streakCount == calculateActualStreak() - 1 {
                    streakCount += 1
                }
            }
        }
    }
    
    private func calculateActualStreak() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var currentDate = today
        
        while true {
            let hasWorkout = workoutHistory.contains { calendar.isDate($0.date, inSameDayAs: currentDate) }
            if hasWorkout {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            } else {
                break
            }
        }
        
        return streak
    }
    
    private func updateWeeklyStats() {
        let calendar = Calendar.current
        let startOfWeek = calendar.startOfWeek(for: Date())
        let weekWorkouts = workoutHistory.filter { $0.date >= startOfWeek }
        
        weeklyStats = WeeklyStats(
            workoutsCompleted: weekWorkouts.count,
            totalTime: weekWorkouts.map { $0.duration }.reduce(0, +),
            caloriesBurned: weekWorkouts.map { $0.caloriesBurned }.reduce(0, +),
            averageHeartRate: weekWorkouts.isEmpty ? 0 : Int(weekWorkouts.map { $0.averageHeartRate }.average())
        )
    }
    
    private func getWorkoutsThisWeek() -> Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.startOfWeek(for: Date())
        return workoutHistory.filter { $0.date >= startOfWeek }.count
    }
    
    private func estimateCalories(duration: TimeInterval, exercises: [CompletedExercise]) -> Int {
        // Simple calorie estimation - would use more sophisticated calculation in real app
        let baseCaloriesPerMinute = 8.0 // Average for strength training
        let minutes = duration / 60.0
        return Int(minutes * baseCaloriesPerMinute)
    }
    
    // MARK: - Parsing Helpers (AI -> CompletedExercise)
    private static func parseFirstInt(from text: String) -> Int? {
        let pattern = "\\d+"
        if let range = text.range(of: pattern, options: .regularExpression) {
            return Int(text[range])
        }
        return nil
    }
    
    private static func parseRestTime(_ text: String) -> TimeInterval {
        let lower = text.lowercased()
        if lower.contains("min") || lower.contains("minute") {
            if let n = parseFirstInt(from: lower) { return TimeInterval(n * 60) }
        }
        if lower.contains("sec") || lower.contains("second") {
            if let n = parseFirstInt(from: lower) { return TimeInterval(n) }
        }
        return 90 // default seconds
    }
    
    private static func durationMinutes(from d: AIWorkoutDuration) -> Int {
        switch d {
        case .short: return 30
        case .medium: return 45
        case .long: return 60
        }
    }
    
    // MARK: - Data Persistence (Backend)
    
    private func loadFromBackend() async {
        let userIdOpt: UUID? = await MainActor.run { authService.currentUser?.id }
        guard let userId = userIdOpt else {
            // Not authenticated; clear state
            await MainActor.run {
                self.workoutHistory = []
                self.achievements = []
                self.weeklyStats = WeeklyStats()
                self.streakCount = 0
            }
            return
        }
        
        // Fetch data from backend
        do {
            let history = try await databaseService.getWorkoutHistory(for: userId)
            let ach = try await databaseService.getFitnessAchievements(for: userId)
            let weekStart = Calendar.current.startOfWeek(for: Date())
            let stats = try await databaseService.getWeeklyStats(for: userId, weekStart: weekStart)
            let streak = try await databaseService.getStreak(for: userId)
            
            await MainActor.run {
                self.workoutHistory = history
                self.achievements = ach
                if let s = stats { self.weeklyStats = s } else { self.weeklyStats = WeeklyStats() }
                self.streakCount = streak
            }
        } catch {
            // On error, keep defaults; optionally log
        }
    }
    
    private func persistProgressAsync() async {
        let userIdOpt: UUID? = await MainActor.run { authService.currentUser?.id }
        guard let userId = userIdOpt else { return }
        
        // Persist recent changes
        do {
            if let last = workoutHistory.last {
                try await databaseService.saveWorkoutSession(userId: userId, last)
            }
            
            let weekStart = Calendar.current.startOfWeek(for: Date())
            try await databaseService.upsertWeeklyStats(userId: userId, weekStart: weekStart, stats: weeklyStats)
            try await databaseService.setStreak(userId: userId, count: streakCount)
            try await databaseService.saveFitnessAchievements(userId: userId, achievements)
        } catch {
            // Optionally surface errors via a publisher/toast
        }
    }
    
    // MARK: - Demo Data (for testing)
    
    func addDemoData() {
        let demoWorkouts = generateDemoWorkouts()
        for workout in demoWorkouts {
            logWorkout(workout)
        }
    }
    
    private func generateDemoWorkouts() -> [WorkoutSession] {
        let calendar = Calendar.current
        var workouts: [WorkoutSession] = []
        
        // Generate workouts for the past 30 days
        for i in 1...30 {
            if i % 2 == 0 { // Every other day
                let date = calendar.date(byAdding: .day, value: -i, to: Date())!
                let workout = WorkoutSession(
                    id: UUID(),
                    title: ["Push Day", "Pull Day", "Leg Day", "Cardio"].randomElement()!,
                    date: date,
                    duration: TimeInterval.random(in: 1800...3600), // 30-60 minutes
                    exercises: generateDemoExercises(),
                    muscleGroups: [MuscleGroup.allCases.randomElement()!],
                    caloriesBurned: Int.random(in: 200...500),
                    averageHeartRate: Int.random(in: 130...160)
                )
                workouts.append(workout)
            }
        }
        
        return workouts
    }
    
    private func generateDemoExercises() -> [CompletedExercise] {
        let exerciseNames = ["Bench Press", "Squats", "Deadlifts", "Pull-ups", "Overhead Press", "Rows"]
        return exerciseNames.prefix(3).map { name in
            CompletedExercise(
                name: name,
                sets: Int.random(in: 3...4),
                reps: Int.random(in: 8...12),
                weight: Double.random(in: 50...150),
                restTime: TimeInterval(90),
                completed: true
            )
        }
    }
}

// MARK: - Extensions

extension Array where Element == Double {
    func average() -> Double {
        isEmpty ? 0 : reduce(0, +) / Double(count)
    }
}

extension Array where Element == Int {
    func average() -> Double {
        isEmpty ? 0 : Double(reduce(0, +)) / Double(count)
    }
}

extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        return Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components) ?? date
    }
    
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
    
    func startOfYear(for date: Date) -> Date {
        let components = dateComponents([.year], from: date)
        return self.date(from: components) ?? date
    }
    
    func numberOfDays(from startDate: Date, to endDate: Date) -> Int {
        let components = dateComponents([.day], from: startDate, to: endDate)
        return components.day ?? 0
    }
}
