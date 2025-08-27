import { OpenAI } from 'openai';
import { config } from '../config';
import { randomUUID } from 'crypto';

export class AIService {
  private openai?: OpenAI;
  private xaiClient?: OpenAI;

  constructor() {
    if (config.OPENAI_API_KEY) {
      this.openai = new OpenAI({
        apiKey: config.OPENAI_API_KEY,
      });
    }

    if (config.XAI_API_KEY) {
      this.xaiClient = new OpenAI({
        apiKey: config.XAI_API_KEY,
        baseURL: 'https://api.x.ai/v1',
      });
    }
  }

  async generateWorkoutPlan(params: {
    userId: string;
    preferences: any;
    healthProfile: any;
    overrides: any;
  }) {
    const prompt = this.buildWorkoutPrompt(params);
    
    const response = await this.callAI(prompt, 'workout-plan');
    
    return {
      id: randomUUID(),
      user_id: params.userId,
      title: response.title || 'Custom Workout Plan',
      description: response.description || 'AI-generated workout plan',
      difficulty_level: params.overrides.difficulty_level || 'intermediate',
      estimated_duration: params.overrides.estimated_duration || 45,
      target_muscle_groups: params.overrides.target_muscle_groups || ['full_body'],
      equipment: params.overrides.equipment || ['none'],
      exercises: response.exercises || [],
      ai_generated_notes: response.notes,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };
  }

  async generateMealPlan(params: {
    userId: string;
    preferences: any;
    healthProfile: any;
    overrides: any;
  }) {
    const prompt = this.buildMealPrompt(params);
    
    const response = await this.callAI(prompt, 'meal-plan');
    
    return {
      id: randomUUID(),
      user_id: params.userId,
      title: response.title || 'Custom Meal Plan',
      description: response.description || 'AI-generated meal plan',
      target_calories: params.overrides.target_calories || 2000,
      macro_breakdown: response.macro_breakdown || { protein: 150, carbs: 200, fat: 65, fiber: 25 },
      meals: response.meals || [],
      shopping_list: response.shopping_list || [],
      prep_time: params.overrides.prep_time || 60,
      ai_generated_notes: response.notes,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };
  }

  async chatCompletion(params: {
    sessionId: string;
    userId: string;
    message: string;
    preferences: any;
  }) {
    const prompt = this.buildChatPrompt(params);
    
    const response = await this.callAI(prompt, 'chat');
    
    return {
      content: response.content || response,
      tokensIn: response.usage?.prompt_tokens || 0,
      tokensOut: response.usage?.completion_tokens || 0,
      provider: 'openai'
    };
  }

  async streamChatCompletion(params: {
    sessionId: string;
    userId: string;
    message: string;
    preferences: any;
    onToken: (token: string) => void;
  }) {
    // For now, return non-streamed response
    // In production, implement actual streaming
    const response = await this.chatCompletion(params);
    
    // Simulate streaming by sending chunks
    const words = response.content.split(' ');
    for (const word of words) {
      params.onToken(word + ' ');
      await new Promise(resolve => setTimeout(resolve, 50));
    }
    
    return response;
  }

  async generateDailyFeed(params: {
    userId: string;
    date: Date;
    preferences: any;
  }) {
    const prompt = this.buildFeedPrompt(params);
    
    const response = await this.callAI(prompt, 'feed');
    
    return (response.items || []).map((item: any) => ({
      id: randomUUID(),
      kind: item.kind || 'quote',
      title: item.title,
      text: item.text,
      image_url: item.image_url,
      topic_tags: item.topic_tags || [],
      style: item.style,
      created_at: new Date().toISOString()
    }));
  }

  async analyzeProgress(params: {
    userId: string;
    entries: any[];
    preferences: any;
    goals: any[];
  }) {
    const prompt = this.buildProgressPrompt(params);
    
    const response = await this.callAI(prompt, 'progress');
    
    return {
      trends: response.trends || [],
      summary: response.summary || 'No analysis available',
      recommendations: response.recommendations || []
    };
  }

  private async callAI(prompt: string, type: string): Promise<any> {
    try {
      // Try XAI first if available
      if (this.xaiClient) {
        const response = await this.xaiClient.chat.completions.create({
          model: 'grok-3',
          messages: [{ role: 'user', content: prompt }],
          max_tokens: config.AI_MAX_TOKENS,
          temperature: 0.7,
        });
        
        return JSON.parse(response.choices[0]?.message?.content || '{}');
      }
      
      // Fallback to OpenAI
      if (this.openai) {
        const response = await this.openai.chat.completions.create({
          model: 'gpt-4',
          messages: [{ role: 'user', content: prompt }],
          max_tokens: config.AI_MAX_TOKENS,
          temperature: 0.7,
        });
        
        return JSON.parse(response.choices[0]?.message?.content || '{}');
      }
      
      throw new Error('No AI provider available');
    } catch (error) {
      console.error(`AI call failed for ${type}:`, error);
      return this.getFallbackResponse(type);
    }
  }

  private buildWorkoutPrompt(params: any): string {
    return `Generate a workout plan as JSON with title, description, exercises array, and notes. 
    User preferences: ${JSON.stringify(params.preferences)}
    Overrides: ${JSON.stringify(params.overrides)}`;
  }

  private buildMealPrompt(params: any): string {
    return `Generate a meal plan as JSON with title, description, meals array, macro_breakdown, shopping_list, and notes.
    User preferences: ${JSON.stringify(params.preferences)}
    Overrides: ${JSON.stringify(params.overrides)}`;
  }

  private buildChatPrompt(params: any): string {
    return `You are a fitness coach. Respond helpfully to the user's message.
    Return a strict JSON object with the shape: { "content": string } and nothing else.
    Message: "${params.message}"
    User preferences: ${JSON.stringify(params.preferences)}`;
  }

  private buildFeedPrompt(params: any): string {
    return `Generate 3 motivational feed items as JSON array with items containing kind, title, text, topic_tags.
    Date: ${params.date.toISOString()}
    User preferences: ${JSON.stringify(params.preferences)}`;
  }

  private buildProgressPrompt(params: any): string {
    return `Analyze progress data and provide JSON with trends array, summary string, and recommendations array.
    Entries: ${JSON.stringify(params.entries.slice(0, 10))}
    Goals: ${JSON.stringify(params.goals)}`;
  }

  private getFallbackResponse(type: string): any {
    switch (type) {
      case 'workout-plan':
        return { title: 'Basic Workout', description: 'Simple workout plan', exercises: [], notes: 'Generated workout' };
      case 'meal-plan':
        return { title: 'Basic Meal Plan', description: 'Simple meal plan', meals: [], macro_breakdown: { protein: 150, carbs: 200, fat: 65, fiber: 25 }, shopping_list: [], notes: 'Generated meal plan' };
      case 'chat':
        return { content: 'I apologize, but I\'m having trouble processing your request right now. Please try again later.' };
      case 'feed':
        return { items: [{ kind: 'quote', text: 'Stay motivated and keep moving forward!', topic_tags: ['motivation'] }] };
      case 'progress':
        return { trends: [], summary: 'Progress analysis unavailable', recommendations: [] };
      default:
        return {};
    }
  }
}
