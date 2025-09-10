import { FastifyInstance } from 'fastify';
import { CreateProgressEntrySchema, AnalyzeProgressSchema } from '../schemas/progress';
import { AIService } from '../services/ai';
import { randomUUID } from 'crypto';
import { zodToJsonSchema } from 'zod-to-json-schema';

export async function progressRoutes(server: FastifyInstance) {
  const aiService = new AIService();

  // Create progress entry
  server.post('/', {
    schema: {
      body: zodToJsonSchema(CreateProgressEntrySchema)
    }
  }, async (request, reply) => {
    const userId = (request.authUser as { id: string }).id;
    const progressData = (request.body as any) || {};

    const progressId = randomUUID();
    const now = new Date().toISOString();

    const { data: progress, error } = await server.supabase
      .from('progress_entries')
      .insert({
        id: progressId,
        user_id: userId,
        ...(progressData as Record<string, any>),
        created_at: now
      })
      .select()
      .single();

    if (error) {
      server.log.error({ err: error }, 'Error creating progress entry');
      return reply.code(500).send({ error: 'Failed to create progress entry' });
    }

    return { progress };
  });

  // Get progress entries
  server.get('/', async (request, reply) => {
    const userId = (request.authUser as { id: string }).id;
    const { from, to, limit = 50 } = (request.query as any) as { 
      from?: string; 
      to?: string; 
      limit?: number; 
    };

    let query = server.supabase
      .from('progress_entries')
      .select('*')
      .eq('user_id', userId)
      .order('date', { ascending: false })
      .limit(limit);

    if (from) {
      query = query.gte('date', from);
    }
    if (to) {
      query = query.lte('date', to);
    }

    const { data: entries, error } = await query;

    if (error) {
      server.log.error({ err: error }, 'Error fetching progress entries');
      return reply.code(500).send({ error: 'Failed to fetch progress entries' });
    }

    return { entries: entries || [] };
  });

  // Analyze progress
  server.post('/analyze', {
    schema: {
      body: zodToJsonSchema(AnalyzeProgressSchema)
    }
  }, async (request, reply) => {
    const userId = (request.authUser as { id: string }).id;
    const { entries: providedEntries, timeframe } = (request.body as any) || {};

    try {
      let entries = providedEntries;

      // If no entries provided, fetch recent entries
      if (!entries || entries.length === 0) {
        const daysBack = timeframe === 'week' ? 7 : timeframe === 'month' ? 30 : 90;
        const fromDate = new Date();
        fromDate.setDate(fromDate.getDate() - daysBack);

        const { data: fetchedEntries, error } = await server.supabase
          .from('progress_entries')
          .select('*')
          .eq('user_id', userId)
          .gte('date', fromDate.toISOString())
          .order('date', { ascending: true });

        if (error) {
          server.log.error({ err: error }, 'Error fetching entries for analysis');
          return reply.code(500).send({ error: 'Failed to fetch progress data' });
        }

        entries = fetchedEntries || [];
      }

      if (entries.length === 0) {
        return reply.code(400).send({ error: 'No progress data available for analysis' });
      }

      // Get user context
      const { data: preferences } = await server.supabase
        .from('user_preferences')
        .select('*')
        .eq('user_id', userId)
        .single();

      const { data: goals } = await server.supabase
        .from('goals')
        .select('*')
        .eq('user_id', userId)
        .eq('is_completed', false);

      // Generate AI analysis
      const analysis = await aiService.analyzeProgress({
        userId,
        entries,
        preferences: preferences || {},
        goals: goals || []
      });

      return { analysis };
    } catch (error) {
      server.log.error({ err: error }, 'Error analyzing progress');
      return reply.code(500).send({ error: 'Failed to analyze progress' });
    }
  });

  // Create a workout session (manual or AI-completed)
  server.post('/sessions', async (request, reply) => {
    const userId = (request.authUser as { id: string }).id;
    const body = (request.body as any) || {};
    const now = new Date().toISOString();

    const payload = {
      id: randomUUID(),
      user_id: userId,
      title: body.title ?? 'Workout',
      occurred_at: body.occurred_at ?? now,
      duration_seconds: body.duration_seconds ?? 0,
      exercises: body.exercises ?? [],
      muscle_groups: body.muscle_groups ?? [],
      calories_burned: body.calories_burned ?? null,
      average_heart_rate: body.average_heart_rate ?? null,
      created_at: now
    };

    const { data: session, error } = await server.supabase
      .from('workout_sessions')
      .insert(payload)
      .select()
      .single();

    if (error) {
      server.log.error({ err: error }, 'Error creating workout session');
      return reply.code(500).send({ error: 'Failed to create workout session' });
    }

    return { session };
  });

  // List workout sessions for user
  server.get('/sessions', async (request, reply) => {
    const userId = (request.authUser as { id: string }).id;
    const { from, to, limit = 50 } = (request.query as any) as {
      from?: string;
      to?: string;
      limit?: number;
    };

    let query = server.supabase
      .from('workout_sessions')
      .select('*')
      .eq('user_id', userId)
      .order('occurred_at', { ascending: false })
      .limit(limit);

    if (from) query = query.gte('occurred_at', from);
    if (to) query = query.lte('occurred_at', to);

    const { data: sessions, error } = await query;
    if (error) {
      server.log.error({ err: error }, 'Error fetching workout sessions');
      return reply.code(500).send({ error: 'Failed to fetch workout sessions' });
    }

    return { sessions: sessions || [] };
  });
}
