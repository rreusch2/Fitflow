import fp from 'fastify-plugin';
import { FastifyRequest, FastifyReply } from 'fastify';
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { config } from '../config';

declare module 'fastify' {
  interface FastifyRequest {
    authUser?: {
      id: string;
      email: string;
      subscription_tier: string;
    };
    supabaseUser?: SupabaseClient;
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
      fastify.log.warn({ msg: 'Missing/invalid Authorization header' });
      reply.code(401).send({ error: 'Missing or invalid authorization header' });
      return;
    }

    const token = authHeader.substring(7);

    try {
      // Verify JWT with Supabase
      fastify.log.info({ msg: 'Verifying Supabase JWT', tokenPrefix: token.slice(0, 12) + '…' });
      const { data: { user }, error } = await fastify.supabase.auth.getUser(token);
      
      if (error || !user) {
        fastify.log.warn({ msg: 'Supabase auth.getUser failed', err: error, tokenPrefix: token.slice(0, 12) + '…' });
        reply.code(401).send({ error: 'Invalid token' });
        return;
      }

      // Create a per-request Supabase client authenticated as this user for RLS-safe DB ops
      const userClient = createClient(
        config.SUPABASE_URL,
        config.SUPABASE_ANON_KEY,
        {
          auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false },
          global: { headers: { Authorization: `Bearer ${token}` } }
        }
      );

      // Fetch user details from database
      let { data: userData, error: userError } = await userClient
        .from('users')
        .select('id, email, subscription_tier')
        .eq('id', user.id)
        .single();

      // Auto-provision a minimal user row if missing
      if (userError || !userData) {
        fastify.log.warn({ userId: user.id, err: userError }, 'User not found in users table, creating...');
        const { data: inserted, error: insertError } = await userClient
          .from('users')
          .insert({ id: user.id, email: user.email, subscription_tier: 'free' })
          .select('id, email, subscription_tier')
          .single();

        if (insertError) {
          fastify.log.error({ err: insertError }, 'Failed to auto-provision user');
          reply.code(401).send({ error: 'User not found and could not be created' });
          return;
        }
        userData = inserted;
      }

      request.authUser = userData;
      request.supabaseUser = userClient;
      fastify.log.info({ userId: userData.id, email: userData.email, tier: userData.subscription_tier }, 'Authenticated request');
    } catch (error) {
      fastify.log.error({ err: error }, 'Auth error');
      reply.code(401).send({ error: 'Authentication failed' });
    }
  });
});
