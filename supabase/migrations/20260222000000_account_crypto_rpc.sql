-- Set a secret key for encryption (in a real app, use Supabase Vault)
ALTER DATABASE postgres SET app.encryption_key = 'finanalyzer-secret-key-2025';

-- Refresh the current session to load the new setting immediately
-- (Note: in a script, the setting is available to new sessions, but we'll use a fallback in the function just in case)

CREATE OR REPLACE FUNCTION public.add_account(
  p_bank_name TEXT,
  p_type TEXT,
  p_ends_with TEXT
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_secret TEXT;
  v_inserted_id UUID;
  v_result json;
BEGIN
  -- Get secret key
  v_secret := current_setting('app.encryption_key', true);
  IF v_secret IS NULL OR v_secret = '' THEN
    v_secret := 'finanalyzer-secret-key-2025'; -- Fallback for prototype
  END IF;

  INSERT INTO public.user_personal_accounts (
    user_id,
    bank_name,
    type,
    ends_with
  ) VALUES (
    auth.uid(),
    pgp_sym_encrypt(p_bank_name, v_secret),
    p_type,
    pgp_sym_encrypt(p_ends_with, v_secret)
  ) RETURNING id INTO v_inserted_id;

  SELECT json_build_object(
    'id', v_inserted_id,
    'user_id', auth.uid(),
    'bank_name', p_bank_name,
    'type', p_type,
    'ends_with', p_ends_with,
    'created_at', NOW()
  ) INTO v_result;

  RETURN v_result;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_accounts()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_secret TEXT;
  v_result json;
BEGIN
  v_secret := current_setting('app.encryption_key', true);
  IF v_secret IS NULL OR v_secret = '' THEN
    v_secret := 'finanalyzer-secret-key-2025';
  END IF;

  SELECT COALESCE(json_agg(
    json_build_object(
      'id', id,
      'user_id', user_id,
      'bank_name', pgp_sym_decrypt(bank_name, v_secret),
      'type', type,
      'ends_with', pgp_sym_decrypt(ends_with, v_secret),
      'created_at', created_at
    ) ORDER BY created_at DESC
  ), '[]'::json)
  INTO v_result
  FROM public.user_personal_accounts
  WHERE user_id = auth.uid();

  RETURN v_result;
END;
$$;
