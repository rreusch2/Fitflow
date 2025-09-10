import { FastifyInstance } from 'fastify';
import { GenerateWorkoutPlanSchema, GenerateMealPlanSchema } from '../schemas/ai';
import { AIService } from '../services/ai';
import { NutritionAIService } from '../services/nutritionAI';
import { zodToJsonSchema } from 'zod-to-json-schema';

export async function aiRoutes(server: FastifyInstance) {
  const aiService = new AIService();
  const nutritionAI = new NutritionAIService();

  // Generate workout plan
  server.post('/workout-plan', {
    schema: {
      body: zodToJsonSchema(GenerateWorkoutPlanSchema)
    }
  }, async (request, reply) => {
    const userId = (request.authUser as { id: string }).id;
    const overrides = request.body as any;

    try {
      // Get user preferences (JSONB bucket) and extract
      const { data: prefRow } = await server.supabase
        .from('user_preferences')
        .select('preferences')
        .eq('user_id', userId)
        .single();
      const preferences = prefRow?.preferences || {};

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

      console.log('🔥 DEBUG: AI Generated workout plan:', JSON.stringify(workoutPlan, null, 2));

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
        console.log('🔥 DEBUG: Database save error:', error);
        server.log.error({ err: error }, 'Error saving workout plan');
        return reply.code(500).send({ error: 'Failed to save workout plan' });
      }

      return { plan: savedPlan };
    } catch (error) {
      server.log.error({ err: error }, 'Error generating workout plan');
      return reply.code(500).send({ error: 'Failed to generate workout plan' });
    }
  });

  // List user's AI workout plans
  server.get('/workout-plans', async (request, reply) => {
    const userId = (request.authUser as { id: string }).id;

    try {
      const { data, error } = await server.supabase
        .from('workout_plans')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', { ascending: false });

      if (error) {
        server.log.error({ err: error }, 'Error fetching workout plans');
        return reply.code(500).send({ error: 'Failed to fetch workout plans' });
      }

      return reply.send({ plans: data || [] });
    } catch (error) {
      server.log.error({ err: error }, 'Error fetching workout plans');
      return reply.code(500).send({ error: 'Failed to fetch workout plans' });
    }
  });

  // Delete a workout plan (only if it belongs to the user)
  server.delete('/workout-plans/:id', async (request, reply) => {
    const userId = (request.authUser as { id: string }).id;
    const { id } = request.params as { id: string };

    try {
      const { error } = await server.supabase
        .from('workout_plans')
        .delete()
        .eq('id', id)
        .eq('user_id', userId);

      if (error) {
        server.log.error({ err: error }, 'Error deleting workout plan');
        return reply.code(500).send({ error: 'Failed to delete workout plan' });
      }

      return reply.code(204).send();
    } catch (error) {
      server.log.error({ err: error }, 'Error deleting workout plan');
      return reply.code(500).send({ error: 'Failed to delete workout plan' });
    }
  });

  // Generate meal plan
  server.post('/meal-plan', {
    schema: {
      body: zodToJsonSchema(GenerateMealPlanSchema)
    }
  }, async (request, reply) => {
    const userId = (request.authUser as { id: string }).id;
    const overrides = request.body;

    try {
      // Get user preferences (JSONB bucket) and extract
      const { data: prefRow } = await server.supabase
        .from('user_preferences')
        .select('preferences')
        .eq('user_id', userId)
        .single();
      const preferences = prefRow?.preferences || {};

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
        server.log.error({ err: error }, 'Error saving meal plan');
        return reply.code(500).send({ error: 'Failed to save meal plan' });
      }

      return { plan: savedPlan };
    } catch (error) {
      server.log.error({ err: error }, 'Error generating meal plan');
      return reply.code(500).send({ error: 'Failed to generate meal plan' });
    }
  });

  // Generate daily meal suggestions
  server.post('/daily-meal-suggestions', async (request, reply) => {
    const userId = (request.authUser as { id: string }).id;
    const { date, goals } = request.body as any;

    try {
      // Get user preferences and health profile
      const { data: prefRow } = await server.supabase
        .from('user_preferences')
        .select('preferences')
        .eq('user_id', userId)
        .single();
      const preferences = prefRow?.preferences || {};

      const { data: nutritionGoals } = await server.supabase
        .from('nutrition_goals')
        .select('*')
        .eq('user_id', userId)
        .single();

      const { data: healthProfile } = await server.supabase
        .from('health_profile')
        .select('*')
        .eq('user_id', userId)
        .single();

      // Generate suggestions with AI
      const suggestions = await nutritionAI.generateDailySuggestions({
        userId,
        date: new Date(date),
        preferences: { ...(preferences?.nutrition || {}), motivation: preferences?.motivation },
        nutritionGoals: nutritionGoals || {},
        healthProfile: healthProfile || {}
      });

      // Cache suggestions in database
      await server.supabase
        .from('ai_meal_suggestions')
        .upsert({
          user_id: userId,
          date: date,
          meals: suggestions.suggestions,
          provider: 'grok',
          tokens_used: suggestions.tokensUsed,
          cost_cents: suggestions.costCents
        });

      return { suggestions: suggestions.suggestions };
    } catch (error) {
      server.log.error({ err: error }, 'Error generating daily meal suggestions');
      return reply.code(500).send({ error: 'Failed to generate meal suggestions' });
    }
  });

  // Generate weekly meal plan
  server.post('/weekly-meal-plan', async (request, reply) => {
    const userId = (request.authUser as { id: string }).id;
    const { preferences, startDate } = request.body as any;

    try {
      // Get user data
      const { data: prefRow } = await server.supabase
        .from('user_preferences')
        .select('preferences')
        .eq('user_id', userId)
        .single();
      const userPrefs = prefRow?.preferences || {};

      const { data: nutritionGoals } = await server.supabase
        .from('nutrition_goals')
        .select('*')
        .eq('user_id', userId)
        .single();

      const { data: healthProfile } = await server.supabase
        .from('health_profile')
        .select('*')
        .eq('user_id', userId)
        .single();

      // Generate weekly meal plan with AI
      const mealPlan = await nutritionAI.generateWeeklyMealPlan({
        userId,
        preferences: { ...(userPrefs?.nutrition || {}), ...(preferences || {}), motivation: userPrefs?.motivation },
        nutritionGoals: nutritionGoals || {},
        healthProfile: healthProfile || {},
        startDate: new Date(startDate)
      });

      // Save to database
      const { data: savedPlan } = await server.supabase
        .from('meal_plans')
        .insert({
          id: mealPlan.id,
          user_id: userId,
          title: mealPlan.title,
          description: mealPlan.description,
          target_calories: mealPlan.targetCalories,
          macro_breakdown: mealPlan.macroBreakdown,
          meals: mealPlan.meals,
          shopping_list: mealPlan.shoppingList,
          prep_time: mealPlan.prepTime,
          ai_generated_notes: mealPlan.aiGeneratedNotes
        })
        .select()
        .single();

      return mealPlan;
    } catch (error) {
      server.log.error({ err: error }, 'Error generating weekly meal plan');
      return reply.code(500).send({ error: 'Failed to generate weekly meal plan' });
    }
  });

  // Analyze user's diet
  server.post('/analyze-diet', async (request, reply) => {
    const userId = (request.authUser as { id: string }).id;
    const { days = 7 } = request.body as any;

    try {
      // Get recent meal logs
      const endDate = new Date();
      const startDate = new Date();
      startDate.setDate(startDate.getDate() - days);

      const { data: mealLogs } = await server.supabase
        .from('meal_logs')
        .select('*')
        .eq('user_id', userId)
        .gte('logged_date_utc', startDate.toISOString().split('T')[0])
        .lte('logged_date_utc', endDate.toISOString().split('T')[0])
        .order('logged_at', { ascending: false });

      // Get user goals and preferences
      const { data: nutritionGoals } = await server.supabase
        .from('nutrition_goals')
        .select('*')
        .eq('user_id', userId)
        .single();

      const { data: healthProfile } = await server.supabase
        .from('health_profile')
        .select('*')
        .eq('user_id', userId)
        .single();

      // Generate analysis with AI
      // Get preferences for personalization
      const { data: prefRow } = await server.supabase
        .from('user_preferences')
        .select('preferences')
        .eq('user_id', userId)
        .single();
      const preferences = prefRow?.preferences || {};

      const analysis = await nutritionAI.analyzeDiet({
        userId,
        mealLogs: mealLogs || [],
        nutritionGoals: nutritionGoals || {},
        healthProfile: healthProfile || {},
        days,
        preferences: { ...(preferences?.nutrition || {}), motivation: preferences?.motivation }
      });

      return analysis;
    } catch (error) {
      server.log.error({ err: error }, 'Error analyzing diet');
      return reply.code(500).send({ error: 'Failed to analyze diet' });
    }
  });

  // Get personalized nutrition tips
  server.post('/nutrition-tips', async (request, reply) => {
    const userId = (request.authUser as { id: string }).id;

    try {
      // Get user context
      const { data: recentLogs } = await server.supabase
        .from('meal_logs')
        .select('*')
        .eq('user_id', userId)
        .gte('logged_date_utc', new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0])
        .order('logged_at', { ascending: false })
        .limit(20);

      const { data: nutritionGoals } = await server.supabase
        .from('nutrition_goals')
        .select('*')
        .eq('user_id', userId)
        .single();

      const { data: prefRow } = await server.supabase
        .from('user_preferences')
        .select('preferences')
        .eq('user_id', userId)
        .single();
      const preferences = prefRow?.preferences || {};

      // Generate personalized tips with AI
      const tips = await nutritionAI.generatePersonalizedTips({
        userId,
        recentMealLogs: recentLogs || [],
        nutritionGoals: nutritionGoals || {},
        preferences: { ...(preferences?.nutrition || {}), motivation: preferences?.motivation }
      });

      return { tips };
    } catch (error) {
      server.log.error({ err: error }, 'Error generating nutrition tips');
      return reply.code(500).send({ error: 'Failed to generate nutrition tips' });
    }
  });
}
