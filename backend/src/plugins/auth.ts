import fp from 'fastify-plugin';
import { FastifyRequest, FastifyReply } from 'fastify';

declare module 'fastify' {
  interface FastifyRequest {
    authUser?: {
      id: string;
      email: string;
      subscription_tier: string;
    };
  }
}

export const authPlugin = fp(async (fastify) => {
  // Only decorate if not already present
  if (!fastify.hasRequestDecorator('authUser')) {
    fastify.decorateRequest('authUser', null);
  }

  fastify.addHook('preHandler', async (request: FastifyRequest, reply: FastifyReply) => {
    // Skip auth for health check and public routes
    if (request.url === '/health' || request.url.startsWith('/v1/public/')) {
      return;
    }

    const authHeader = request.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      reply.code(401).send({ error: 'Missing or invalid authorization header' });
      return;
    }

    const token = authHeader.substring(7);

    try {
      // Verify JWT with Supabase
      const { data: { user }, error } = await fastify.supabase.auth.getUser(token);
      
      if (error || !user) {
        reply.code(401).send({ error: 'Invalid token' });
        return;
      }

      // Fetch user details from database
      const { data: userData, error: userError } = await fastify.supabase
        .from('users')
        .select('id, email, subscription_tier')
        .eq('id', user.id)
        .single();

      if (userError || !userData) {
        reply.code(401).send({ error: 'User not found' });
        return;
      }

      request.authUser = userData;
    } catch (error) {
      fastify.log.error({ err: error }, 'Auth error');
      reply.code(401).send({ error: 'Authentication failed' });
    }
  });
});
