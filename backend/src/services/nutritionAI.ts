import { v4 } from 'uuid';
import { config } from '../config';

interface UserContext {
  userId: string;
  preferences?: any;
  nutritionGoals?: any;
  healthProfile?: any;
}

interface DailySuggestionsParams extends UserContext {
  date: Date;
}

interface WeeklyMealPlanParams extends UserContext {
  startDate: Date;
}

interface DietAnalysisParams extends UserContext {
  mealLogs: any[];
  days: number;
}

interface PersonalizedTipsParams extends UserContext {
  recentMealLogs: any[];
}

export class NutritionAIService {
  private grokApiKey: string;
  private grokBaseUrl: string;

  constructor() {
    if (!config.ai) {
      throw new Error('AI configuration is missing');
    }
    this.grokApiKey = config.ai.apiKey;
    this.grokBaseUrl = config.ai.baseUrl;
  }

  async generateDailySuggestions(params: DailySuggestionsParams) {
    const prompt = this.buildDailySuggestionsPrompt(params);
    
    const response = await this.callGrokAPI(prompt, {
      maxTokens: 2000,
      temperature: 0.7
    });

    const suggestions = this.parseMealSuggestions(response);
    
    return {
      suggestions,
      tokensUsed: response.usage?.total_tokens || 0,
      costCents: this.calculateCost(response.usage?.total_tokens || 0)
    };
  }

  async generateWeeklyMealPlan(params: WeeklyMealPlanParams) {
    const prompt = this.buildWeeklyMealPlanPrompt(params);
    
    const response = await this.callGrokAPI(prompt, {
      maxTokens: 3000,
      temperature: 0.6
    });

    return this.parseWeeklyMealPlan(response);
  }

  async analyzeDiet(params: DietAnalysisParams) {
    const prompt = this.buildDietAnalysisPrompt(params);
    
    const response = await this.callGrokAPI(prompt, {
      maxTokens: 1500,
      temperature: 0.3
    });

    return this.parseDietAnalysis(response);
  }

  async generatePersonalizedTips(params: PersonalizedTipsParams) {
    const prompt = this.buildPersonalizedTipsPrompt(params);
    
    const response = await this.callGrokAPI(prompt, {
      maxTokens: 800,
      temperature: 0.7
    });

    return this.parseNutritionTips(response);
  }

  private buildDailySuggestionsPrompt(params: DailySuggestionsParams): string {
    const { nutritionGoals, preferences, healthProfile } = params;
    
    return `As a registered dietitian, create 4 personalized meal suggestions (breakfast, lunch, dinner, snack) for today.

User Context:
- Target Calories: ${nutritionGoals?.target_calories || 2000}/day
- Protein Goal: ${nutritionGoals?.target_macros?.protein || 'moderate'}g
- Carbs Goal: ${nutritionGoals?.target_macros?.carbs || 'moderate'}g  
- Fat Goal: ${nutritionGoals?.target_macros?.fat || 'moderate'}g
- Diet Type: ${nutritionGoals?.diet_preferences?.diet_type || 'balanced'}
- Allergies: ${nutritionGoals?.exclusions?.join(', ') || 'none'}
- Age: ${healthProfile?.age || 'adult'}
- Activity Level: ${preferences?.fitness?.level || 'moderate'}

Requirements:
- Each meal should be practical and easy to prepare
- Include accurate calorie and macro estimates
- Provide 2-3 ingredient alternatives per meal
- Include brief cooking instructions
- Consider user's dietary restrictions

Return JSON format:
{
  "suggestions": [
    {
      "id": "uuid",
      "type": "breakfast|lunch|dinner|snack",
      "name": "Meal Name",
      "description": "Brief description",
      "calories": 400,
      "macros": {"protein": 25, "carbs": 45, "fat": 12, "fiber": 8},
      "ingredients": [
        {
          "id": "uuid",
          "name": "Ingredient name",
          "amount": 100,
          "unit": "g",
          "calories": 150,
          "macros": {"protein": 20, "carbs": 5, "fat": 8, "fiber": 2},
          "isOptional": false,
          "substitutes": ["Alternative 1", "Alternative 2"]
        }
      ],
      "instructions": ["Step 1", "Step 2"],
      "prepTime": 10,
      "cookTime": 5,
      "tags": ["high_protein", "quick"]
    }
  ]
}`;
  }

  private buildWeeklyMealPlanPrompt(params: WeeklyMealPlanParams): string {
    const { nutritionGoals, preferences } = params;
    
    return `Create a comprehensive 7-day meal plan with shopping list and prep notes.

User Requirements:
- Daily Calories: ${nutritionGoals?.target_calories || 2000}
- Diet Type: ${nutritionGoals?.diet_preferences?.diet_type || 'balanced'}
- Prep Time Preference: ${preferences?.prepTimePreference || 30} minutes max
- Meal Count: ${preferences?.mealCount || 3} meals + 1 snack per day
- Cuisine Preferences: ${preferences?.cuisinePreferences?.join(', ') || 'varied'}
- Dislikes: ${preferences?.dislikes?.join(', ') || 'none'}

Return comprehensive meal plan with:
- 7 days of complete meals
- Shopping list organized by category
- Meal prep tips and batch cooking suggestions
- Cost estimates where possible
- Nutritional balance across the week

Format as detailed JSON with all meal information, shopping items, and prep instructions.`;
  }

  private buildDietAnalysisPrompt(params: DietAnalysisParams): string {
    const { mealLogs, nutritionGoals, days } = params;
    
    const totalCalories = mealLogs.reduce((sum, log) => sum + (log.totals?.calories || 0), 0);
    const avgCalories = totalCalories / Math.max(days, 1);
    const totalProtein = mealLogs.reduce((sum, log) => sum + (log.totals?.protein || 0), 0);
    const avgProtein = totalProtein / Math.max(days, 1);
    
    return `Analyze this user's ${days}-day nutrition data and provide insights.

Nutrition Data Summary:
- Average Daily Calories: ${avgCalories.toFixed(0)}
- Average Daily Protein: ${avgProtein.toFixed(1)}g
- Total Meals Logged: ${mealLogs.length}
- Target Calories: ${nutritionGoals?.target_calories || 2000}
- Target Protein: ${nutritionGoals?.target_macros?.protein || 'not set'}g

Goals:
${JSON.stringify(nutritionGoals, null, 2)}

Recent Meal Patterns:
${mealLogs.slice(0, 10).map(log => 
  `${log.meal_type}: ${log.totals?.calories || 0} cal, ${log.totals?.protein || 0}g protein`
).join('\n')}

Provide analysis with:
1. Overall assessment (score 1-100)
2. Macro trend analysis
3. 3-5 key insights about eating patterns
4. Prioritized recommendations for improvement
5. Positive reinforcement for good habits

Return structured JSON with clear, actionable insights.`;
  }

  private buildPersonalizedTipsPrompt(params: PersonalizedTipsParams): string {
    const { recentMealLogs, nutritionGoals, preferences } = params;
    
    return `Generate 3-4 personalized nutrition tips for this user based on their recent eating patterns.

User Context:
- Recent meals logged: ${recentMealLogs.length}
- Goal calories: ${nutritionGoals?.target_calories || 'not set'}
- Diet preferences: ${JSON.stringify(nutritionGoals?.diet_preferences)}

Recent Eating Pattern:
${recentMealLogs.slice(0, 5).map(log => 
  `${log.meal_type}: ${log.totals?.calories || 0} cal`
).join('\n')}

Create tips that are:
- Actionable and specific
- Based on actual eating patterns
- Encouraging and positive
- Varied in type (nutritional, behavioral, timing)

Return JSON array of tips with type, title, description, icon, priority, and actionable flag.`;
  }

  private async callGrokAPI(prompt: string, options: { maxTokens: number; temperature: number }) {
    const response = await fetch(`${this.grokBaseUrl}/chat/completions`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${this.grokApiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model: 'grok-beta',
        messages: [
          {
            role: 'system',
            content: 'You are a certified nutritionist and registered dietitian with expertise in personalized meal planning, nutrition analysis, and dietary coaching. Always respond with valid JSON when requested and provide evidence-based recommendations.'
          },
          {
            role: 'user',
            content: prompt
          }
        ],
        temperature: options.temperature,
        max_tokens: options.maxTokens
      })
    });

    if (!response.ok) {
      throw new Error(`Grok API error: ${response.status} ${response.statusText}`);
    }

    const data = await response.json();
    return {
      content: (data as any).choices[0].message.content,
      usage: (data as any).usage
    };
  }

  private parseMealSuggestions(response: any) {
    try {
      const content = response.content;
      const jsonMatch = content.match(/\{[\s\S]*\}/);
      if (!jsonMatch) throw new Error('No JSON found in response');
      
      const parsed = JSON.parse(jsonMatch[0]);
      return parsed.suggestions || [];
    } catch (error) {
      console.error('Error parsing meal suggestions:', error);
      // Return fallback suggestions
      return this.getFallbackMealSuggestions();
    }
  }

  private parseWeeklyMealPlan(response: any) {
    try {
      const content = response.content;
      const jsonMatch = content.match(/\{[\s\S]*\}/);
      if (!jsonMatch) throw new Error('No JSON found in response');
      
      const parsed = JSON.parse(jsonMatch[0]);
      
      return {
        id: v4(),
        title: parsed.title || 'Weekly Meal Plan',
        description: parsed.description || 'AI-generated meal plan',
        targetCalories: parsed.targetCalories || 2000,
        macroBreakdown: parsed.macroBreakdown || {},
        meals: parsed.meals || {},
        shoppingList: parsed.shoppingList || [],
        prepTime: parsed.prepTime || 120,
        aiGeneratedNotes: parsed.prepNotes || 'Follow meal prep instructions for best results.',
        ...parsed
      };
    } catch (error) {
      console.error('Error parsing weekly meal plan:', error);
      return this.getFallbackWeeklyPlan();
    }
  }

  private parseDietAnalysis(response: any) {
    try {
      const content = response.content;
      const jsonMatch = content.match(/\{[\s\S]*\}/);
      if (!jsonMatch) throw new Error('No JSON found in response');
      
      return JSON.parse(jsonMatch[0]);
    } catch (error) {
      console.error('Error parsing diet analysis:', error);
      return this.getFallbackDietAnalysis();
    }
  }

  private parseNutritionTips(response: any) {
    try {
      const content = response.content;
      const jsonMatch = content.match(/\[[\s\S]*\]/) || content.match(/\{[\s\S]*\}/);
      if (!jsonMatch) throw new Error('No JSON found in response');
      
      const parsed = JSON.parse(jsonMatch[0]);
      return Array.isArray(parsed) ? parsed : (parsed.tips || []);
    } catch (error) {
      console.error('Error parsing nutrition tips:', error);
      return this.getFallbackNutritionTips();
    }
  }

  private calculateCost(tokens: number): number {
    // Estimate cost in cents (Grok pricing approximately $5 per 1M tokens)
    return Math.ceil((tokens / 1000000) * 500);
  }

  // Fallback methods for when AI parsing fails
  private getFallbackMealSuggestions() {
    return [
      {
        id: v4(),
        type: 'breakfast',
        name: 'Greek Yogurt Bowl',
        description: 'High-protein breakfast with berries and granola',
        calories: 350,
        macros: { protein: 25, carbs: 40, fat: 10, fiber: 6 },
        ingredients: [
          {
            id: v4(),
            name: 'Greek Yogurt',
            amount: 200,
            unit: 'g',
            calories: 150,
            macros: { protein: 20, carbs: 10, fat: 0, fiber: 0 },
            isOptional: false,
            substitutes: ['Skyr', 'Regular yogurt']
          }
        ],
        instructions: ['Mix yogurt with toppings', 'Enjoy immediately'],
        prepTime: 5,
        cookTime: 0,
        tags: ['high_protein', 'quick']
      }
    ];
  }

  private getFallbackWeeklyPlan() {
    return {
      id: v4(),
      title: 'Balanced Weekly Plan',
      description: 'Simple, nutritious meals for the week',
      targetCalories: 2000,
      macroBreakdown: { protein: 150, carbs: 200, fat: 65 },
      meals: {},
      shoppingList: [],
      prepTime: 120,
      aiGeneratedNotes: 'Plan your meals ahead for success.'
    };
  }

  private getFallbackDietAnalysis() {
    return {
      period: '7 days',
      overview: 'Analysis based on recent eating patterns',
      macroTrends: {
        averageCalories: 1800,
        proteinTrend: 'stable',
        carbsTrend: 'stable',
        fatTrend: 'stable',
        fiberAverage: 25
      },
      insights: [
        {
          type: 'tip',
          title: 'Stay Consistent',
          description: 'Keep logging meals for better insights',
          impact: 'positive'
        }
      ],
      recommendations: [
        {
          priority: 'medium',
          action: 'Log more meals',
          reason: 'Better tracking leads to better insights',
          expectedBenefit: 'More personalized recommendations'
        }
      ],
      score: 75
    };
  }

  private getFallbackNutritionTips() {
    return [
      {
        id: v4(),
        type: 'tip',
        title: 'Stay Hydrated',
        description: 'Aim for 8 glasses of water daily for optimal health',
        icon: 'drop.fill',
        priority: 'medium',
        actionable: true
      },
      {
        id: v4(),
        type: 'suggestion',
        title: 'Add More Protein',
        description: 'Include protein in every meal to support muscle health',
        icon: 'figure.strengthtraining.traditional',
        priority: 'high',
        actionable: true
      }
    ];
  }
}
