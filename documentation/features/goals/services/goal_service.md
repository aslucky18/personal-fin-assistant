# goal_service.dart

## What this file does
This service acts as the bridge between the app's Financial Goals and the Supabase database. It handles saving, loading, and deleting goals.

## Key Methods
- **`getGoals()`**: Fetches all goals for the logged-in user from the database.
- **`addGoal()`**: Sends a new goal to the database.
- **`updateGoal()`**: Modifies an existing goal and updates the database.
- **`deleteGoal()`**: Removes a goal from the database permanently.
