# record.dart

## What this file does
This is the "Blueprint" for the core point of the entire app: A Financial Record (money entering or leaving).

## Key Properties & Functions
- **`FinancialRecord (Class)`**: The blueprint containing everything needed to glue the app together:
  - `id`: A unique database string label.
  - `userId`: Which user made the transaction.
  - `accountId`: *Which* bank account did this affect?
  - `categoryId`: *What* kind of spending was this?
  - `name`: Text from the user (e.g., "Starbucks Coffee").
  - `amount`: The money value.
  - `type`: "debit" (money lost) or "credit" (money gained).
  - `timestamp`: The exact date this transaction occurred according to the user.
  - `createdAt`: When it was saved to the server.
- **`fromJson()`**: Converts the dictionary from the database into the `FinancialRecord` object.
- **`toJson()`**: Converts the `FinancialRecord` object back into a database dictionary to be saved securely.
