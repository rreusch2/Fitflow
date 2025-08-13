import Fastify from 'fastify';
import cors from '@fastify/cors';
import jwt from '@fastify/jwt';
import rateLimit from '@fastify/rate-limit';
import { config } from './config';
import { setupRoutes } from './routes';
import { setupPlugins } from './plugins';

const server = Fastify({
  logger: {
    level: config.LOG_LEVEL,
    transport: {
      target: 'pino-pretty',
      options: {
        colorize: true,
        translateTime: 'HH:MM:ss Z',
        ignore: 'pid,hostname'
      }
    }
  }
});

async function start() {
  try {
    // Register CORS
    await server.register(cors, {
      origin: true, // Allow all origins in development
      credentials: true
    });

    // Register JWT
    await server.register(jwt, {
      secret: config.SUPABASE_JWT_SECRET
    });

    // Register rate limiting
    await server.register(rateLimit, {
      max: config.RATE_LIMIT_MAX,
      timeWindow: config.RATE_LIMIT_TIMEWINDOW
    });

    // Setup custom plugins
    await setupPlugins(server);

    // Setup routes
    await setupRoutes(server);

    // Health check endpoint
    server.get('/health', async () => {
      return { 
        status: 'healthy', 
        timestamp: new Date().toISOString(),
        version: '1.0.0'
      };
    });

    // Start the server
    const address = await server.listen({ 
      port: config.PORT, 
      host: config.HOST 
    });
    
    server.log.info(`🚀 Fitflow Backend API running at ${address}`);
    server.log.info(`📊 Health check available at ${address}/health`);

  } catch (err) {
    server.log.error(err);
    process.exit(1);
  }
}

// Handle graceful shutdown
const signals = ['SIGINT', 'SIGTERM'];
signals.forEach(signal => {
  process.on(signal, async () => {
    server.log.info(`Received ${signal}, closing server...`);
    await server.close();
    process.exit(0);
  });
});

start();
