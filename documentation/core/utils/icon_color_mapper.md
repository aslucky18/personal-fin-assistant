# icon_color_mapper.dart

## What this file does
Our database (Supabase) can only store text and numbers, it cannot literally store a picture of a "Shopping Cart Icon" or the concept of the "Color Red". This file acts as a translator between what the database understands (text string keywords) and what Flutter natively understands (Icons and Color objects).

## Key Functions
- **`colorToString()` & `stringToColor()`**: Translates a Flutter `Color` object into a readable text string (e.g., `'Color(0xfff44336)'`) to save to the database, and back again into a `Color` when loading from the database.
- **`iconToString()`**: Looks at the graphic icon a user selected and translates it into a text string like `'shopping_cart'` or `'fastfood'`.
- **`stringToIcon()`**: Reads the text keyword from the database and returns the actual `IconData` (like `Icons.shopping_cart_rounded`) so it can be drawn on the screen.

When users create custom Categories for their expenses, we use this to save their personalized Color and Icon choices to the backend.
