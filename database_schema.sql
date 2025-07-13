-- Fitflow Database Schema for Supabase
-- Run this SQL in your Supabase SQL Editor to set up all tables

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create custom types/enums
CREATE TYPE subscription_tier AS ENUM ('free', 'pro', 'lifetime');
CREATE TYPE fitness_level AS ENUM ('beginner', 'intermediate', 'advanced');
CREATE TYPE activity_type AS ENUM ('cardio', 'strength', 'yoga', 'hiit', 'pilates', 'running', 'cycling', 'swimming', 'dancing', 'sports');
CREATE TYPE equipment AS ENUM ('none', 'dumbbells', 'resistance_bands', 'kettlebells', 'pullup_bar', 'yoga_mat', 'full_gym');
CREATE TYPE workout_duration AS ENUM ('15-30', '30-45', '45-60', '60+');
CREATE TYPE workout_frequency AS ENUM ('1-2', '3-4', '5-6', '7');
CREATE TYPE dietary_restriction AS ENUM ('none', 'vegetarian', 'vegan', 'keto', 'paleo', 'gluten_free', 'dairy_free', 'low_carb', 'mediterranean', 'intermittent_fasting');
CREATE TYPE calorie_goal AS ENUM ('lose_weight', 'maintain', 'gain_weight', 'build_muscle');
CREATE TYPE meal_preference AS ENUM ('quick_and_easy', 'home_cooking', 'meal_prep', 'restaurant_style', 'comfort', 'international', 'healthy', 'budget');
CREATE TYPE cooking_skill AS ENUM ('beginner', 'intermediate', 'advanced');
CREATE TYPE meal_prep_time AS ENUM ('15', '30', '60', 'unlimited');
CREATE TYPE communication_style AS ENUM ('energetic', 'calm', 'tough', 'supportive', 'scientific', 'humorous');
CREATE TYPE reminder_frequency AS ENUM ('none', 'daily', 'weekdays', 'workout_days', 'custom');
CREATE TYPE motivation_trigger AS ENUM ('morning_boost', 'pre_workout', 'post_workout', 'plateau_breaker', 'goal_reminder', 'progress_celebration', 'bad_day_pickup');
CREATE TYPE preferred_time AS ENUM ('early_morning', 'morning', 'afternoon', 'evening', 'night');
CREATE TYPE goal_type AS ENUM ('weight_loss', 'weight_gain', 'muscle_gain', 'endurance', 'strength', 'flexibility', 'habit', 'performance');
CREATE TYPE activity_level AS ENUM ('sedentary', 'lightly_active', 'moderately_active', 'very_active', 'extremely_active');
CREATE TYPE muscle_group AS ENUM ('chest', 'back', 'shoulders', 'biceps', 'triceps', 'forearms', 'abs', 'obliques', 'lower_back', 'glutes', 'quadriceps', 'hamstrings', 'calves', 'full_body', 'cardio');
CREATE TYPE modification_type AS ENUM ('easier', 'harder', 'low_impact', 'no_equipment', 'injury');
CREATE TYPE meal_type AS ENUM ('breakfast', 'lunch', 'dinner', 'snack', 'preworkout', 'postworkout');
CREATE TYPE mood_rating AS ENUM ('terrible', 'poor', 'okay', 'good', 'excellent');
CREATE TYPE energy_level AS ENUM ('very_low', 'low', 'moderate', 'high', 'very_high');
CREATE TYPE difficulty_rating AS ENUM ('too_easy', 'easy', 'just_right', 'hard', 'too_hard');
CREATE TYPE satisfaction_rating AS ENUM ('hated', 'disliked', 'neutral', 'liked', 'loved');
CREATE TYPE message_role AS ENUM ('user', 'assistant', 'system');

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    subscription_tier subscription_tier DEFAULT 'free',
    preferences JSONB,
    health_profile JSONB,
    has_completed_onboarding BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Workout plans table
CREATE TABLE workout_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    difficulty_level fitness_level DEFAULT 'intermediate',
    estimated_duration INTEGER, -- in minutes
    target_muscle_groups muscle_group[],
    equipment equipment[],
    exercises JSONB NOT NULL, -- Array of exercise objects
    ai_generated_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Meal plans table
CREATE TABLE meal_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    target_calories INTEGER,
    macro_breakdown JSONB, -- {protein, carbs, fat, fiber}
    meals JSONB NOT NULL, -- Array of meal objects
    shopping_list TEXT[],
    prep_time INTEGER, -- in minutes
    ai_generated_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User progress table
CREATE TABLE user_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    log_date DATE NOT NULL,
    workout_completed BOOLEAN DEFAULT FALSE,
    workout_plan_id UUID REFERENCES workout_plans(id),
    exercises_completed JSONB, -- Array of exercise progress objects
    meals_logged JSONB, -- Array of meal progress objects
    body_metrics JSONB, -- {weight, body_fat_percentage, muscle_mass, measurements}
    mood mood_rating,
    energy_level energy_level,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, log_date)
);

-- Chat sessions table
CREATE TABLE chat_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    messages JSONB NOT NULL, -- Array of message objects
    session_type TEXT DEFAULT 'general',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Goals table (separate from user preferences for better tracking)
CREATE TABLE goals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    type goal_type NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    target_value DECIMAL,
    current_value DECIMAL DEFAULT 0,
    unit TEXT,
    target_date DATE,
    is_completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- AI usage tracking table
CREATE TABLE ai_usage (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    request_type TEXT NOT NULL, -- 'workout_generation', 'meal_generation', 'chat', etc.
    tokens_used INTEGER,
    cost_cents INTEGER, -- cost in cents
    request_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Subscription history table
CREATE TABLE subscription_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    subscription_tier subscription_tier NOT NULL,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ended_at TIMESTAMP WITH TIME ZONE,
    payment_method TEXT,
    amount_cents INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_subscription ON users(subscription_tier);
CREATE INDEX idx_workout_plans_user_id ON workout_plans(user_id);
CREATE INDEX idx_workout_plans_created_at ON workout_plans(created_at DESC);
CREATE INDEX idx_meal_plans_user_id ON meal_plans(user_id);
CREATE INDEX idx_meal_plans_created_at ON meal_plans(created_at DESC);
CREATE INDEX idx_user_progress_user_id ON user_progress(user_id);
CREATE INDEX idx_user_progress_date ON user_progress(log_date DESC);
CREATE INDEX idx_chat_sessions_user_id ON chat_sessions(user_id);
CREATE INDEX idx_goals_user_id ON goals(user_id);
CREATE INDEX idx_goals_completed ON goals(is_completed);
CREATE INDEX idx_ai_usage_user_date ON ai_usage(user_id, request_date);
CREATE INDEX idx_subscription_history_user_id ON subscription_history(user_id);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add updated_at triggers
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_workout_plans_updated_at BEFORE UPDATE ON workout_plans FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_meal_plans_updated_at BEFORE UPDATE ON meal_plans FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_goals_updated_at BEFORE UPDATE ON goals FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Row Level Security (RLS) policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE meal_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscription_history ENABLE ROW LEVEL SECURITY;

-- Users can only access their own data
CREATE POLICY "Users can view own profile" ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON users FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can view own workout plans" ON workout_plans FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own workout plans" ON workout_plans FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own workout plans" ON workout_plans FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own workout plans" ON workout_plans FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Users can view own meal plans" ON meal_plans FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own meal plans" ON meal_plans FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own meal plans" ON meal_plans FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own meal plans" ON meal_plans FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Users can view own progress" ON user_progress FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own progress" ON user_progress FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own progress" ON user_progress FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own progress" ON user_progress FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Users can view own chat sessions" ON chat_sessions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own chat sessions" ON chat_sessions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own chat sessions" ON chat_sessions FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can view own goals" ON goals FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own goals" ON goals FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own goals" ON goals FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own goals" ON goals FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Users can view own AI usage" ON ai_usage FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own AI usage" ON ai_usage FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own subscription history" ON subscription_history FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own subscription history" ON subscription_history FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Insert some sample data for testing (optional)
-- You can remove this section if you don't want sample data

-- Sample user (this will be created through your app's auth system)
-- INSERT INTO users (id, email, subscription_tier, has_completed_onboarding) 
-- VALUES ('550e8400-e29b-41d4-a716-446655440000', 'test@fitflow.app', 'free', true);

-- Functions for common queries
CREATE OR REPLACE FUNCTION get_user_daily_ai_usage(user_uuid UUID, check_date DATE DEFAULT CURRENT_DATE)
RETURNS INTEGER AS $$
BEGIN
    RETURN (
        SELECT COALESCE(COUNT(*), 0)
        FROM ai_usage
        WHERE user_id = user_uuid AND request_date = check_date
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_user_workout_streak(user_uuid UUID)
RETURNS INTEGER AS $$
DECLARE
    streak_count INTEGER := 0;
    check_date DATE := CURRENT_DATE;
BEGIN
    LOOP
        IF EXISTS (
            SELECT 1 FROM user_progress 
            WHERE user_id = user_uuid 
            AND log_date = check_date 
            AND workout_completed = true
        ) THEN
            streak_count := streak_count + 1;
            check_date := check_date - INTERVAL '1 day';
        ELSE
            EXIT;
        END IF;
    END LOOP;
    
    RETURN streak_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Fitflow database schema created successfully! 🎉';
    RAISE NOTICE 'Tables created: users, workout_plans, meal_plans, user_progress, chat_sessions, goals, ai_usage, subscription_history';
    RAISE NOTICE 'Row Level Security enabled for all tables';
    RAISE NOTICE 'Indexes and triggers configured';
    RAISE NOTICE 'Ready for your Fitflow app! 🚀';
END $$;