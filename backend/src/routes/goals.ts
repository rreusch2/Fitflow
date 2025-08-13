import { FastifyInstance } from 'fastify';
import { CreateGoalSchema, UpdateGoalSchema } from '../schemas/goals';
import { randomUUID } from 'crypto';
import { zodToJsonSchema } from 'zod-to-json-schema';

export async function goalsRoutes(server: FastifyInstance) {
  // Get all goals for user
  server.get('/', async (request, reply) => {
    const userId = (request.authUser as { id: string }).id;
    const { completed } = (request.query as any) as { completed?: boolean };

    let query = server.supabase
      .from('goals')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false });

    if (completed !== undefined) {
      query = query.eq('is_completed', completed);
    }

    const { data: goals, error } = await query;

    if (error) {
      server.log.error({ err: error }, 'Error fetching goals');
      return reply.code(500).send({ error: 'Failed to fetch goals' });
    }

    return { goals: goals || [] };
  });

  // Create new goal
  server.post('/', {
    schema: {
      body: zodToJsonSchema(CreateGoalSchema)
    }
  }, async (request, reply) => {
    const userId = (request.authUser as { id: string }).id;
    const goalData = (request.body as any) || {};

    const goalId = randomUUID();
    const now = new Date().toISOString();

    const { data: goal, error } = await server.supabase
      .from('goals')
      .insert({
        id: goalId,
        user_id: userId,
        ...(goalData as Record<string, any>),
        current_value: 0,
        is_completed: false,
        created_at: now
      })
      .select()
      .single();

    if (error) {
      server.log.error({ err: error }, 'Error creating goal');
      return reply.code(500).send({ error: 'Failed to create goal' });
    }

    return { goal };
  });

  // Get specific goal
  server.get('/:id', async (request, reply) => {
    const userId = (request.authUser as { id: string }).id;
    const { id } = (request.params as any) as { id: string };

    const { data: goal, error } = await server.supabase
      .from('goals')
      .select('*')
      .eq('id', id)
      .eq('user_id', userId)
      .single();

    if (error) {
      server.log.error({ err: error }, 'Error fetching goal');
      return reply.code(404).send({ error: 'Goal not found' });
    }

    return { goal };
  });

  // Update goal
  server.put('/:id', {
    schema: {
      body: zodToJsonSchema(UpdateGoalSchema)
    }
  }, async (request, reply) => {
    const userId = (request.authUser as { id: string }).id;
    const { id } = (request.params as any) as { id: string };
    const updates = (request.body as any) || {};

    const { data: goal, error } = await server.supabase
      .from('goals')
      .update(updates as Record<string, any>)
      .eq('id', id)
      .eq('user_id', userId)
      .select()
      .single();

    if (error) {
      server.log.error({ err: error }, 'Error updating goal');
      return reply.code(500).send({ error: 'Failed to update goal' });
    }

    return { goal };
  });

  // Delete goal
  server.delete('/:id', async (request, reply) => {
    const userId = (request.authUser as { id: string }).id;
    const { id } = (request.params as any) as { id: string };

    const { error } = await server.supabase
      .from('goals')
      .delete()
      .eq('id', id)
      .eq('user_id', userId);

    if (error) {
      server.log.error({ err: error }, 'Error deleting goal');
      return reply.code(500).send({ error: 'Failed to delete goal' });
    }

    return { success: true };
  });
}
