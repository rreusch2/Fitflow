//
//  AIPrompts.swift
//  Fitflow
//
//  Created on 2025-01-13
//

import Foundation

// MARK: - AI Service Prompt Extensions

extension AIService {
    
    // MARK: - Workout Plan Prompts
    
    func createWorkoutPlanPrompt(preferences: UserPreferences, healthProfile: HealthProfile?) -> String {
        let fitness = preferences.fitness
        let motivation = preferences.motivation
        
        var prompt = """
        Create a personalized workout plan with the following specifications:
        
        USER PROFILE:
        - Fitness Level: \(fitness.level.displayName) (\(fitness.level.description))
        - Preferred Activities: \(fitness.preferredActivities.map { $0.displayName }.joined(separator: ", "))
        - Available Equipment: \(fitness.availableEquipment.map { $0.displayName }.joined(separator: ", "))
        - Workout Duration: \(fitness.workoutDuration.displayName)
        - Workout Frequency: \(fitness.workoutFrequency.displayName)
        - Motivation Style: \(motivation.communicationStyle.displayName)
        """
        
        if !fitness.limitations.isEmpty {
            prompt += "\n- Limitations/Injuries: \(fitness.limitations.joined(separator: ", "))"
        }
        
        if let health = healthProfile {
            if let age = health.age {
                prompt += "\n- Age: \(age) years"
            }
            if !health.healthConditions.isEmpty {
                prompt += "\n- Health Conditions: \(health.healthConditions.joined(separator: ", "))"
            }
            if !health.injuries.isEmpty {
                prompt += "\n- Previous Injuries: \(health.injuries.joined(separator: ", "))"
            }
        }
        
        prompt += """
        
        GOALS:
        \(preferences.goals.map { "- \($0.title): \($0.description)" }.joined(separator: "\n"))
        
        REQUIREMENTS:
        1. Create a safe, effective workout plan appropriate for the user's fitness level
        2. Include 4-6 exercises with proper sets, reps, and rest periods
        3. Focus on the user's preferred activities when possible
        4. Only use available equipment
        5. Match the requested workout duration
        6. Include detailed exercise instructions and safety tips
        7. Provide exercise modifications for easier/harder variations
        8. Add motivational notes in the user's preferred communication style
        
        RESPONSE FORMAT:
        Return a valid JSON object matching this structure:
        {
            "title": "Workout Plan Title",
            "description": "Brief description of the workout",
            "estimatedDuration": 45,
            "targetMuscleGroups": ["chest", "back", "shoulders"],
            "exercises": [
                {
                    "name": "Exercise Name",
                    "description": "Brief exercise description",
                    "muscleGroups": ["chest", "triceps"],
                    "equipment": "dumbbells",
                    "sets": 3,
                    "reps": "10-12",
                    "weight": "moderate",
                    "restTime": 60,
                    "instructions": [
                        "Step 1 instruction",
                        "Step 2 instruction"
                    ],
                    "tips": [
                        "Safety tip 1",
                        "Form tip 2"
                    ],
                    "modifications": [
                        {
                            "type": "easier",
                            "description": "Easier variation name",
                            "instructions": "How to make it easier"
                        }
                    ]
                }
            ],
            "aiGeneratedNotes": "Motivational notes in user's preferred style"
        }
        """
        
        return prompt
    }
    
    func createCustomWorkoutPrompt(
        preferences: UserPreferences?,
        duration: Int,
        focusAreas: [MuscleGroup],
        equipment: [Equipment],
        difficulty: FitnessLevel
    ) -> String {
        let motivationStyle = preferences?.motivation.communicationStyle ?? .supportive
        
        return """
        Create a custom workout plan with these specific requirements:
        
        WORKOUT SPECIFICATIONS:
        - Duration: \(duration) minutes
        - Focus Areas: \(focusAreas.map { $0.displayName }.joined(separator: ", "))
        - Available Equipment: \(equipment.map { $0.displayName }.joined(separator: ", "))
        - Difficulty Level: \(difficulty.displayName)
        - Motivation Style: \(motivationStyle.displayName)
        
        REQUIREMENTS:
        1. Design a \(duration)-minute workout targeting the specified muscle groups
        2. Use only the available equipment
        3. Match the difficulty level appropriately
        4. Include warm-up and cool-down if duration allows
        5. Provide clear exercise instructions and safety guidelines
        6. Add motivational notes in \(motivationStyle.displayName.lowercased()) style
        
        Return the response in the same JSON format as specified in the workout plan structure.
        """
    }
    
    // MARK: - Meal Plan Prompts
    
    func createMealPlanPrompt(preferences: UserPreferences, healthProfile: HealthProfile?) -> String {
        let nutrition = preferences.nutrition
        
        var prompt = """
        Create a personalized daily meal plan with the following specifications:
        
        NUTRITION PROFILE:
        - Dietary Restrictions: \(nutrition.dietaryRestrictions.map { $0.displayName }.joined(separator: ", "))
        - Calorie Goal: \(nutrition.calorieGoal.displayName) (\(nutrition.calorieGoal.description))
        - Meal Preferences: \(nutrition.mealPreferences.map { $0.displayName }.joined(separator: ", "))
        - Cooking Skill: \(nutrition.cookingSkill.displayName)
        - Meal Prep Time: \(nutrition.mealPrepTime.displayName)
        """
        
        if !nutrition.allergies.isEmpty {
            prompt += "\n- Allergies: \(nutrition.allergies.joined(separator: ", "))"
        }
        
        if !nutrition.dislikedFoods.isEmpty {
            prompt += "\n- Disliked Foods: \(nutrition.dislikedFoods.joined(separator: ", "))"
        }
        
        if let health = healthProfile {
            if let weight = health.weight, let height = health.height {
                let bmi = weight / ((height / 100) * (height / 100))
                prompt += "\n- BMI: \(String(format: "%.1f", bmi))"
            }
            prompt += "\n- Activity Level: \(health.activityLevel.displayName)"
        }
        
        prompt += """
        
        GOALS:
        \(preferences.goals.filter { $0.type == .weightLoss || $0.type == .weightGain || $0.type == .muscleGain }.map { "- \($0.title): \($0.description)" }.joined(separator: "\n"))
        
        REQUIREMENTS:
        1. Create a balanced daily meal plan with breakfast, lunch, dinner, and 1-2 snacks
        2. Respect all dietary restrictions and allergies
        3. Match the calorie goal and activity level
        4. Keep recipes within the user's cooking skill level
        5. Ensure meal prep time fits the user's schedule
        6. Provide accurate nutritional information
        7. Include a shopping list
        8. Add helpful cooking tips and meal prep suggestions
        
        RESPONSE FORMAT:
        Return a valid JSON object matching this structure:
        {
            "title": "Daily Meal Plan Title",
            "description": "Brief description of the meal plan",
            "targetCalories": 2000,
            "macroBreakdown": {
                "protein": 150,
                "carbs": 200,
                "fat": 67,
                "fiber": 30
            },
            "meals": [
                {
                    "type": "breakfast",
                    "name": "Meal Name",
                    "description": "Brief meal description",
                    "calories": 400,
                    "macros": {
                        "protein": 25,
                        "carbs": 45,
                        "fat": 15,
                        "fiber": 8
                    },
                    "ingredients": [
                        {
                            "name": "Ingredient name",
                            "amount": 100,
                            "unit": "g",
                            "calories": 50,
                            "isOptional": false,
                            "substitutes": ["Alternative 1", "Alternative 2"]
                        }
                    ],
                    "instructions": [
                        "Step 1",
                        "Step 2"
                    ],
                    "prepTime": 10,
                    "cookTime": 5,
                    "servings": 1,
                    "difficulty": "beginner",
                    "tags": ["quick", "healthy"]
                }
            ],
            "shoppingList": ["Item 1", "Item 2"],
            "prepTime": 60,
            "aiGeneratedNotes": "Helpful tips and motivation in user's preferred style"
        }
        """
        
        return prompt
    }
    
    // MARK: - Chat Prompts
    
    func createChatPrompt(messages: [ChatMessage], user: User, context: ChatContext) -> String {
        guard let preferences = user.preferences else {
            return createBasicChatPrompt(messages: messages, context: context)
        }
        
        let motivation = preferences.motivation
        let contextDescription = getChatContextDescription(context)
        
        var prompt = """
        You are having a conversation with a Fitflow user. Here's their profile:
        
        USER CONTEXT:
        - Communication Style: \(motivation.communicationStyle.displayName) (\(motivation.communicationStyle.description))
        - Fitness Level: \(preferences.fitness.level.displayName)
        - Primary Goals: \(preferences.goals.prefix(3).map { $0.title }.joined(separator: ", "))
        - Context: \(contextDescription)
        
        CONVERSATION STYLE:
        \(motivation.communicationStyle.sampleMessage)
        
        CONVERSATION HISTORY:
        """
        
        for message in messages.suffix(10) { // Last 10 messages for context
            let role = message.role == .user ? "User" : "Assistant"
            prompt += "\n\(role): \(message.content)"
        }
        
        prompt += """
        
        GUIDELINES:
        1. Match the user's preferred communication style
        2. Stay focused on fitness, nutrition, and wellness topics
        3. Be encouraging and supportive
        4. Provide actionable advice when appropriate
        5. Reference their goals and preferences when relevant
        6. Keep responses concise but helpful
        7. If asked about medical advice, remind them to consult healthcare professionals
        
        Respond as the AI assistant in the conversation.
        """
        
        return prompt
    }
    
    private func createBasicChatPrompt(messages: [ChatMessage], context: ChatContext) -> String {
        let contextDescription = getChatContextDescription(context)
        
        var prompt = """
        You are a helpful AI fitness and wellness assistant. Context: \(contextDescription)
        
        CONVERSATION HISTORY:
        """
        
        for message in messages.suffix(10) {
            let role = message.role == .user ? "User" : "Assistant"
            prompt += "\n\(role): \(message.content)"
        }
        
        prompt += """
        
        Provide a helpful, encouraging response focused on fitness and wellness.
        """
        
        return prompt
    }
    
    private func getChatContextDescription(_ context: ChatContext) -> String {
        switch context {
        case .general:
            return "General fitness and wellness conversation"
        case .workout:
            return "Discussion about workout plans and exercises"
        case .nutrition:
            return "Discussion about meal plans and nutrition"
        case .motivation:
            return "Motivational support and encouragement"
        case .progress:
            return "Progress tracking and analysis discussion"
        }
    }
    
    // MARK: - Motivation Prompts
    
    func createMotivationPrompt(
        preferences: UserPreferences,
        trigger: MotivationTrigger,
        context: [String: Any]
    ) -> String {
        let motivation = preferences.motivation
        let triggerDescription = getMotivationTriggerDescription(trigger)
        
        var prompt = """
        Generate a motivational message for a Fitflow user with these characteristics:
        
        USER PROFILE:
        - Communication Style: \(motivation.communicationStyle.displayName)
        - Fitness Level: \(preferences.fitness.level.displayName)
        - Primary Goals: \(preferences.goals.prefix(2).map { $0.title }.joined(separator: ", "))
        - Trigger: \(triggerDescription)
        
        STYLE EXAMPLE:
        \(motivation.communicationStyle.sampleMessage)
        
        CONTEXT:
        """
        
        for (key, value) in context {
            prompt += "\n- \(key): \(value)"
        }
        
        prompt += """
        
        REQUIREMENTS:
        1. Match the user's preferred communication style exactly
        2. Keep the message concise (1-3 sentences)
        3. Make it personal and relevant to their goals
        4. Be genuinely motivating, not generic
        5. Include actionable encouragement when appropriate
        6. Use appropriate emojis if they fit the communication style
        
        Generate only the motivational message, no additional text.
        """
        
        return prompt
    }
    
    private func getMotivationTriggerDescription(_ trigger: MotivationTrigger) -> String {
        switch trigger {
        case .morningBoost:
            return "Morning motivation to start the day strong"
        case .preWorkout:
            return "Pre-workout hype to get energized for exercise"
        case .postWorkout:
            return "Post-workout celebration and encouragement"
        case .plateauBreaker:
            return "Motivation to push through a fitness plateau"
        case .goalReminder:
            return "Reminder about their fitness goals and why they matter"
        case .progressCelebration:
            return "Celebration of recent progress and achievements"
        case .badDayPickup:
            return "Encouragement during a difficult or unmotivated day"
        }
    }
    
    // MARK: - Progress Analysis Prompts
    
    func createProgressAnalysisPrompt(entries: [ProgressEntry], user: User) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        let startDate = entries.first?.date ?? Date()
        let endDate = entries.last?.date ?? Date()
        
        var prompt = """
        Analyze the fitness progress data for a Fitflow user over the period from \(dateFormatter.string(from: startDate)) to \(dateFormatter.string(from: endDate)).
        
        USER PROFILE:
        """
        
        if let preferences = user.preferences {
            prompt += """
            - Fitness Level: \(preferences.fitness.level.displayName)
            - Primary Goals: \(preferences.goals.map { $0.title }.joined(separator: ", "))
            - Communication Style: \(preferences.motivation.communicationStyle.displayName)
            """
        }
        
        prompt += """
        
        PROGRESS DATA:
        """
        
        for entry in entries {
            prompt += """
            
            Date: \(dateFormatter.string(from: entry.date))
            - Workout Completed: \(entry.workoutCompleted ? "Yes" : "No")
            """
            
            if let mood = entry.mood {
                prompt += "\n- Mood: \(mood.displayName) (\(mood.value)/5)"
            }
            
            if let energy = entry.energyLevel {
                prompt += "\n- Energy Level: \(energy.displayName) (\(energy.value)/5)"
            }
            
            if let metrics = entry.bodyMetrics {
                if let weight = metrics.weight {
                    prompt += "\n- Weight: \(String(format: "%.1f", weight)) kg"
                }
                if let bodyFat = metrics.bodyFatPercentage {
                    prompt += "\n- Body Fat: \(String(format: "%.1f", bodyFat))%"
                }
            }
            
            if let notes = entry.notes, !notes.isEmpty {
                prompt += "\n- Notes: \(notes)"
            }
        }
        
        prompt += """
        
        ANALYSIS REQUIREMENTS:
        1. Identify key trends in workout consistency, mood, energy, and body metrics
        2. Highlight significant achievements and improvements
        3. Note any concerning patterns or declines
        4. Provide specific, actionable recommendations
        5. Suggest realistic next goals based on current progress
        6. Match the user's communication style for motivation
        
        RESPONSE FORMAT:
        Return a valid JSON object matching this structure:
        {
            "summary": "Overall progress summary in 2-3 sentences",
            "trends": [
                {
                    "metric": "workout_consistency",
                    "direction": "improving",
                    "change": 15.5,
                    "description": "Workout consistency has improved by 15.5% over the period"
                }
            ],
            "achievements": [
                {
                    "title": "Achievement title",
                    "description": "What they accomplished",
                    "date": "2025-01-10",
                    "category": "workout"
                }
            ],
            "recommendations": [
                {
                    "title": "Recommendation title",
                    "description": "Specific actionable advice",
                    "priority": "high",
                    "category": "workout"
                }
            ],
            "nextGoals": [
                "Specific goal suggestion 1",
                "Specific goal suggestion 2"
            ]
        }
        """
        
        return prompt
    }
}

// MARK: - Response Parsing Extensions

extension AIService {
    func parseProgressAnalysisResponse(_ response: String) throws -> ProgressAnalysis {
        guard let data = response.data(using: .utf8) else {
            throw AIError.parsingError("Invalid response encoding")
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(ProgressAnalysis.self, from: data)
        } catch {
            throw AIError.parsingError("Failed to parse progress analysis: \(error.localizedDescription)")
        }
    }
}
