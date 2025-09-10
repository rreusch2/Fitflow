import { FastifyInstance } from 'fastify';

export async function nutritionRoutes(server: FastifyInstance) {
  // Log a meal using RPC that calculates totals server-side
  server.post('/log-meal', async (request, reply) => {
    const userId = (request.authUser as { id: string }).id;
    const { meal_type, items, source = 'manual', notes = null } = request.body as any;

    try {
      if (!meal_type || !items || !Array.isArray(items)) {
        return reply.code(400).send({ error: 'meal_type and items are required' });
      }

      // Primary: RPC path
      const { data, error } = await server.supabase.rpc('log_meal_with_totals', {
        user_id: userId,
        meal_type,
        items,
        source,
        notes,
      });

      if (error) {
        server.log.warn({ err: error }, 'RPC log_meal_with_totals failed, attempting fallback insert');
        // Fallback: compute totals in API and insert row directly
        try {
          const totals = (items as any[]).reduce(
            (acc, it) => {
              const macros = it.macros || {};
              acc.calories += Number(it.calories || 0);
              acc.protein += Number(macros.protein || 0);
              acc.carbs += Number(macros.carbs || 0);
              acc.fat += Number(macros.fat || 0);
              acc.fiber += Number(macros.fiber || 0);
              return acc;
            },
            { calories: 0, protein: 0, carbs: 0, fat: 0, fiber: 0 }
          );
          const { data: inserted, error: insertError } = await server.supabase
            .from('meal_logs')
            .insert({
              user_id: userId,
              meal_type,
              items,
              totals,
              source,
              notes,
            })
            .select('id')
            .single();

          if (insertError) {
            server.log.error({ err: insertError }, 'Fallback insert into meal_logs failed');
            return reply.code(500).send({ error: 'Failed to log meal' });
          }
          return reply.send({ id: inserted?.id });
        } catch (fbErr) {
          server.log.error({ err: fbErr }, 'Unexpected error in fallback insert');
          return reply.code(500).send({ error: 'Failed to log meal' });
        }
      }

      return reply.send({ id: data });
    } catch (error) {
      server.log.error({ err: error }, 'Unexpected error logging meal');
      return reply.code(500).send({ error: 'Failed to log meal' });
    }
  });

  // Get today summary for nutrition (calories/macros/meals logged)
  server.get('/today-summary', async (request, reply) => {
    const userId = (request.authUser as { id: string }).id;

    try {
      const today = new Date();
      const start = new Date(Date.UTC(today.getUTCFullYear(), today.getUTCMonth(), today.getUTCDate()));
      const end = start; // single day

      const toDateStr = (d: Date) => d.toISOString().slice(0, 10);

      const { data, error } = await server.supabase.rpc('get_nutrition_summary', {
        user_id: userId,
        start_date: toDateStr(start),
        end_date: toDateStr(end),
      });

      if (error) {
        server.log.error({ err: error }, 'Error fetching nutrition summary');
        return reply.code(500).send({ error: 'Failed to fetch summary' });
      }

      return reply.send({ summary: data });
    } catch (error) {
      server.log.error({ err: error }, 'Unexpected error fetching nutrition summary');
      return reply.code(500).send({ error: 'Failed to fetch summary' });
    }
  });
}
