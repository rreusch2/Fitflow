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
    const userId = (request.authUser as { id: string }).id;
    const overrides = request.body as any;

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
        server.log.error({ err: error }, 'Error saving workout plan');
        return reply.code(500).send({ error: 'Failed to save workout plan' });
      }

      return { plan: savedPlan };
    } catch (error) {
      server.log.error({ err: error }, 'Error generating workout plan');
      return reply.code(500).send({ error: 'Failed to generate workout plan' });
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
  server.post('/meal-suggestions', async (request, reply) => {
    const userId = (request.authUser as { id: string }).id;
    const { date, force_regenerate } = request.body as { date?: string; force_regenerate?: boolean };
    const targetDate = date ? new Date(date) : new Date();
    const dateStr = targetDate.toISOString().split('T')[0];

    try {
      // Check if we already have suggestions for this date
      if (!force_regenerate) {
        const { data: existing } = await server.supabase
          .from('ai_meal_suggestions')
          .select('*')
          .eq('user_id', userId)
          .eq('date', dateStr)
          .single();

        if (existing) {
          return { suggestions: existing.meals, cached: true };
        }
      }

      // Get user preferences and nutrition goals
      const [preferencesResult, nutritionGoalsResult] = await Promise.all([
        server.supabase.from('user_preferences').select('*').eq('user_id', userId).single(),
        server.supabase.from('nutrition_goals').select('*').eq('user_id', userId).single()
      ]);

      const preferences = preferencesResult.data || {};
      const nutritionGoals = nutritionGoalsResult.data || {};

      // Generate AI meal suggestions
      const suggestions = await aiService.generateDailyMealSuggestions({
        userId,
        date: targetDate,
        preferences,
        nutritionGoals
      });

      // Save suggestions to database
      const { error: saveError } = await server.supabase
        .from('ai_meal_suggestions')
        .upsert({
          user_id: userId,
          date: dateStr,
          meals: suggestions,
          prompt_hash: 'daily_suggestions_v1',
          provider: 'grok',
          tokens_used: 1500, // Estimate
          cost_cents: 3
        });

      if (saveError) {
        server.log.error({ err: saveError }, 'Error saving meal suggestions');
      }

      return { suggestions, cached: false };
    } catch (error) {
      server.log.error({ err: error }, 'Error generating meal suggestions');
      return reply.code(500).send({ error: 'Failed to generate meal suggestions' });
    }
  });

  // Analyze current diet
  server.post('/analyze-diet', async (request, reply) => {
    const userId = (request.authUser as { id: string }).id;
    const { days_back = 7 } = request.body as { days_back?: number };

    try {
      // Get recent meal logs
      const endDate = new Date();
      const startDate = new Date(endDate.getTime() - (days_back * 24 * 60 * 60 * 1000));

      const { data: mealLogs } = await server.supabase
        .from('meal_logs')
        .select('*')
        .eq('user_id', userId)
        .gte('logged_date_utc', startDate.toISOString().split('T')[0])
        .lte('logged_date_utc', endDate.toISOString().split('T')[0])
        .order('logged_at', { ascending: false });

      // Get nutrition goals
      const { data: nutritionGoals } = await server.supabase
        .from('nutrition_goals')
        .select('*')
        .eq('user_id', userId)
        .single();

      // Get user preferences
      const { data: preferences } = await server.supabase
        .from('user_preferences')
        .select('*')
        .eq('user_id', userId)
        .single();

      // Analyze diet with AI
      const analysis = await aiService.analyzeDiet({
        userId,
        mealLogs: mealLogs || [],
        nutritionGoals: nutritionGoals || {},
        preferences: preferences || {},
        daysBack: days_back
      });

      return { analysis };
    } catch (error) {
      server.log.error({ err: error }, 'Error analyzing diet');
      return reply.code(500).send({ error: 'Failed to analyze diet' });
    }
  });

  // Generate personalized nutrition tips
  server.get('/nutrition-tips', async (request, reply) => {
    const userId = (request.authUser as { id: string }).id;

    try {
      // Get recent data for context
      const today = new Date().toISOString().split('T')[0];
      const weekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];

      const [nutritionGoalsResult, recentLogsResult, preferencesResult] = await Promise.all([
        server.supabase.from('nutrition_goals').select('*').eq('user_id', userId).single(),
        server.supabase.from('meal_logs').select('*').eq('user_id', userId).gte('logged_date_utc', weekAgo).lte('logged_date_utc', today),
        server.supabase.from('user_preferences').select('*').eq('user_id', userId).single()
      ]);

      const tips = await aiService.generateNutritionTips({
        userId,
        nutritionGoals: nutritionGoalsResult.data || {},
        recentLogs: recentLogsResult.data || [],
        preferences: preferencesResult.data || {}
      });

      return { tips };
    } catch (error) {
      server.log.error({ err: error }, 'Error generating nutrition tips');
      return reply.code(500).send({ error: 'Failed to generate nutrition tips' });
    }
  });

  // Generate weekly meal plan
  server.post('/weekly-meal-plan', async (request, reply) => {
    const userId = (request.authUser as { id: string }).id;
    const { start_date } = request.body as { start_date?: string };
    const startDate = start_date ? new Date(start_date) : new Date();

    try {
      // Get user preferences and nutrition goals
      const [preferencesResult, nutritionGoalsResult] = await Promise.all([
        server.supabase.from('user_preferences').select('*').eq('user_id', userId).single(),
        server.supabase.from('nutrition_goals').select('*').eq('user_id', userId).single()
      ]);

      const weeklyPlan = await aiService.generateWeeklyMealPlan({
        userId,
        startDate,
        preferences: preferencesResult.data || {},
        nutritionGoals: nutritionGoalsResult.data || {}
      });

      // Save the weekly plan
      const { data: savedPlan, error } = await server.supabase
        .from('meal_plans')
        .insert({
          id: weeklyPlan.id,
          user_id: userId,
          title: weeklyPlan.title,
          description: weeklyPlan.description,
          target_calories: weeklyPlan.target_calories,
          macro_breakdown: weeklyPlan.macro_breakdown,
          meals: weeklyPlan.meals,
          shopping_list: weeklyPlan.shopping_list,
          prep_time: weeklyPlan.prep_time,
          ai_generated_notes: weeklyPlan.ai_generated_notes
        })
        .select()
        .single();

      if (error) {
        server.log.error({ err: error }, 'Error saving weekly meal plan');
        return reply.code(500).send({ error: 'Failed to save weekly meal plan' });
      }

      return { plan: savedPlan };
    } catch (error) {
      server.log.error({ err: error }, 'Error generating weekly meal plan');
      return reply.code(500).send({ error: 'Failed to generate weekly meal plan' });
    }
  });
}
