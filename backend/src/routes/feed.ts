import { FastifyInstance } from 'fastify';
import { AIService } from '../services/ai';

export async function feedRoutes(server: FastifyInstance) {
  const aiService = new AIService();

  // Get daily feed items
  server.get('/daily', async (request, reply) => {
    const userId = request.user!.id;
    const { date } = request.query as { date?: string };
    
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
      server.log.error('Error fetching feed items:', feedError);
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
        .insert(feedItems.map(item => ({
          ...item,
          user_id: userId,
          date: targetDate.toISOString()
        })))
        .select();

      if (saveError) {
        server.log.error('Error saving feed items:', saveError);
        return reply.code(500).send({ error: 'Failed to save feed items' });
      }

      return { feed: savedFeed || [] };
    } catch (error) {
      server.log.error('Error generating daily feed:', error);
      return reply.code(500).send({ error: 'Failed to generate daily feed' });
    }
  });

  // Manually generate feed (admin/dev endpoint)
  server.post('/generate', async (request, reply) => {
    const userId = request.user!.id;

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
        .insert(feedItems.map(item => ({
          ...item,
          user_id: userId,
          date: new Date().toISOString()
        })))
        .select();

      if (error) {
        server.log.error('Error saving generated feed:', error);
        return reply.code(500).send({ error: 'Failed to save feed items' });
      }

      return { feed: savedFeed || [] };
    } catch (error) {
      server.log.error('Error generating feed:', error);
      return reply.code(500).send({ error: 'Failed to generate feed' });
    }
  });
}
