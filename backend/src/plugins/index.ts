import { FastifyInstance } from 'fastify';
import { supabasePlugin } from './supabase';
import { authPlugin } from './auth';

export async function setupPlugins(server: FastifyInstance) {
  // Register Supabase client
  await server.register(supabasePlugin);
  
  // Register authentication middleware
  await server.register(authPlugin);
}
