# liability.dart

## What this file does
This file defines the blueprint for a "Liability" or "Debt". It allows users to track what they owe to others (e.g., loans, credit card balances).

## Key Properties & Functions
- **`Liability (Class)`**: The structure for tracking debts:
  - `id`: A unique database label.
  - `userId`: Who this debt belongs to.
  - `name`: What the debt is (e.g., "Car Loan").
  - `type`: The category of debt (e.g., "loan", "card").
  - `totalAmount`: The original or total amount owed.
  - `paidAmount`: How much has been paid back so far.
  - `interestRate`: The annual percentage rate for this debt.
  - `dueDate`: When the next payment is due.
  - `createdAt`: When the debt was added to the tracker.
- **`fromJson()`**: Turns data from the database into a `Liability` object.
- **`toJson()`**: Turns a `Liability` object back into database data.
- **`remainingAmount`**: Calculates how much is still owed.
- **`percentPaid`**: Calculates the percentage of the debt that has been repaid.
