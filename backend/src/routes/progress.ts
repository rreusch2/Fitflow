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
}
