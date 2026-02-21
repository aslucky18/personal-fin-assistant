# account_service.dart

## What this file does
This acts as the "Plumbing" for our Accounts. It is responsible for making the actual network calls to Supabase to save a new Account or download a list of existing Accounts.

## Key Functions
- **`addAccount(Account account)`**: Takes the Blueprint `Account` object, packages it, and sends it to a special Postgres routine (an RPC called `add_account_securely`) to securely save and encrypt the bank details on the backend.
- **`getAccounts()`**: Contacts the Supabase `get_accounts_decrypted` RPC to download all the user's accounts, decrypts their balances and strings, and returns them as a List of `Account` blueprints so the UI can draw them.
