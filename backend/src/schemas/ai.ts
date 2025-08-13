import { z } from 'zod';
import { FitnessLevelEnum, EquipmentEnum, ActivityTypeEnum } from './user';

// Muscle Groups
export const MuscleGroupEnum = z.enum([
  'chest', 'back', 'shoulders', 'biceps', 'triceps', 'forearms', 
  'abs', 'obliques', 'lower_back', 'glutes', 'quadriceps', 
  'hamstrings', 'calves', 'full_body', 'cardio'
]);

// Generate Workout Plan
export const GenerateWorkoutPlanSchema = z.object({
  difficulty_level: FitnessLevelEnum.optional(),
  estimated_duration: z.number().min(15).max(180).optional(),
  target_muscle_groups: z.array(MuscleGroupEnum).optional(),
  equipment: z.array(EquipmentEnum).optional(),
  preferred_activities: z.array(ActivityTypeEnum).optional(),
  limitations: z.array(z.string()).optional()
});

// Generate Meal Plan
export const GenerateMealPlanSchema = z.object({
  target_calories: z.number().min(800).max(5000).optional(),
  dietary_restrictions: z.array(z.string()).optional(),
  allergies: z.array(z.string()).optional(),
  meal_preferences: z.array(z.string()).optional(),
  cooking_skill: z.enum(['beginner', 'intermediate', 'advanced']).optional(),
  prep_time: z.number().min(15).max(120).optional()
});

// Exercise Modification Type
export const ModificationTypeEnum = z.enum(['easier', 'harder', 'low_impact', 'no_equipment', 'injury']);

// Exercise Modification
export const ExerciseModificationSchema = z.object({
  type: ModificationTypeEnum,
  description: z.string(),
  instructions: z.string()
});

// Exercise
export const ExerciseSchema = z.object({
  id: z.string().uuid(),
  name: z.string(),
  description: z.string(),
  muscle_groups: z.array(MuscleGroupEnum),
  equipment: EquipmentEnum.optional(),
  sets: z.number().optional(),
  reps: z.string().optional(), // Can be "10-12" or "30 seconds"
  weight: z.string().optional(), // Can be "bodyweight" or "15 lbs"
  rest_time: z.number().optional(), // in seconds
  instructions: z.array(z.string()),
  tips: z.array(z.string()),
  modifications: z.array(ExerciseModificationSchema),
  video_url: z.string().url().optional(),
  image_url: z.string().url().optional()
});

// Macro Breakdown
export const MacroBreakdownSchema = z.object({
  protein: z.number(), // in grams
  carbs: z.number(), // in grams
  fat: z.number(), // in grams
  fiber: z.number() // in grams
});

// Meal Type
export const MealTypeEnum = z.enum(['breakfast', 'lunch', 'dinner', 'snack', 'preworkout', 'postworkout']);

// Ingredient
export const IngredientSchema = z.object({
  id: z.string().uuid(),
  name: z.string(),
  amount: z.number(),
  unit: z.string(),
  calories: z.number(),
  macros: MacroBreakdownSchema,
  is_optional: z.boolean(),
  substitutes: z.array(z.string())
});

// Meal
export const MealSchema = z.object({
  id: z.string().uuid(),
  type: MealTypeEnum,
  name: z.string(),
  description: z.string(),
  calories: z.number(),
  macros: MacroBreakdownSchema,
  ingredients: z.array(IngredientSchema),
  instructions: z.array(z.string()),
  prep_time: z.number(), // in minutes
  cook_time: z.number(), // in minutes
  servings: z.number(),
  difficulty: z.enum(['beginner', 'intermediate', 'advanced']),
  tags: z.array(z.string()),
  image_url: z.string().url().optional()
});

// Workout Plan Response
export const WorkoutPlanSchema = z.object({
  id: z.string().uuid(),
  user_id: z.string().uuid(),
  title: z.string(),
  description: z.string(),
  difficulty_level: FitnessLevelEnum,
  estimated_duration: z.number(),
  target_muscle_groups: z.array(MuscleGroupEnum),
  equipment: z.array(EquipmentEnum),
  exercises: z.array(ExerciseSchema),
  ai_generated_notes: z.string().optional(),
  created_at: z.string().datetime(),
  updated_at: z.string().datetime()
});

// Meal Plan Response
export const MealPlanSchema = z.object({
  id: z.string().uuid(),
  user_id: z.string().uuid(),
  title: z.string(),
  description: z.string(),
  target_calories: z.number(),
  macro_breakdown: MacroBreakdownSchema,
  meals: z.array(MealSchema),
  shopping_list: z.array(z.string()),
  prep_time: z.number(), // in minutes
  ai_generated_notes: z.string().optional(),
  created_at: z.string().datetime(),
  updated_at: z.string().datetime()
});
