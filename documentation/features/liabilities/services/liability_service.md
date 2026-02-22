# liability_service.dart

## What this file does
This service manages the connection between the Debt Manager and the Supabase database. It allows the app to save, retrieve, and remove debt records.

## Key Methods
- **`getLiabilities()`**: Fetches all active debts for the logged-in user.
- **`addLiability()`**: Adds a new debt entry to the database.
- **`updateLiability()`**: Updates details for an existing debt.
- **`deleteLiability()`**: Removes a debt record from the system.
