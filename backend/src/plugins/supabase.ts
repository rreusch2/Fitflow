import fp from 'fastify-plugin';
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { config } from '../config';

declare module 'fastify' {
  interface FastifyInstance {
    supabase: SupabaseClient;
  }
}

export const supabasePlugin = fp(async (fastify) => {
  const supabase = createClient(
    config.SUPABASE_URL,
    config.SUPABASE_ANON_KEY,
    {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
        detectSessionInUrl: false
      }
    }
  );

  fastify.decorate('supabase', supabase);
  
  fastify.log.info('✅ Supabase client initialized');
});
