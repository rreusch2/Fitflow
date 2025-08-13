import { z } from 'zod';
import { GoalTypeEnum } from './user';

export const CreateGoalSchema = z.object({
  type: GoalTypeEnum,
  title: z.string().min(1).max(200),
  description: z.string().max(1000),
  target_value: z.number().optional(),
  unit: z.string().optional(),
  target_date: z.string().datetime().optional()
});

export const UpdateGoalSchema = z.object({
  title: z.string().min(1).max(200).optional(),
  description: z.string().max(1000).optional(),
  target_value: z.number().optional(),
  current_value: z.number().optional(),
  unit: z.string().optional(),
  target_date: z.string().datetime().optional(),
  is_completed: z.boolean().optional()
});
