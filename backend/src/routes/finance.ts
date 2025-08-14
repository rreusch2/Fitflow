import { FastifyInstance } from 'fastify';
import { AIService } from '../services/ai';

export async function financeRoutes(server: FastifyInstance) {
  const aiService = new AIService();

  // POST /v1/finance/stock-analysis
  server.post('/finance/stock-analysis', async (request, reply) => {
    try {
      const body = (request.body as any) || {};
      const symbol: string = (body.symbol || '').toUpperCase();
      const analysisType: string = body.analysis_type || 'comprehensive';

      if (!symbol || symbol.length > 10) {
        return reply.code(400).send({ error: 'Invalid symbol' });
      }

      const result = await aiService.generateStockAnalysis({
        symbol,
        analysisType,
        // Note: We are not requiring auth context for now to simplify integration.
        // In production, you can enrich with user finance preferences via Supabase using request.authUser.id
      });

      return { analysis: result };
    } catch (err) {
      server.log.error({ err }, 'stock-analysis failed');
      return reply.code(500).send({ error: 'Failed to analyze stock' });
    }
  });
}
