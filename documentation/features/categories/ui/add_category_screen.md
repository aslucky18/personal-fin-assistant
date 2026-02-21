# add_category_screen.dart

## What this file does
Allows the user to paint their own buckets! A visual form to define a new Custom Category.

## How it works
- It contains a `TextField` for the Category Name.
- It contains a segmented button (essentially a toggle switch) letting the user designate the category as an "Expense" (like Rent) or "Income" (like Salary).
- It generates a visual grid of selectable **Colors** and a visual grid of selectable **Icons**. When a user taps one, a white circle popup indicates it is selected.
- **`_saveCategory()`**: Gathers the text, the color, the icon, the type, and packages it into a `Category` object. Sends it to `CategoryService.addCategory()` to save to the database. Uses `icon_color_mapper.dart` behind the scenes to translate the visual choices into text the database can actually understand.
