# account.dart

## What this file does
This file creates the "Blueprint" for what an Account looks like in our app. Before we can show a Bank Account on the screen, Flutter needs to know exactly what pieces of information make up a Bank Account.

## Key Properties & Functions
- **`Account (Class)`**: The blueprint containing:
  - `id`: A unique database string label.
  - `userId`: Which user owns this account.
  - `bankName`: Text like "Chase" or "Bank of America".
  - `type`: Either "Checking" or "Savings" (or others).
  - `endsWith`: The last 4 digits of the account so the user can identify it.
  - `balance`: The actual amount of money in the account.
  - `createdAt`: When the account was added to the app.
- **`fromJson()`**: A factory that translates data downloaded from the Database (which arrives as a big messy Dictionary/JSON) into a neat `Account` object that Flutter can use.
- **`toJson()`**: The reverse. It packages our `Account` object back into a database-friendly dictionary to be uploaded to Supabase.
