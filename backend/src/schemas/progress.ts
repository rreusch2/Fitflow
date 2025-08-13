import { z } from 'zod';
import { MealTypeEnum } from './ai';

export const MoodRatingEnum = z.enum(['terrible', 'poor', 'okay', 'good', 'excellent']);
export const EnergyLevelEnum = z.enum(['very_low', 'low', 'moderate', 'high', 'very_high']);

export const BodyMetricsSchema = z.object({
  weight: z.number().optional(),
  body_fat_percentage: z.number().optional(),
  muscle_mass: z.number().optional(),
  measurements: z.record(z.number()).optional()
});

export const CreateProgressEntrySchema = z.object({
  date: z.string().datetime(),
  workout_completed: z.boolean(),
  workout_plan_id: z.string().uuid().optional(),
  exercises_completed: z.array(z.any()).optional(),
  meals_logged: z.array(z.any()).optional(),
  body_metrics: BodyMetricsSchema.optional(),
  mood: MoodRatingEnum.optional(),
  energy_level: EnergyLevelEnum.optional(),
  notes: z.string().optional()
});

export const AnalyzeProgressSchema = z.object({
  entries: z.array(z.any()).optional(),
  timeframe: z.enum(['week', 'month', 'quarter']).optional()
});
