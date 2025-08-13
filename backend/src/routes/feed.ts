import { FastifyInstance } from 'fastify';
import { AIService } from '../services/ai';

export async function feedRoutes(server: FastifyInstance) {
  const aiService = new AIService();

  // Get daily feed items
  server.get('/daily', async (request, reply) => {
    const userId = (request.authUser as { id: string }).id;
    const { date } = (request.query as any) as { date?: string };
    
    const targetDate = date ? new Date(date) : new Date();
    targetDate.setHours(0, 0, 0, 0);
    
    const nextDate = new Date(targetDate);
    nextDate.setDate(nextDate.getDate() + 1);

    // Check if we already have feed items for this date
    const { data: existingFeed, error: feedError } = await server.supabase
      .from('feed_items')
      .select('*')
      .eq('user_id', userId)
      .gte('date', targetDate.toISOString())
      .lt('date', nextDate.toISOString())
      .order('created_at', { ascending: true });

    if (feedError) {
      server.log.error({ err: feedError }, 'Error fetching feed items');
      return reply.code(500).send({ error: 'Failed to fetch feed items' });
    }

    // If we have items for today, return them
    if (existingFeed && existingFeed.length > 0) {
      return { feed: existingFeed };
    }

    try {
      // Generate new feed items for today
      const { data: preferences } = await server.supabase
        .from('user_preferences')
        .select('*')
        .eq('user_id', userId)
        .single();

      const feedItems = await aiService.generateDailyFeed({
        userId,
        date: targetDate,
        preferences: preferences || {}
      });

      // Save feed items to database
      const { data: savedFeed, error: saveError } = await server.supabase
        .from('feed_items')
        .insert((feedItems as any[]).map((item: any) => ({
          ...(item as Record<string, any>),
          user_id: userId,
          date: targetDate.toISOString()
        })))
        .select();

      if (saveError) {
        server.log.error({ err: saveError }, 'Error saving feed items');
        return reply.code(500).send({ error: 'Failed to save feed items' });
      }

      return { feed: savedFeed || [] };
    } catch (error) {
      server.log.error({ err: error }, 'Error generating daily feed');
      return reply.code(500).send({ error: 'Failed to generate daily feed' });
    }
  });

  // Manually generate feed (admin/dev endpoint)
  server.post('/generate', async (request, reply) => {
    const userId = (request.authUser as { id: string }).id;

    try {
      const { data: preferences } = await server.supabase
        .from('user_preferences')
        .select('*')
        .eq('user_id', userId)
        .single();

      const feedItems = await aiService.generateDailyFeed({
        userId,
        date: new Date(),
        preferences: preferences || {}
      });

      const { data: savedFeed, error } = await server.supabase
        .from('feed_items')
        .insert((feedItems as any[]).map((item: any) => ({
          ...(item as Record<string, any>),
          user_id: userId,
          date: new Date().toISOString()
        })))
        .select();

      if (error) {
        server.log.error({ err: error }, 'Error saving generated feed');
        return reply.code(500).send({ error: 'Failed to save feed items' });
      }

      return { feed: savedFeed || [] };
    } catch (error) {
      server.log.error({ err: error }, 'Error generating feed');
      return reply.code(500).send({ error: 'Failed to generate feed' });
    }
  });
}
