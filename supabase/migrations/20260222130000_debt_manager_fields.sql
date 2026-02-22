-- Migration: Add missing fields to Liabilities Table (Debt Manager)
-- Date: 2026-02-22

-- Add monthly_payable, no_of_months, start_date fields to public.liabilities
ALTER TABLE public.liabilities
    ADD COLUMN monthly_payable DECIMAL(12, 2) NOT NULL DEFAULT 0,
    ADD COLUMN no_of_months INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN start_date TIMESTAMPTZ;
