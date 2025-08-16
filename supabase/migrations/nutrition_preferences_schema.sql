-- Migration for Nutrition Preferences and Enhanced Nutrition Tracking
-- This adds comprehensive nutrition preference management and quick-add functionality

-- Create nutrition preferences table
CREATE TABLE IF NOT EXISTS nutrition_preferences (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    dietary_restrictions TEXT[] DEFAULT '{}',
    preferred_cuisines TEXT[] DEFAULT '{}',
    disliked_foods TEXT[] DEFAULT '{}',
    meals_per_day INTEGER DEFAULT 3 CHECK (meals_per_day >= 2 AND meals_per_day <= 6),
    max_prep_time TEXT DEFAULT 'medium' CHECK (max_prep_time IN ('quick', 'medium', 'long', 'extended')),
    cooking_skill TEXT DEFAULT 'intermediate' CHECK (cooking_skill IN ('beginner', 'intermediate', 'advanced', 'expert')),
    include_snacks BOOLEAN DEFAULT true,
    meal_prep_friendly BOOLEAN DEFAULT false,
    budget_level TEXT DEFAULT 'moderate' CHECK (budget_level IN ('budget', 'moderate', 'premium', 'luxury')),
    prefer_local_seasonal BOOLEAN DEFAULT false,
    consider_workout_schedule BOOLEAN DEFAULT true,
    optimize_for_recovery BOOLEAN DEFAULT false,
    include_supplements BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id)
);

-- Add RLS policies for nutrition preferences
ALTER TABLE nutrition_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own nutrition preferences" ON nutrition_preferences
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own nutrition preferences" ON nutrition_preferences
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own nutrition preferences" ON nutrition_preferences
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own nutrition preferences" ON nutrition_preferences
    FOR DELETE USING (auth.uid() = user_id);

-- Create indexes for better performance
CREATE INDEX idx_nutrition_preferences_user_id ON nutrition_preferences(user_id);
CREATE INDEX idx_nutrition_preferences_updated_at ON nutrition_preferences(updated_at);

-- Enhance existing nutrition_logs table with source tracking
ALTER TABLE nutrition_logs 
ADD COLUMN IF NOT EXISTS source TEXT DEFAULT 'manual' CHECK (source IN ('manual', 'ai_suggestion', 'quick_add', 'meal_plan', 'barcode_scan'));

-- Add index for source filtering
CREATE INDEX IF NOT EXISTS idx_nutrition_logs_source ON nutrition_logs(source);

-- Create nutrition tips cache table for AI-generated tips
CREATE TABLE IF NOT EXISTS nutrition_tips_cache (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    tips JSONB NOT NULL,
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '24 hours'),
    context_hash TEXT, -- Hash of user's recent meals and goals for cache validation
    UNIQUE(user_id)
);

-- Add RLS policies for tips cache
ALTER TABLE nutrition_tips_cache ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own nutrition tips" ON nutrition_tips_cache
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own nutrition tips" ON nutrition_tips_cache
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own nutrition tips" ON nutrition_tips_cache
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own nutrition tips" ON nutrition_tips_cache
    FOR DELETE USING (auth.uid() = user_id);

-- Create index for tips cache
CREATE INDEX idx_nutrition_tips_user_id ON nutrition_tips_cache(user_id);
CREATE INDEX idx_nutrition_tips_expires_at ON nutrition_tips_cache(expires_at);

-- Create function to clean up expired tips
CREATE OR REPLACE FUNCTION cleanup_expired_nutrition_tips()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM nutrition_tips_cache WHERE expires_at < NOW();
END;
$$;

-- Create daily meal suggestions cache table
CREATE TABLE IF NOT EXISTS daily_meal_suggestions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    date DATE NOT NULL,
    suggestions JSONB NOT NULL,
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    preferences_hash TEXT, -- Hash of user preferences for cache invalidation
    goals_hash TEXT, -- Hash of nutrition goals for cache invalidation
    UNIQUE(user_id, date)
);

-- Add RLS policies for meal suggestions
ALTER TABLE daily_meal_suggestions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own meal suggestions" ON daily_meal_suggestions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own meal suggestions" ON daily_meal_suggestions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own meal suggestions" ON daily_meal_suggestions
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own meal suggestions" ON daily_meal_suggestions
    FOR DELETE USING (auth.uid() = user_id);

-- Create indexes for meal suggestions
CREATE INDEX idx_daily_meal_suggestions_user_date ON daily_meal_suggestions(user_id, date);
CREATE INDEX idx_daily_meal_suggestions_generated_at ON daily_meal_suggestions(generated_at);

-- Create function to get nutrition summary with enhanced aggregation
CREATE OR REPLACE FUNCTION get_nutrition_summary(
    p_user_id UUID,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE (
    total_calories NUMERIC,
    total_protein NUMERIC,
    total_carbs NUMERIC,
    total_fat NUMERIC,
    total_fiber NUMERIC,
    total_sugar NUMERIC,
    total_sodium NUMERIC,
    meal_count INTEGER,
    days_logged INTEGER,
    avg_calories_per_day NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(SUM(nl.calories), 0) as total_calories,
        COALESCE(SUM(nl.protein), 0) as total_protein,
        COALESCE(SUM(nl.carbs), 0) as total_carbs,
        COALESCE(SUM(nl.fat), 0) as total_fat,
        COALESCE(SUM(nl.fiber), 0) as total_fiber,
        COALESCE(SUM(nl.sugar), 0) as total_sugar,
        COALESCE(SUM(nl.sodium), 0) as total_sodium,
        COUNT(*)::INTEGER as meal_count,
        COUNT(DISTINCT nl.logged_date_utc)::INTEGER as days_logged,
        CASE 
            WHEN COUNT(DISTINCT nl.logged_date_utc) > 0 
            THEN COALESCE(SUM(nl.calories), 0) / COUNT(DISTINCT nl.logged_date_utc)
            ELSE 0
        END as avg_calories_per_day
    FROM nutrition_logs nl
    WHERE nl.user_id = p_user_id
    AND nl.logged_date_utc >= p_start_date
    AND nl.logged_date_utc <= p_end_date;
END;
$$;

-- Create function to get meal suggestions with fallback
CREATE OR REPLACE FUNCTION get_or_generate_meal_suggestions(
    p_user_id UUID,
    p_date DATE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    cached_suggestions JSONB;
BEGIN
    -- Try to get cached suggestions
    SELECT suggestions INTO cached_suggestions
    FROM daily_meal_suggestions
    WHERE user_id = p_user_id 
    AND date = p_date
    AND generated_at > NOW() - INTERVAL '12 hours'; -- Cache for 12 hours
    
    -- Return cached if found
    IF cached_suggestions IS NOT NULL THEN
        RETURN cached_suggestions;
    END IF;
    
    -- Return empty if no cache (will trigger AI generation in backend)
    RETURN '{"meals": [], "cached": false}'::JSONB;
END;
$$;

-- Create trigger function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add trigger for nutrition preferences
CREATE TRIGGER update_nutrition_preferences_updated_at 
    BEFORE UPDATE ON nutrition_preferences 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert default nutrition preferences for existing users (optional)
-- This can be run manually if needed:
-- INSERT INTO nutrition_preferences (user_id) 
-- SELECT id FROM auth.users 
-- WHERE id NOT IN (SELECT user_id FROM nutrition_preferences)
-- ON CONFLICT (user_id) DO NOTHING;

COMMENT ON TABLE nutrition_preferences IS 'User nutrition preferences for AI meal planning and suggestions';
COMMENT ON TABLE nutrition_tips_cache IS 'Cache for AI-generated personalized nutrition tips';
COMMENT ON TABLE daily_meal_suggestions IS 'Cache for AI-generated daily meal suggestions';
COMMENT ON FUNCTION get_nutrition_summary IS 'Get comprehensive nutrition summary for a date range';
COMMENT ON FUNCTION get_or_generate_meal_suggestions IS 'Get cached meal suggestions or indicate need for generation';
