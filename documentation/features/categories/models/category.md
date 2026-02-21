# category.dart

## What this file does
This is the "Blueprint" for a Category. It defines how the app understands a spending bucket, like "Groceries" or an income bucket like "Salary".

## Key Properties & Functions
- **`Category (Class)`**: The blueprint containing:
  - `id`: A unique database string label.
  - `userId`: Which user created this category.
  - `name`: User-readable text like "Shopping".
  - `type`: Either "income" or "expense".
  - `colorHex`: The string text that `icon_color_mapper.dart` understands (e.g., `#F44336`).
  - `iconName`: The text mapping to a Flutter icon (e.g., `shopping_cart`).
  - `createdAt`: When the category was added to the app.
- **`fromJson()`**: Converts the dictionary from the database into the `Category` object.
- **`toJson()`**: Converts the `Category` object back into a database dictionary to be saved.
