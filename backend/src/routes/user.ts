import { FastifyInstance } from 'fastify';
import { UserPreferencesSchema, UpdateUserPreferencesSchema } from '../schemas/user';
import { zodToJsonSchema } from 'zod-to-json-schema';
import { buildPersonalizationContext } from '../services/personalization';

export async function userRoutes(server: FastifyInstance) {
  // Get current user profile
  server.get('/me', async (request, reply) => {
    const userId = (request.authUser as { id: string }).id;

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
      server.log.error({ err: error }, 'Error fetching user');
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

  // Debug: Get computed personalization context
  server.get('/personalization-context', async (request, reply) => {
    const userId = (request.authUser as { id: string }).id;

    const { data: prefRow } = await server.supabase
      .from('user_preferences')
      .select('preferences')
      .eq('user_id', userId)
      .single();

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

    const preferences = prefRow?.preferences || {};
    const context = buildPersonalizationContext({
      motivations: preferences?.motivation,
      preferences,
      nutritionGoals: nutritionGoals || {},
      healthProfile: healthProfile || {},
    });

    return { context };
  });

  // Get user preferences (JSONB bucket)
  server.get('/preferences', async (request, reply) => {
    const userId = (request.authUser as { id: string }).id;

    const { data: row, error } = await server.supabase
      .from('user_preferences')
      .select('preferences')
      .eq('user_id', userId)
      .single();

    if (error && (error as any).code !== 'PGRST116') { // Not found is OK
      server.log.error({ err: error }, 'Error fetching preferences');
      return reply.code(500).send({ error: 'Failed to fetch preferences' });
    }

    return { preferences: row?.preferences || null };
  });

  // Update user preferences (wrap body into JSONB 'preferences')
  server.put('/preferences', {
    schema: {
      body: zodToJsonSchema(UpdateUserPreferencesSchema)
    }
  }, async (request, reply) => {
    const userId = (request.authUser as { id: string }).id;
    const preferencesData = (request.body as any) || {};

    // Upsert preferences
    const { data: preferences, error } = await server.supabase
      .from('user_preferences')
      .upsert({
        user_id: userId,
        preferences: preferencesData as Record<string, any>,
        updated_at: new Date().toISOString()
      })
      .select()
      .single();

    if (error) {
      server.log.error({ err: error }, 'Error updating preferences');
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
