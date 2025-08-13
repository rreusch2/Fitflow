import { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { AIService } from '../services/ai';

export async function publicRoutes(server: FastifyInstance) {
  const aiService = new AIService();

  // Simple health proxy
  server.get('/health', async () => ({ ok: true }));

  // Public chat (non-streaming)
  server.post('/chat', async (request, reply) => {
    const bodySchema = z.object({ message: z.string().min(1) });
    const parse = bodySchema.safeParse(request.body);
    if (!parse.success) return reply.code(400).send({ error: 'Invalid body' });

    try {
      const res = await aiService.chatCompletion({
        sessionId: 'public-session',
        userId: 'public-user',
        message: parse.data.message,
        preferences: {}
      });
      return { message: res.content };
    } catch (e) {
      server.log.error(e);
      return reply.code(500).send({ error: 'Chat failed' });
    }
  });

  // Public workout plan generation
  server.post('/workout-plan', async (request, reply) => {
    const overrides = (request.body as any) || {};
    try {
      const plan = await aiService.generateWorkoutPlan({
        userId: 'public-user',
        preferences: {},
        healthProfile: {},
        overrides
      });
      return { plan };
    } catch (e) {
      server.log.error(e);
      return reply.code(500).send({ error: 'Failed to generate workout plan' });
    }
  });

  // Public meal plan generation
  server.post('/meal-plan', async (request, reply) => {
    const overrides = (request.body as any) || {};
    try {
      const plan = await aiService.generateMealPlan({
        userId: 'public-user',
        preferences: {},
        healthProfile: {},
        overrides
      });
      return { plan };
    } catch (e) {
      server.log.error(e);
      return reply.code(500).send({ error: 'Failed to generate meal plan' });
    }
  });

  // Public daily feed
  server.get('/feed', async (request, reply) => {
    try {
      const items = await aiService.generateDailyFeed({
        userId: 'public-user',
        date: new Date(),
        preferences: {}
      });
      return { items };
    } catch (e) {
      server.log.error(e);
      return reply.code(500).send({ error: 'Failed to generate feed' });
    }
  });

  // Public progress analysis
  server.post('/progress/analyze', async (request, reply) => {
    const body = (request.body as any) || {};
    try {
      const result = await aiService.analyzeProgress({
        userId: 'public-user',
        entries: body.entries || [],
        preferences: {},
        goals: body.goals || []
      });
      return result;
    } catch (e) {
      server.log.error(e);
      return reply.code(500).send({ error: 'Failed to analyze progress' });
    }
  });
}
