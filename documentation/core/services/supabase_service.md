# supabase_service.dart

## What this file does
This file acts as the main toolbox for talking to our remote database server, Supabase. It uses the `Supabase.instance.client` command to get a direct telephone line to the database.

## Key Properties
- **`client`**: A shortcut getter. Whenever a completely different file wants to talk to Supabase to fetch or save something, it will ask for `SupabaseService.client` to quickly get access to the database connection.
