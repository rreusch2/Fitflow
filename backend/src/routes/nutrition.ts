import { FastifyInstance } from 'fastify';

export async function nutritionRoutes(server: FastifyInstance) {
  // Get nutrition goals
  server.get('/goals', async (request, reply) => {
    const userId = (request.authUser as { id: string }).id;

    try {
      const { data: goals, error } = await server.supabase
        .from('nutrition_goals')
        .select('*')
        .eq('user_id', userId)
        .single();

      if (error && error.code !== 'PGRST116') {
        server.log.error({ err: error }, 'Error fetching nutrition goals');
        return reply.code(500).send({ error: 'Failed to fetch nutrition goals' });
      }

      return { goals: goals || null };
    } catch (error) {
      server.log.error({ err: error }, 'Error fetching nutrition goals');
      return reply.code(500).send({ error: 'Failed to fetch nutrition goals' });
    }
  });

  // Update nutrition goals
  server.post('/goals', async (request, reply) => {
    const userId = (request.authUser as { id: string }).id;
    const { target_calories, target_macros, diet_preferences, exclusions, opt_in_daily_ai } = request.body as any;

    try {
      const { data: goals, error } = await server.supabase
        .from('nutrition_goals')
        .upsert({
          user_id: userId,
          target_calories,
          target_macros,
          diet_preferences,
          exclusions,
          opt_in_daily_ai,
          updated_at: new Date().toISOString()
        })
        .select()
        .single();

      if (error) {
        server.log.error({ err: error }, 'Error updating nutrition goals');
        return reply.code(500).send({ error: 'Failed to update nutrition goals' });
      }

      return { goals };
    } catch (error) {
      server.log.error({ err: error }, 'Error updating nutrition goals');
      return reply.code(500).send({ error: 'Failed to update nutrition goals' });
    }
  });

  // Get nutrition summary for date range
  server.get('/summary', async (request, reply) => {
    const userId = (request.authUser as { id: string }).id;
    const { start_date, end_date } = request.query as { start_date?: string; end_date?: string };
    
    const startDate = start_date || new Date().toISOString().split('T')[0];
    const endDate = end_date || new Date().toISOString().split('T')[0];

    try {
      const { data: logs, error } = await server.supabase
        .from('meal_logs')
        .select('*')
        .eq('user_id', userId)
        .gte('logged_date_utc', startDate)
        .lte('logged_date_utc', endDate);

      if (error) {
        server.log.error({ err: error }, 'Error fetching meal logs');
        return reply.code(500).send({ error: 'Failed to fetch meal logs' });
      }

      // Calculate totals
      let totalCalories = 0;
      let totalProtein = 0;
      let totalCarbs = 0;
      let totalFat = 0;
      let totalFiber = 0;

      logs?.forEach(log => {
        if (log.totals) {
          totalCalories += log.totals.calories || 0;
          totalProtein += log.totals.protein || 0;
          totalCarbs += log.totals.carbs || 0;
          totalFat += log.totals.fat || 0;
          totalFiber += log.totals.fiber || 0;
        }
      });

      return {
        summary: {
          calories: totalCalories,
          protein: totalProtein,
          carbs: totalCarbs,
          fat: totalFat,
          fiber: totalFiber,
          entries_count: logs?.length || 0
        }
      };
    } catch (error) {
      server.log.error({ err: error }, 'Error calculating nutrition summary');
      return reply.code(500).send({ error: 'Failed to calculate nutrition summary' });
    }
  });

  // Log a meal
  server.post('/log', async (request, reply) => {
    const userId = (request.authUser as { id: string }).id;
    const { meal_type, items, notes, logged_at, source = 'manual' } = request.body as any;

    try {
      // Calculate totals from items
      const totals = items.reduce((acc: any, item: any) => {
        acc.calories += item.calories || 0;
        acc.protein += item.macros?.protein || 0;
        acc.carbs += item.macros?.carbs || 0;
        acc.fat += item.macros?.fat || 0;
        acc.fiber += item.macros?.fiber || 0;
        return acc;
      }, { calories: 0, protein: 0, carbs: 0, fat: 0, fiber: 0 });

      const loggedAt = logged_at ? new Date(logged_at) : new Date();
      
      const { data: log, error } = await server.supabase
        .from('meal_logs')
        .insert({
          user_id: userId,
          logged_at: loggedAt.toISOString(),
          logged_date_utc: loggedAt.toISOString().split('T')[0],
          meal_type,
          items,
          totals,
          source,
          notes
        })
        .select()
        .single();

      if (error) {
        server.log.error({ err: error }, 'Error logging meal');
        return reply.code(500).send({ error: 'Failed to log meal' });
      }

      return { log };
    } catch (error) {
      server.log.error({ err: error }, 'Error logging meal');
      return reply.code(500).send({ error: 'Failed to log meal' });
    }
  });

  // Get meal logs
  server.get('/logs', async (request, reply) => {
    const userId = (request.authUser as { id: string }).id;
    const { start_date, end_date, limit = 50 } = request.query as { start_date?: string; end_date?: string; limit?: number };
    
    const startDate = start_date || new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
    const endDate = end_date || new Date().toISOString().split('T')[0];

    try {
      const { data: logs, error } = await server.supabase
        .from('meal_logs')
        .select('*')
        .eq('user_id', userId)
        .gte('logged_date_utc', startDate)
        .lte('logged_date_utc', endDate)
        .order('logged_at', { ascending: false })
        .limit(limit);

      if (error) {
        server.log.error({ err: error }, 'Error fetching meal logs');
        return reply.code(500).send({ error: 'Failed to fetch meal logs' });
      }

      return { logs: logs || [] };
    } catch (error) {
      server.log.error({ err: error }, 'Error fetching meal logs');
      return reply.code(500).send({ error: 'Failed to fetch meal logs' });
    }
  });

  // Add meal to plan (save for future)
  server.post('/plan/add', async (request, reply) => {
    const userId = (request.authUser as { id: string }).id;
    const { date, meals } = request.body as { date: string; meals: any[] };

    try {
      const { data: plan, error } = await server.supabase
        .from('meal_plan_days')
        .upsert({
          user_id: userId,
          date,
          meals: meals
        })
        .select()
        .single();

      if (error) {
        server.log.error({ err: error }, 'Error saving meal plan');
        return reply.code(500).send({ error: 'Failed to save meal plan' });
      }

      return { plan };
    } catch (error) {
      server.log.error({ err: error }, 'Error saving meal plan');
      return reply.code(500).send({ error: 'Failed to save meal plan' });
    }
  });

  // Get meal plan for date
  server.get('/plan/:date', async (request, reply) => {
    const userId = (request.authUser as { id: string }).id;
    const { date } = request.params as { date: string };

    try {
      const { data: plan, error } = await server.supabase
        .from('meal_plan_days')
        .select('*')
        .eq('user_id', userId)
        .eq('date', date)
        .single();

      if (error && error.code !== 'PGRST116') {
        server.log.error({ err: error }, 'Error fetching meal plan');
        return reply.code(500).send({ error: 'Failed to fetch meal plan' });
      }

      return { plan: plan || null };
    } catch (error) {
      server.log.error({ err: error }, 'Error fetching meal plan');
      return reply.code(500).send({ error: 'Failed to fetch meal plan' });
    }
  });

  // Search food items
  server.get('/food/search', async (request, reply) => {
    const userId = (request.authUser as { id: string }).id;
    const { query, limit = 20 } = request.query as { query: string; limit?: number };

    try {
      const { data: foods, error } = await server.supabase
        .from('food_items')
        .select('*')
        .or(`user_id.eq.${userId},is_public.eq.true`)
        .ilike('name', `%${query}%`)
        .limit(limit);

      if (error) {
        server.log.error({ err: error }, 'Error searching food items');
        return reply.code(500).send({ error: 'Failed to search food items' });
      }

      return { foods: foods || [] };
    } catch (error) {
      server.log.error({ err: error }, 'Error searching food items');
      return reply.code(500).send({ error: 'Failed to search food items' });
    }
  });

  // Add custom food item
  server.post('/food', async (request, reply) => {
    const userId = (request.authUser as { id: string }).id;
    const { name, brand, serving, calories, macros, tags } = request.body as any;

    try {
      const { data: food, error } = await server.supabase
        .from('food_items')
        .insert({
          user_id: userId,
          name,
          brand,
          serving,
          calories,
          macros,
          tags: tags || [],
          source: 'user_created'
        })
        .select()
        .single();

      if (error) {
        server.log.error({ err: error }, 'Error creating food item');
        return reply.code(500).send({ error: 'Failed to create food item' });
      }

      return { food };
    } catch (error) {
      server.log.error({ err: error }, 'Error creating food item');
      return reply.code(500).send({ error: 'Failed to create food item' });
    }
  });

  // Get nutrition preferences
  server.get('/preferences', async (request, reply) => {
    try {
      const userId = (request.authUser as { id: string }).id;
      if (!userId) {
        return reply.code(401).send({ error: 'Unauthorized' });
      }

      const { data, error } = await server.supabase
        .from('nutrition_preferences')
        .select('*')
        .eq('user_id', userId)
        .single();

      if (error && error.code !== 'PGRST116') { // PGRST116 = no rows found
        server.log.error({ err: error }, 'Error fetching nutrition preferences');
        return reply.code(500).send({ error: 'Failed to fetch preferences' });
      }

      // Return default preferences if none found
      const defaultPreferences = {
        dietary_restrictions: [],
        preferred_cuisines: [],
        disliked_foods: [],
        meals_per_day: 3,
        max_prep_time: 'medium',
        cooking_skill: 'intermediate',
        include_snacks: true,
        meal_prep_friendly: false,
        budget_level: 'moderate',
        prefer_local_seasonal: false,
        consider_workout_schedule: true,
        optimize_for_recovery: false,
        include_supplements: false
      };

      return reply.send({ preferences: data || defaultPreferences });
    } catch (err) {
      server.log.error({ err }, 'Error in get nutrition preferences');
      return reply.code(500).send({ error: 'Internal server error' });
    }
  });

  // Save nutrition preferences
  server.post('/preferences', async (request, reply) => {
    try {
      const userId = (request.authUser as { id: string }).id;
      if (!userId) {
        return reply.code(401).send({ error: 'Unauthorized' });
      }

      const preferences = request.body as any;
      const preferencesData = {
        user_id: userId,
        dietary_restrictions: preferences.dietary_restrictions || [],
        preferred_cuisines: preferences.preferred_cuisines || [],
        disliked_foods: preferences.disliked_foods || [],
        meals_per_day: preferences.meals_per_day || 3,
        max_prep_time: preferences.max_prep_time || 'medium',
        cooking_skill: preferences.cooking_skill || 'intermediate',
        include_snacks: preferences.include_snacks !== undefined ? preferences.include_snacks : true,
        meal_prep_friendly: preferences.meal_prep_friendly || false,
        budget_level: preferences.budget_level || 'moderate',
        prefer_local_seasonal: preferences.prefer_local_seasonal || false,
        consider_workout_schedule: preferences.consider_workout_schedule !== undefined ? preferences.consider_workout_schedule : true,
        optimize_for_recovery: preferences.optimize_for_recovery || false,
        include_supplements: preferences.include_supplements || false,
        updated_at: new Date().toISOString()
      };

      const { data, error } = await server.supabase
        .from('nutrition_preferences')
        .upsert(preferencesData, { onConflict: 'user_id' })
        .select()
        .single();

      if (error) {
        server.log.error({ err: error }, 'Error saving nutrition preferences');
        return reply.code(500).send({ error: 'Failed to save preferences' });
      }

      return reply.send({ success: true, message: 'Preferences saved successfully' });
    } catch (err) {
      server.log.error({ err }, 'Error in save nutrition preferences');
      return reply.code(500).send({ error: 'Internal server error' });
    }
  });

  // Quick add calories
  server.post('/quick-add', async (request, reply) => {
    try {
      const userId = (request.authUser as { id: string }).id;
      if (!userId) {
        return reply.code(401).send({ error: 'Unauthorized' });
      }

      const { calories, description, meal_type } = request.body as {
        calories: number;
        description?: string;
        meal_type: string;
      };

      if (!calories || calories <= 0) {
        return reply.code(400).send({ error: 'Valid calories amount is required' });
      }

      const quickAddData = {
        user_id: userId,
        calories,
        description: description || `Quick add - ${calories} calories`,
        meal_type: meal_type || 'snack',
        protein: 0,
        carbs: 0,
        fat: 0,
        fiber: 0,
        sugar: 0,
        sodium: 0,
        source: 'quick_add',
        logged_at: new Date().toISOString(),
        logged_date_utc: new Date().toISOString().split('T')[0]
      };

      const { data, error } = await server.supabase
        .from('nutrition_logs')
        .insert(quickAddData)
        .select()
        .single();

      if (error) {
        server.log.error({ err: error }, 'Error quick adding calories');
        return reply.code(500).send({ error: 'Failed to add calories' });
      }

      return reply.send({ success: true, log: data });
    } catch (err) {
      server.log.error({ err }, 'Error in quick add calories');
      return reply.code(500).send({ error: 'Internal server error' });
    }
  });
}
