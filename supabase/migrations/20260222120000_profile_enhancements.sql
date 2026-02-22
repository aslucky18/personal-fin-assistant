-- Add professional and personal data fields to user_profiles

ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS professional_salary NUMERIC DEFAULT 0,
ADD COLUMN IF NOT EXISTS salary_credit_date INTEGER, -- Day of month (1-31)
ADD COLUMN IF NOT EXISTS fixed_allowances NUMERIC DEFAULT 0,
ADD COLUMN IF NOT EXISTS job_title TEXT,
ADD COLUMN IF NOT EXISTS company_name TEXT,
ADD COLUMN IF NOT EXISTS gender TEXT,
ADD COLUMN IF NOT EXISTS date_of_birth DATE;

-- Since the user didn't specify exactly what personal data, 
-- I'm adding a flexible set of common fields.
