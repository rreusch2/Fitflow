import { z } from 'zod';

// Enums matching Swift models
export const SubscriptionTierEnum = z.enum(['free', 'pro', 'lifetime']);
export const FitnessLevelEnum = z.enum(['beginner', 'intermediate', 'advanced']);
export const ActivityTypeEnum = z.enum(['cardio', 'strength', 'yoga', 'hiit', 'pilates', 'running', 'cycling', 'swimming', 'dancing', 'sports']);
export const EquipmentEnum = z.enum(['none', 'dumbbells', 'resistance_bands', 'kettlebells', 'pullup_bar', 'yoga_mat', 'full_gym']);
export const WorkoutDurationEnum = z.enum(['15-30', '30-45', '45-60', '60+']);
export const WorkoutFrequencyEnum = z.enum(['1-2', '3-4', '5-6', '7']);
export const DietaryRestrictionEnum = z.enum(['none', 'vegetarian', 'vegan', 'keto', 'paleo', 'gluten_free', 'dairy_free', 'low_carb', 'mediterranean', 'intermittent_fasting']);
export const CalorieGoalEnum = z.enum(['lose_weight', 'maintain', 'gain_weight', 'build_muscle']);
export const MealPreferenceEnum = z.enum(['quick_and_easy', 'home_cooking', 'meal_prep', 'restaurant_style', 'comfort', 'international', 'healthy', 'budget']);
export const CookingSkillEnum = z.enum(['beginner', 'intermediate', 'advanced']);
export const MealPrepTimeEnum = z.enum(['15', '30', '60', 'unlimited']);
export const CommunicationStyleEnum = z.enum(['energetic', 'calm', 'tough', 'supportive', 'scientific', 'humorous']);
export const ReminderFrequencyEnum = z.enum(['none', 'daily', 'weekdays', 'workout_days', 'custom']);
export const MotivationTriggerEnum = z.enum(['morning_boost', 'pre_workout', 'post_workout', 'plateau_breaker', 'goal_reminder', 'progress_celebration', 'bad_day_pickup']);
export const PreferredTimeEnum = z.enum(['early_morning', 'morning', 'afternoon', 'evening', 'night']);
export const ActivityLevelEnum = z.enum(['sedentary', 'lightly_active', 'moderately_active', 'very_active', 'extremely_active']);
export const GoalTypeEnum = z.enum(['weight_loss', 'weight_gain', 'muscle_gain', 'endurance', 'strength', 'flexibility', 'habit', 'performance']);

// Fitness Preferences
export const FitnessPreferencesSchema = z.object({
  level: FitnessLevelEnum,
  preferred_activities: z.array(ActivityTypeEnum),
  available_equipment: z.array(EquipmentEnum),
  workout_duration: WorkoutDurationEnum,
  workout_frequency: WorkoutFrequencyEnum,
  limitations: z.array(z.string())
});

// Nutrition Preferences
export const NutritionPreferencesSchema = z.object({
  dietary_restrictions: z.array(DietaryRestrictionEnum),
  calorie_goal: CalorieGoalEnum,
  meal_preferences: z.array(MealPreferenceEnum),
  allergies: z.array(z.string()),
  disliked_foods: z.array(z.string()),
  cooking_skill: CookingSkillEnum,
  meal_prep_time: MealPrepTimeEnum
});

// Motivation Preferences
export const MotivationPreferencesSchema = z.object({
  communication_style: CommunicationStyleEnum,
  reminder_frequency: ReminderFrequencyEnum,
  motivation_triggers: z.array(MotivationTriggerEnum),
  preferred_times: z.array(PreferredTimeEnum)
});

// Goal
export const GoalSchema = z.object({
  type: GoalTypeEnum,
  title: z.string(),
  description: z.string(),
  target_value: z.number().optional(),
  unit: z.string().optional(),
  target_date: z.string().datetime().optional()
});

// Health Profile
export const HealthProfileSchema = z.object({
  age: z.number().optional(),
  height: z.number().optional(), // in cm
  weight: z.number().optional(), // in kg
  activity_level: ActivityLevelEnum,
  health_conditions: z.array(z.string()),
  medications: z.array(z.string()),
  injuries: z.array(z.string())
});

// User Preferences
export const UserPreferencesSchema = z.object({
  fitness: FitnessPreferencesSchema,
  nutrition: NutritionPreferencesSchema,
  motivation: MotivationPreferencesSchema,
  goals: z.array(GoalSchema)
});

// Update schemas (all fields optional)
export const UpdateUserPreferencesSchema = z.object({
  fitness: FitnessPreferencesSchema.partial().optional(),
  nutrition: NutritionPreferencesSchema.partial().optional(),
  motivation: MotivationPreferencesSchema.partial().optional(),
  goals: z.array(GoalSchema).optional()
});

// User schema
export const UserSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
  subscription_tier: SubscriptionTierEnum,
  has_completed_onboarding: z.boolean(),
  created_at: z.string().datetime(),
  updated_at: z.string().datetime(),
  preferences: UserPreferencesSchema.optional(),
  health_profile: HealthProfileSchema.optional()
});
