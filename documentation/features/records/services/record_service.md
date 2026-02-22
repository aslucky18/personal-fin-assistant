# record_service.dart

## What this file does
The super-heavy-lifting plumber. It saves every transaction, and more importantly, it handles all the Math to make sure Bank Balances are always perfectly up-to-date.

## Key Functions
- **`addRecord(FinancialRecord record)`**: 
  - Takes a new Record, encrypts its data securely, and saves it to the database table via an RPC call.
  - *Magic Trick*: Along with saving the transaction, the database RPC routine simultaneously looks at the attached Bank Account. For an "Income" record, it *adds* the money to the bank account balance. For an "Expense" record, it *subtracts* the money from the bank account balance. All of this happens instantly and securely on the backend.
- **`updateRecord()`**: Modifies an existing financial record in the database.
- **`getRecords()`**: Calls the `get_records_decrypted` RPC to fetch the 50 most recent decrypted transactions from Supabase so the Home Dashboard can display them.
