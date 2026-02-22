-- Migration: Create Financial Goals Table
-- Date: 2026-02-22

CREATE TABLE IF NOT EXISTS public.financial_goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    target_amount DECIMAL(12, 2) NOT NULL DEFAULT 0,
    current_amount DECIMAL(12, 2) NOT NULL DEFAULT 0,
    deadline TIMESTAMPTZ,
    icon TEXT DEFAULT 'flag',
    colour TEXT DEFAULT '#2196F3',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.financial_goals ENABLE ROW LEVEL SECURITY;

-- Create Policies
CREATE POLICY "Users can view their own goals" 
    ON public.financial_goals FOR SELECT 
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own goals" 
    ON public.financial_goals FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own goals" 
    ON public.financial_goals FOR UPDATE 
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own goals" 
    ON public.financial_goals FOR DELETE 
    USING (auth.uid() = user_id);
