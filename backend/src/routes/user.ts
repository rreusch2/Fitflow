import { FastifyInstance } from 'fastify';
import { UserPreferencesSchema, UpdateUserPreferencesSchema } from '../schemas/user';
import { zodToJsonSchema } from 'zod-to-json-schema';

export async function userRoutes(server: FastifyInstance) {
  // Get current user profile
  server.get('/me', async (request, reply) => {
    const userId = request.user!.id;

    const { data: user, error } = await server.supabase
      .from('users')
      .select(`
        id,
        email,
        subscription_tier,
        has_completed_onboarding,
        created_at,
        updated_at,
        user_preferences (
          fitness,
          nutrition,
          motivation,
          goals,
          created_at,
          updated_at
        ),
        health_profile (
          age,
          height,
          weight,
          activity_level,
          health_conditions,
          medications,
          injuries
        )
      `)
      .eq('id', userId)
      .single();

    if (error) {
      server.log.error('Error fetching user:', error);
      return reply.code(500).send({ error: 'Failed to fetch user data' });
    }

    return {
      user: {
        ...user,
        preferences: user.user_preferences?.[0] || null,
        healthProfile: user.health_profile?.[0] || null
      }
    };
  });

  // Get user preferences
  server.get('/preferences', async (request, reply) => {
    const userId = request.user!.id;

    const { data: preferences, error } = await server.supabase
      .from('user_preferences')
      .select('*')
      .eq('user_id', userId)
      .single();

    if (error && error.code !== 'PGRST116') { // Not found is OK
      server.log.error('Error fetching preferences:', error);
      return reply.code(500).send({ error: 'Failed to fetch preferences' });
    }

    return { preferences: preferences || null };
  });

  // Update user preferences
  server.put('/preferences', {
    schema: {
      body: zodToJsonSchema(UpdateUserPreferencesSchema)
    }
  }, async (request, reply) => {
    const userId = request.user!.id;
    const preferencesData = request.body;

    // Upsert preferences
    const { data: preferences, error } = await server.supabase
      .from('user_preferences')
      .upsert({
        user_id: userId,
        ...preferencesData,
        updated_at: new Date().toISOString()
      })
      .select()
      .single();

    if (error) {
      server.log.error('Error updating preferences:', error);
      return reply.code(500).send({ error: 'Failed to update preferences' });
    }

    // Update onboarding status if not completed
    await server.supabase
      .from('users')
      .update({ has_completed_onboarding: true })
      .eq('id', userId);

    return { preferences };
  });
}
