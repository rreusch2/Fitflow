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

      const { data, error } = await server.supabase.rpc('log_meal_with_totals', {
        user_id_param: userId,
        meal_type_param: meal_type,
        items_param: items,
        source_param: source,
        notes_param: notes,
      });

      if (error) {
        server.log.error({ err: error }, 'Error logging meal via RPC');
        return reply.code(500).send({ error: 'Failed to log meal' });
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
        user_id_param: userId,
        start_date_param: toDateStr(start),
        end_date_param: toDateStr(end),
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
