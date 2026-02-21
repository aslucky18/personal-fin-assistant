# categories_list_screen.dart

## What this file does
A visual screen showing every single Category the user has created in a stunning, colorful list. 

## How it works
- Uses `CategoryService.getCategories()` inside a `FutureBuilder` to fetch data from the internet while showing a loading circle.
- Maps through the data to draw a `ListView` of custom cards (`_buildCategoryCard`).
- Every card looks at the `colorHex` text and `iconName` text stored in the database, passes it through `icon_color_mapper.dart`, and then draws a perfect Circle Avatar containing that exact color and icon next to the category name.
- It provides a floating "+" button linking to `AddCategoryScreen`. Whenever a new category is made, it refreshes the list instantly.
