import { FastifyInstance } from 'fastify';
import { userRoutes } from './user';
import { aiRoutes } from './ai';
import { fitnessRoutes } from './fitness';
import { plansRoutes } from './plans';
import { chatRoutes } from './chat';
import { feedRoutes } from './feed';
import { progressRoutes } from './progress';
import { goalsRoutes } from './goals';
import { publicRoutes } from './public';
import { nutritionRoutes } from './nutrition';

export async function setupRoutes(server: FastifyInstance) {
  // API versioning prefix
  await server.register(async function (server) {
    await server.register(userRoutes, { prefix: '/v1' });
    await server.register(aiRoutes, { prefix: '/v1/ai' });
    await server.register(fitnessRoutes, { prefix: '/v1/fitness' });
    await server.register(plansRoutes, { prefix: '/v1/plans' });
    await server.register(chatRoutes, { prefix: '/v1/chat' });
    await server.register(feedRoutes, { prefix: '/v1/feed' });
    await server.register(progressRoutes, { prefix: '/v1/progress' });
    await server.register(goalsRoutes, { prefix: '/v1/goals' });
    await server.register(publicRoutes, { prefix: '/v1/public' });
    await server.register(nutritionRoutes, { prefix: '/v1/nutrition' });
  });
}
