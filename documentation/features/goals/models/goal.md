# goal.dart

## What this file does
This file defines the blueprint for a "Financial Goal". It helps the app understand what a user is saving for and how much progress they've made.

## Key Properties & Functions
- **`FinancialGoal (Class)`**: The structure for tracking goals:
  - `id`: A unique database label.
  - `userId`: Who this goal belongs to.
  - `name`: What the goal is (e.g., "New iPhone").
  - `targetAmount`: The total money needed.
  - `currentAmount`: How much has been saved so far.
  - `deadline`: The date the user wants to reach this goal.
  - `icon`: The symbol shown (defaults to 'flag').
  - `colour`: The visual color given to this goal.
  - `createdAt`: When the goal was first created.
- **`fromJson()`**: Turns data from the database into a `FinancialGoal` object.
- **`toJson()`**: Turns a `FinancialGoal` object back into database data.
- **`percentComplete`**: A shortcut to calculate what percentage of the goal has been reached.
