import { createClient } from '@supabase/supabase-js';
import { config } from '../config';

interface AIUsageLog {
  user_id: string;
  endpoint: string;
  model: string;
  prompt_tokens?: number;
  completion_tokens?: number;
  total_tokens?: number;
  cost_usd?: number;
  personalization_context?: string;
  request_metadata?: Record<string, any>;
  response_metadata?: Record<string, any>;
  created_at?: string;
}

export class AIUsageLogger {
  private supabase;

  constructor() {
    this.supabase = createClient(config.SUPABASE_URL, config.SUPABASE_ANON_KEY);
  }

  async logUsage(usage: AIUsageLog): Promise<void> {
    try {
      const { error } = await this.supabase
        .from('ai_usage')
        .insert({
          ...usage,
          created_at: new Date().toISOString()
        });

      if (error) {
        console.error('Failed to log AI usage:', error);
      }
    } catch (err) {
      console.error('AI usage logging error:', err);
    }
  }

  // Calculate cost estimates for Grok API
  static calculateGrokCost(promptTokens: number, completionTokens: number): number {
    // Grok pricing estimates (update with actual rates)
    const PROMPT_COST_PER_1K = 0.002; // $0.002 per 1K prompt tokens
    const COMPLETION_COST_PER_1K = 0.002; // $0.002 per 1K completion tokens
    
    const promptCost = (promptTokens / 1000) * PROMPT_COST_PER_1K;
    const completionCost = (completionTokens / 1000) * COMPLETION_COST_PER_1K;
    
    return promptCost + completionCost;
  }

  // Extract token usage from Grok response
  static extractTokenUsage(response: any): { promptTokens: number; completionTokens: number; totalTokens: number } {
    const usage = response.usage || {};
    return {
      promptTokens: usage.prompt_tokens || 0,
      completionTokens: usage.completion_tokens || 0,
      totalTokens: usage.total_tokens || 0
    };
  }

  // Create usage log from AI service call
  static createUsageLog(
    userId: string,
    endpoint: string,
    model: string,
    response: any,
    personalizationContext?: string,
    requestMetadata?: Record<string, any>
  ): AIUsageLog {
    const tokenUsage = this.extractTokenUsage(response);
    const cost = this.calculateGrokCost(tokenUsage.promptTokens, tokenUsage.completionTokens);

    const usageLog: AIUsageLog = {
      user_id: userId,
      endpoint,
      model,
      prompt_tokens: tokenUsage.promptTokens,
      completion_tokens: tokenUsage.completionTokens,
      total_tokens: tokenUsage.totalTokens,
      cost_usd: cost,
      response_metadata: {
        response_id: response.id,
        created: response.created,
        model: response.model
      }
    };

    if (personalizationContext) {
      usageLog.personalization_context = personalizationContext;
    }

    if (requestMetadata) {
      usageLog.request_metadata = requestMetadata;
    }

    return usageLog;
  }
}

export const aiUsageLogger = new AIUsageLogger();
