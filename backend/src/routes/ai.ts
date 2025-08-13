import { FastifyInstance } from 'fastify';
import { GenerateWorkoutPlanSchema, GenerateMealPlanSchema } from '../schemas/ai';
import { AIService } from '../services/ai';
import { zodToJsonSchema } from 'zod-to-json-schema';

export async function aiRoutes(server: FastifyInstance) {
  const aiService = new AIService();

  // Generate workout plan
  server.post('/workout-plan', {
    schema: {
      body: zodToJsonSchema(GenerateWorkoutPlanSchema)
    }
  }, async (request, reply) => {
    const userId = request.user!.id;
    const overrides = request.body;

    try {
      // Get user preferences
      const { data: preferences } = await server.supabase
        .from('user_preferences')
        .select('fitness, nutrition, motivation')
        .eq('user_id', userId)
        .single();

      // Get health profile
      const { data: healthProfile } = await server.supabase
        .from('health_profile')
        .select('*')
        .eq('user_id', userId)
        .single();

      // Generate workout plan with AI
      const workoutPlan = await aiService.generateWorkoutPlan({
        userId,
        preferences: preferences || {},
        healthProfile: healthProfile || {},
        overrides
      });

      // Save to database
      const { data: savedPlan, error } = await server.supabase
        .from('workout_plans')
        .insert({
          id: workoutPlan.id,
          user_id: userId,
          title: workoutPlan.title,
          description: workoutPlan.description,
          difficulty_level: workoutPlan.difficulty_level,
          estimated_duration: workoutPlan.estimated_duration,
          target_muscle_groups: workoutPlan.target_muscle_groups,
          equipment: workoutPlan.equipment,
          exercises: workoutPlan.exercises,
          ai_generated_notes: workoutPlan.ai_generated_notes
        })
        .select()
        .single();

      if (error) {
        server.log.error('Error saving workout plan:', error);
        return reply.code(500).send({ error: 'Failed to save workout plan' });
      }

      return { plan: savedPlan };
    } catch (error) {
      server.log.error('Error generating workout plan:', error);
      return reply.code(500).send({ error: 'Failed to generate workout plan' });
    }
  });

  // Generate meal plan
  server.post('/meal-plan', {
    schema: {
      body: zodToJsonSchema(GenerateMealPlanSchema)
    }
  }, async (request, reply) => {
    const userId = request.user!.id;
    const overrides = request.body;

    try {
      // Get user preferences
      const { data: preferences } = await server.supabase
        .from('user_preferences')
        .select('fitness, nutrition, motivation')
        .eq('user_id', userId)
        .single();

      // Get health profile
      const { data: healthProfile } = await server.supabase
        .from('health_profile')
        .select('*')
        .eq('user_id', userId)
        .single();

      // Generate meal plan with AI
      const mealPlan = await aiService.generateMealPlan({
        userId,
        preferences: preferences || {},
        healthProfile: healthProfile || {},
        overrides
      });

      // Save to database
      const { data: savedPlan, error } = await server.supabase
        .from('meal_plans')
        .insert({
          id: mealPlan.id,
          user_id: userId,
          title: mealPlan.title,
          description: mealPlan.description,
          target_calories: mealPlan.target_calories,
          macro_breakdown: mealPlan.macro_breakdown,
          meals: mealPlan.meals,
          shopping_list: mealPlan.shopping_list,
          prep_time: mealPlan.prep_time,
          ai_generated_notes: mealPlan.ai_generated_notes
        })
        .select()
        .single();

      if (error) {
        server.log.error('Error saving meal plan:', error);
        return reply.code(500).send({ error: 'Failed to save meal plan' });
      }

      return { plan: savedPlan };
    } catch (error) {
      server.log.error('Error generating meal plan:', error);
      return reply.code(500).send({ error: 'Failed to generate meal plan' });
    }
  });
}
