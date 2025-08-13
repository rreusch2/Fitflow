import { FastifyInstance } from 'fastify';

export async function plansRoutes(server: FastifyInstance) {
  // Get workout plans for user
  server.get('/workout', async (request, reply) => {
    const userId = (request.authUser as { id: string }).id;
    const { limit = 20, cursor } = (request.query as any) as { limit?: number; cursor?: string };

    let query = server.supabase
      .from('workout_plans')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .limit(limit);

    if (cursor) {
      query = query.lt('created_at', cursor);
    }

    const { data: plans, error } = await query;

    if (error) {
      server.log.error({ err: error }, 'Error fetching workout plans');
      return reply.code(500).send({ error: 'Failed to fetch workout plans' });
    }

    return { plans: plans || [] };
  });

  // Get specific workout plan
  server.get('/workout/:id', async (request, reply) => {
    const userId = (request.authUser as { id: string }).id;
    const { id } = (request.params as any) as { id: string };

    const { data: plan, error } = await server.supabase
      .from('workout_plans')
      .select('*')
      .eq('id', id)
      .eq('user_id', userId)
      .single();

    if (error) {
      server.log.error({ err: error }, 'Error fetching workout plan');
      return reply.code(404).send({ error: 'Workout plan not found' });
    }

    return { plan };
  });

  // Get meal plans for user
  server.get('/meal', async (request, reply) => {
    const userId = (request.authUser as { id: string }).id;
    const { limit = 20, cursor } = (request.query as any) as { limit?: number; cursor?: string };

    let query = server.supabase
      .from('meal_plans')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .limit(limit);

    if (cursor) {
      query = query.lt('created_at', cursor);
    }

    const { data: plans, error } = await query;

    if (error) {
      server.log.error({ err: error }, 'Error fetching meal plans');
      return reply.code(500).send({ error: 'Failed to fetch meal plans' });
    }

    return { plans: plans || [] };
  });

  // Get specific meal plan
  server.get('/meal/:id', async (request, reply) => {
    const userId = (request.authUser as { id: string }).id;
    const { id } = (request.params as any) as { id: string };

    const { data: plan, error } = await server.supabase
      .from('meal_plans')
      .select('*')
      .eq('id', id)
      .eq('user_id', userId)
      .single();

    if (error) {
      server.log.error({ err: error }, 'Error fetching meal plan');
      return reply.code(404).send({ error: 'Meal plan not found' });
    }

    return { plan };
  });
}
