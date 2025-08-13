import 'dotenv/config';
import { z } from 'zod';

const configSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.coerce.number().default(3001),
  HOST: z.string().default('0.0.0.0'),
  
  // Supabase
  SUPABASE_URL: z.string().url(),
  SUPABASE_ANON_KEY: z.string(),
  SUPABASE_JWT_SECRET: z.string(),
  
  // AI Providers
  OPENAI_API_KEY: z.string().optional(),
  XAI_API_KEY: z.string().optional(),
  
  // Redis
  REDIS_URL: z.string().optional(),
  
  // Rate Limiting
  RATE_LIMIT_MAX: z.coerce.number().default(100),
  RATE_LIMIT_TIMEWINDOW: z.coerce.number().default(900000), // 15 minutes
  
  // AI Configuration
  AI_CACHE_TTL: z.coerce.number().default(3600), // 1 hour
  AI_TIMEOUT: z.coerce.number().default(30000), // 30 seconds
  AI_MAX_TOKENS: z.coerce.number().default(4096),
  
  // Logging
  LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace']).default('info')
});

function loadConfig() {
  const rawConfig = {
    NODE_ENV: process.env.NODE_ENV,
    PORT: process.env.PORT,
    HOST: process.env.HOST,
    SUPABASE_URL: process.env.SUPABASE_URL,
    SUPABASE_ANON_KEY: process.env.SUPABASE_ANON_KEY,
    SUPABASE_JWT_SECRET: process.env.SUPABASE_JWT_SECRET,
    OPENAI_API_KEY: process.env.OPENAI_API_KEY,
    XAI_API_KEY: process.env.XAI_API_KEY,
    REDIS_URL: process.env.REDIS_URL,
    RATE_LIMIT_MAX: process.env.RATE_LIMIT_MAX,
    RATE_LIMIT_TIMEWINDOW: process.env.RATE_LIMIT_TIMEWINDOW,
    AI_CACHE_TTL: process.env.AI_CACHE_TTL,
    AI_TIMEOUT: process.env.AI_TIMEOUT,
    AI_MAX_TOKENS: process.env.AI_MAX_TOKENS,
    LOG_LEVEL: process.env.LOG_LEVEL
  };

  const result = configSchema.safeParse(rawConfig);
  
  if (!result.success) {
    console.error('❌ Invalid configuration:', result.error.format());
    process.exit(1);
  }

  return result.data;
}

export const config = loadConfig();
export type Config = typeof config;
