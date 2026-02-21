# category_service.dart

## What this file does
Acts as the plumbing to save and load Categories to and from the Supabase database table `categories`. 

## Key Functions
- **`getCategories()`**: Contacts Supabase, asks for all categories belonging to the currently signed-in user, and translates the response back into a list of `Category` blueprints.
- **`addCategory(Category category)`**: Takes a new Category created by the user and uploads it to the database so it is saved forever and can be grabbed by `getCategories()` later. 
