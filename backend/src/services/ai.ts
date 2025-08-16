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

  async generateStockAnalysis(params: {
    symbol: string;
    analysisType?: string; // technical | fundamental | sentiment | comprehensive
  }) {
    const analysisType = params.analysisType || 'comprehensive';
    const prompt = this.buildFinanceStockPrompt(params.symbol, analysisType);
    const response = await this.callAI(prompt, 'finance-stock-analysis');

    // Expecting strict JSON from model; normalize to expected fields
    const now = new Date().toISOString();
    return {
      symbol: (response.symbol || params.symbol).toUpperCase(),
      analysisType: response.analysisType || analysisType,
      rating: response.rating || 'hold',
      targetPrice: response.targetPrice ?? null,
      reasoning: response.reasoning || 'No reasoning provided',
      keyPoints: Array.isArray(response.keyPoints) ? response.keyPoints : [],
      riskFactors: Array.isArray(response.riskFactors) ? response.riskFactors : [],
      timeframe: response.timeframe || '3-12 months',
      confidence: typeof response.confidence === 'number' ? response.confidence : 60,
      generatedAt: response.generatedAt || now
    };
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

  async generateDailyMealSuggestions(params: {
    userId: string;
    date: Date;
    preferences: any;
    nutritionGoals: any;
  }) {
    const prompt = this.buildDailyMealSuggestionsPrompt(params);
    const response = await this.callAI(prompt, 'daily-meal-suggestions');
    
    // Ensure we return structured meal suggestions for each meal type
    return {
      breakfast: response.breakfast || this.getDefaultMealSuggestion('breakfast'),
      lunch: response.lunch || this.getDefaultMealSuggestion('lunch'),
      dinner: response.dinner || this.getDefaultMealSuggestion('dinner'),
      snack: response.snack || this.getDefaultMealSuggestion('snack')
    };
  }

  async analyzeDiet(params: {
    userId: string;
    mealLogs: any[];
    nutritionGoals: any;
    preferences: any;
    daysBack: number;
  }) {
    const prompt = this.buildDietAnalysisPrompt(params);
    const response = await this.callAI(prompt, 'diet-analysis');
    
    return {
      overall_score: response.overall_score || 75,
      insights: response.insights || ['No specific insights available'],
      strengths: response.strengths || ['Consistent meal logging'],
      areas_for_improvement: response.areas_for_improvement || ['Consider increasing variety'],
      recommendations: response.recommendations || ['Continue tracking meals'],
      macro_analysis: response.macro_analysis || {
        protein: { current: 0, target: 0, status: 'unknown' },
        carbs: { current: 0, target: 0, status: 'unknown' },
        fat: { current: 0, target: 0, status: 'unknown' }
      },
      calorie_trends: response.calorie_trends || []
    };
  }

  async generateNutritionTips(params: {
    userId: string;
    nutritionGoals: any;
    recentLogs: any[];
    preferences: any;
  }) {
    const prompt = this.buildNutritionTipsPrompt(params);
    const response = await this.callAI(prompt, 'nutrition-tips');
    
    return response.tips || [
      {
        type: 'suggestion',
        icon: 'target',
        title: 'Daily Goal',
        content: 'Focus on meeting your protein targets to support muscle growth and recovery.'
      },
      {
        type: 'positive',
        icon: 'checkmark.circle.fill',
        title: 'Great Job!',
        content: 'You\'re doing well with consistent meal tracking. Keep it up!'
      },
      {
        type: 'tip',
        icon: 'lightbulb.fill',
        title: 'Pro Tip',
        content: 'Try meal prepping on Sundays to stay on track during busy weekdays.'
      }
    ];
  }

  async generateWeeklyMealPlan(params: {
    userId: string;
    startDate: Date;
    preferences: any;
    nutritionGoals: any;
  }) {
    const prompt = this.buildWeeklyMealPlanPrompt(params);
    const response = await this.callAI(prompt, 'weekly-meal-plan');
    
    return {
      id: randomUUID(),
      user_id: params.userId,
      title: response.title || 'Weekly Meal Plan',
      description: response.description || 'AI-generated weekly meal plan',
      target_calories: response.target_calories || 2000,
      macro_breakdown: response.macro_breakdown || { protein: 150, carbs: 200, fat: 65, fiber: 25 },
      meals: response.meals || [],
      shopping_list: response.shopping_list || [],
      prep_time: response.prep_time || 120,
      ai_generated_notes: response.notes || 'Personalized meal plan generated for optimal nutrition.',
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

  private buildDailyMealSuggestionsPrompt(params: any): string {
    return `You are a certified nutritionist. Generate personalized daily meal suggestions for ${params.date.toDateString()}.

User Profile:
- Nutrition Goals: ${JSON.stringify(params.nutritionGoals)}
- Preferences: ${JSON.stringify(params.preferences)}

Return STRICT JSON with breakfast, lunch, dinner, and snack objects. Each meal should have:
{
  "id": "uuid-string",
  "name": "Meal Name",
  "description": "Brief appetizing description",
  "calories": number,
  "macros": { "protein": number, "carbs": number, "fat": number, "fiber": number },
  "ingredients": [{
    "id": "uuid",
    "name": "ingredient name",
    "amount": number,
    "unit": "g/ml/cup",
    "calories": number,
    "macros": { "protein": number, "carbs": number, "fat": number, "fiber": number }
  }],
  "prep_time": number,
  "difficulty": "beginner",
  "tags": ["tag1", "tag2"]
}

Make meals realistic, achievable, and aligned with user goals. Focus on whole foods and balanced nutrition.`;
  }

  private buildDietAnalysisPrompt(params: any): string {
    return `You are a registered dietitian analyzing a client's eating patterns over the last ${params.daysBack} days.

Nutrition Goals: ${JSON.stringify(params.nutritionGoals)}
Meal Logs: ${JSON.stringify(params.mealLogs.slice(0, 50))}
User Preferences: ${JSON.stringify(params.preferences)}

Provide a comprehensive analysis as JSON with:
{
  "overall_score": number (0-100),
  "insights": ["key insight 1", "insight 2"],
  "strengths": ["strength 1", "strength 2"],
  "areas_for_improvement": ["area 1", "area 2"],
  "recommendations": ["specific actionable recommendation"],
  "macro_analysis": {
    "protein": { "current": number, "target": number, "status": "low/good/high" },
    "carbs": { "current": number, "target": number, "status": "low/good/high" },
    "fat": { "current": number, "target": number, "status": "low/good/high" }
  },
  "calorie_trends": [{ "date": "YYYY-MM-DD", "calories": number }]
}

Focus on practical, actionable insights that will help improve their nutrition.`;
  }

  private buildNutritionTipsPrompt(params: any): string {
    return `Generate 3 personalized nutrition tips based on user's current status.

Nutrition Goals: ${JSON.stringify(params.nutritionGoals)}
Recent Logs: ${JSON.stringify(params.recentLogs.slice(0, 10))}
Preferences: ${JSON.stringify(params.preferences)}

Return JSON with "tips" array containing objects with:
{
  "type": "suggestion|positive|tip|warning",
  "icon": "SF Symbol name",
  "title": "Short title",
  "content": "Actionable advice (max 100 characters)"
}

Make tips specific, actionable, and encouraging. Mix positive reinforcement with helpful suggestions.`;
  }

  private buildWeeklyMealPlanPrompt(params: any): string {
    return `Create a comprehensive 7-day meal plan starting ${params.startDate.toDateString()}.

User Profile:
- Nutrition Goals: ${JSON.stringify(params.nutritionGoals)}
- Preferences: ${JSON.stringify(params.preferences)}

Generate JSON with:
{
  "title": "Weekly Meal Plan - [Date Range]",
  "description": "Personalized weekly meal plan",
  "target_calories": daily target,
  "macro_breakdown": { "protein": g, "carbs": g, "fat": g, "fiber": g },
  "meals": {
    "monday": { "breakfast": meal_obj, "lunch": meal_obj, "dinner": meal_obj, "snack": meal_obj },
    // ... for each day of week
  },
  "shopping_list": ["ingredient 1", "ingredient 2"],
  "prep_time": total_minutes,
  "notes": "Helpful preparation and usage tips"
}

Ensure variety across days, balanced nutrition, and practical meal prep considerations.`;
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

  private buildFinanceStockPrompt(symbol: string, analysisType: string): string {
    return `You are a CFA charterholder-level financial analyst. Perform a ${analysisType} analysis of ${symbol}.
Return STRICT JSON only with keys: symbol, analysisType, rating, targetPrice, reasoning, keyPoints, riskFactors, timeframe, confidence, generatedAt.
Rules:
- rating must be one of [strong_buy, buy, hold, sell, strong_sell]
- analysisType must be one of [technical, fundamental, sentiment, comprehensive]
- timeframe is a short string like "1-3 months" or "3-12 months" or "1-5 years"
- confidence is 0-100 number
- keyPoints: array of 3-6 short bullets
- riskFactors: array of 2-5 concise risks
Example JSON shape:
{
  "symbol": "${symbol}",
  "analysisType": "${analysisType}",
  "rating": "buy",
  "targetPrice": 175.5,
  "reasoning": "Concise rationale integrating data across valuation, growth, profitability, and technicals.",
  "keyPoints": ["Point 1", "Point 2"],
  "riskFactors": ["Risk 1", "Risk 2"],
  "timeframe": "3-12 months",
  "confidence": 78,
  "generatedAt": "${new Date().toISOString()}"
}`;
  }

  private getDefaultMealSuggestion(mealType: string) {
    const suggestions: Record<string, any> = {
      breakfast: {
        id: randomUUID(),
        name: 'Greek Yogurt Parfait',
        description: 'High-protein parfait with berries and granola',
        calories: 420,
        macros: { protein: 30, carbs: 50, fat: 12, fiber: 6 },
        ingredients: [{
          id: randomUUID(),
          name: 'Greek Yogurt',
          amount: 200,
          unit: 'g',
          calories: 130,
          macros: { protein: 23, carbs: 8, fat: 0, fiber: 0 }
        }],
        prep_time: 5,
        difficulty: 'beginner',
        tags: ['high_protein', 'quick']
      },
      lunch: {
        id: randomUUID(),
        name: 'Chicken Rice Bowl',
        description: 'Balanced bowl with grilled chicken and vegetables',
        calories: 650,
        macros: { protein: 45, carbs: 70, fat: 18, fiber: 7 },
        ingredients: [{
          id: randomUUID(),
          name: 'Grilled Chicken',
          amount: 170,
          unit: 'g',
          calories: 280,
          macros: { protein: 50, carbs: 0, fat: 6, fiber: 0 }
        }],
        prep_time: 15,
        difficulty: 'beginner',
        tags: ['balanced', 'meal_prep']
      },
      dinner: {
        id: randomUUID(),
        name: 'Salmon & Vegetables',
        description: 'Omega-3 rich salmon with roasted vegetables',
        calories: 700,
        macros: { protein: 42, carbs: 55, fat: 30, fiber: 6 },
        ingredients: [{
          id: randomUUID(),
          name: 'Baked Salmon',
          amount: 170,
          unit: 'g',
          calories: 367,
          macros: { protein: 34, carbs: 0, fat: 25, fiber: 0 }
        }],
        prep_time: 25,
        difficulty: 'beginner',
        tags: ['omega3', 'whole_food']
      },
      snack: {
        id: randomUUID(),
        name: 'Apple & Almond Butter',
        description: 'Simple and satisfying snack',
        calories: 250,
        macros: { protein: 7, carbs: 24, fat: 14, fiber: 5 },
        ingredients: [{
          id: randomUUID(),
          name: 'Apple',
          amount: 182,
          unit: 'g',
          calories: 95,
          macros: { protein: 0, carbs: 25, fat: 0, fiber: 4 }
        }],
        prep_time: 3,
        difficulty: 'beginner',
        tags: ['snack', 'balanced']
      }
    };
    
    return suggestions[mealType] || suggestions.snack;
  }

  private getFallbackResponse(type: string): any {
    switch (type) {
      case 'workout-plan':
        return { title: 'Basic Workout', description: 'Simple workout plan', exercises: [], notes: 'Generated workout' };
      case 'meal-plan':
        return { title: 'Basic Meal Plan', description: 'Simple meal plan', meals: [], macro_breakdown: { protein: 150, carbs: 200, fat: 65, fiber: 25 }, shopping_list: [], notes: 'Generated meal plan' };
      case 'daily-meal-suggestions':
        return {
          breakfast: this.getDefaultMealSuggestion('breakfast'),
          lunch: this.getDefaultMealSuggestion('lunch'),
          dinner: this.getDefaultMealSuggestion('dinner'),
          snack: this.getDefaultMealSuggestion('snack')
        };
      case 'diet-analysis':
        return {
          overall_score: 75,
          insights: ['Continue tracking your meals consistently'],
          strengths: ['Good meal logging habits'],
          areas_for_improvement: ['Consider increasing vegetable intake'],
          recommendations: ['Aim for 5 servings of fruits and vegetables daily'],
          macro_analysis: {
            protein: { current: 0, target: 0, status: 'unknown' },
            carbs: { current: 0, target: 0, status: 'unknown' },
            fat: { current: 0, target: 0, status: 'unknown' }
          },
          calorie_trends: []
        };
      case 'nutrition-tips':
        return {
          tips: [
            { type: 'suggestion', icon: 'target', title: 'Daily Goal', content: 'Focus on meeting your protein targets to support muscle growth.' },
            { type: 'positive', icon: 'checkmark.circle.fill', title: 'Great Job!', content: 'You\'re doing well with consistent meal tracking.' },
            { type: 'tip', icon: 'lightbulb.fill', title: 'Pro Tip', content: 'Try meal prepping on Sundays for busy weekdays.' }
          ]
        };
      case 'weekly-meal-plan':
        return { title: 'Basic Weekly Plan', description: 'Simple weekly meal plan', meals: {}, macro_breakdown: { protein: 150, carbs: 200, fat: 65, fiber: 25 }, shopping_list: [], notes: 'Generated weekly meal plan' };
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
