// Shared personalization context builder
// Maps user motivations into 5 archetypes and produces a concise text context

export type MotivationKey = 'aesthetics' | 'performance' | 'weight_management' | 'longevity' | 'mindset';

const ARCHETYPES: MotivationKey[] = [
  'aesthetics',
  'performance',
  'weight_management',
  'longevity',
  'mindset',
];

// Simple keyword map to collapse raw labels into archetypes
const KEYWORD_TO_ARCHETYPE: Record<string, MotivationKey> = {
  aesthetics: 'aesthetics',
  appearance: 'aesthetics',
  hypertrophy: 'aesthetics',
  tone: 'aesthetics',
  confidence: 'aesthetics',

  performance: 'performance',
  strength: 'performance',
  endurance: 'performance',
  athleticism: 'performance',
  pr: 'performance',

  weight: 'weight_management',
  fat_loss: 'weight_management',
  cutting: 'weight_management',
  recomposition: 'weight_management',
  recomp: 'weight_management',
  metabolic: 'weight_management',

  longevity: 'longevity',
  health: 'longevity',
  mobility: 'longevity',
  injury: 'longevity',
  sleep: 'longevity',
  biomarkers: 'longevity',

  mindset: 'mindset',
  stress: 'mindset',
  mindfulness: 'mindset',
  consistency: 'mindset',
  accountability: 'mindset',
  fun: 'mindset',
};

function toLabel(s: string): string {
  return s.trim().toLowerCase().replace(/\s+/g, '_');
}

function normalizeWeights(raw: any): Record<MotivationKey, number> {
  const weights: Record<MotivationKey, number> = {
    aesthetics: 0,
    performance: 0,
    weight_management: 0,
    longevity: 0,
    mindset: 0,
  };

  if (!raw) {
    // default light balance toward adherence/mindset
    weights.mindset = 0.4;
    weights.weight_management = 0.3;
    weights.aesthetics = 0.2;
    weights.longevity = 0.1;
  } else if (Array.isArray(raw)) {
    // assume top N selections ordered by priority
    const top = raw.map((x) => toLabel(String(x))).map((k) => KEYWORD_TO_ARCHETYPE[k] ?? undefined).filter(Boolean) as MotivationKey[];
    if (top.length === 1) {
      weights[top[0]] = 1.0;
    } else if (top.length >= 2) {
      // simple 0.7/0.3 split for top-2
      weights[top[0]] = 0.7;
      weights[top[1]] = 0.3;
      if (top.length >= 3) {
        // bleed tiny weight to third
        const bleed = 0.1;
        weights[top[0]] -= bleed / 2;
        weights[top[1]] -= bleed / 2;
        weights[top[2]] += bleed;
      }
    }
  } else if (typeof raw === 'object') {
    // if already provided as weight map
    const entries = Object.entries(raw as Record<string, number>);
    for (const [k, v] of entries) {
      const mapped = KEYWORD_TO_ARCHETYPE[toLabel(k)] || (ARCHETYPES as string[]).includes(k) ? (k as MotivationKey) : undefined;
      if (mapped && typeof v === 'number' && v > 0) weights[mapped] += v;
    }
  }

  // normalize to sum=1 if any positive
  const sum = Object.values(weights).reduce((a, b) => a + b, 0);
  if (sum > 0) {
    (Object.keys(weights) as MotivationKey[]).forEach((k) => (weights[k] = Number((weights[k] / sum).toFixed(3))));
  }

  return weights;
}

function deriveBiases(weights: Record<MotivationKey, number>) {
  const hints: string[] = [];
  const w = weights;
  if (w.weight_management >= 0.25) {
    hints.push(
      '- Weight Management: prefer modest calorie deficit when goal is loss; high protein; simple, adherence-first meals; avoid overly complex recipes on weekdays.'
    );
  }
  if (w.performance >= 0.25) {
    hints.push(
      '- Performance: support training blocks with adequate carbs around sessions; ensure protein distribution; include convenient performance snacks.'
    );
  }
  if (w.aesthetics >= 0.25) {
    hints.push(
      '- Aesthetics: emphasize protein targets and fiber for satiety; keep calories consistent day-to-day; include variety to avoid palate fatigue.'
    );
  }
  if (w.longevity >= 0.25) {
    hints.push(
      '- Longevity: prioritize micronutrient-dense foods, Omega-3 sources, adequate fiber; include mobility/recovery-friendly timing suggestions.'
    );
  }
  if (w.mindset >= 0.25) {
    hints.push(
      '- Mindset/Stress: prefer quick, low-friction options; suggest batch-cook strategies; minimize decision fatigue with templated meals.'
    );
  }
  return hints;
}

export function buildPersonalizationContext(input: {
  motivations?: any; // array or weight map
  preferences?: any; // user preferences JSON
  nutritionGoals?: any; // nutrition goals JSON
  healthProfile?: any; // health profile JSON
}): string {
  const weights = normalizeWeights(input.motivations ?? input.preferences?.motivation);

  const lines: string[] = [];
  lines.push('Motivation Weights (normalized 0-1):');
  (ARCHETYPES as MotivationKey[]).forEach((k) => {
    lines.push(`- ${k}: ${weights[k] ?? 0}`);
  });

  // Derive concise behavioral biases
  const biases = deriveBiases(weights);
  if (biases.length) {
    lines.push('Guidance:');
    lines.push(...biases);
  }

  // Optional: include select goal constraints
  if (input.nutritionGoals?.target_calories) {
    lines.push(`Target Calories: ${input.nutritionGoals.target_calories}`);
  }
  if (input.nutritionGoals?.diet_preferences) {
    lines.push(`Diet Prefs: ${JSON.stringify(input.nutritionGoals.diet_preferences)}`);
  }

  return lines.join('\n');
}
