-- Migration: Create Liabilities Table (Debt Manager)
-- Date: 2026-02-22

CREATE TABLE IF NOT EXISTS public.liabilities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    total_amount DECIMAL(12, 2) NOT NULL DEFAULT 0,
    paid_amount DECIMAL(12, 2) NOT NULL DEFAULT 0,
    interest_rate DECIMAL(5, 2) DEFAULT 0,
    due_date TIMESTAMPTZ,
    type TEXT DEFAULT 'loan', -- 'loan', 'credit_card', 'mortgage', etc.
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.liabilities ENABLE ROW LEVEL SECURITY;

-- Create Policies
CREATE POLICY "Users can view their own liabilities" 
    ON public.liabilities FOR SELECT 
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own liabilities" 
    ON public.liabilities FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own liabilities" 
    ON public.liabilities FOR UPDATE 
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own liabilities" 
    ON public.liabilities FOR DELETE 
    USING (auth.uid() = user_id);
