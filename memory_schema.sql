-- Memory Feature Schema for Fitflow
-- Add this to your Supabase database

-- Create memory category enum
CREATE TYPE memory_category AS ENUM (
    'breakthrough',
    'goal_achieved',
    'personal_record',
    'mindset_shift',
    'habit_formed',
    'milestone',
    'insight',
    'motivation',
    'strategy',
    'custom'
);

-- User memories table
CREATE TABLE user_memories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    category memory_category DEFAULT 'insight',
    tags TEXT[],
    context JSONB, -- Store relevant context like workout/meal plan references
    emoji TEXT DEFAULT '💡', -- Visual identifier for the memory
    is_favorite BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_user_memories_user_id ON user_memories(user_id);
CREATE INDEX idx_user_memories_category ON user_memories(category);
CREATE INDEX idx_user_memories_created_at ON user_memories(created_at DESC);
CREATE INDEX idx_user_memories_is_favorite ON user_memories(is_favorite);

-- Enable Row Level Security (RLS)
ALTER TABLE user_memories ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view own memories" ON user_memories 
    FOR SELECT USING (auth.uid() = user_id);
    
CREATE POLICY "Users can create own memories" ON user_memories 
    FOR INSERT WITH CHECK (auth.uid() = user_id);
    
CREATE POLICY "Users can update own memories" ON user_memories 
    FOR UPDATE USING (auth.uid() = user_id);
    
CREATE POLICY "Users can delete own memories" ON user_memories 
    FOR DELETE USING (auth.uid() = user_id);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for updated_at
CREATE TRIGGER update_user_memories_updated_at 
    BEFORE UPDATE ON user_memories 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();
