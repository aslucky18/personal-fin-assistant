# app_theme.dart

## What this file does
This file defines the entire visual style of the application. It acts as the "paint bucket" for our house. Instead of telling every single screen to use a specific dark blue color, we define the dark blue color here as `AppTheme.background`. If we ever decide to change the app's style to light mode, we only have to change it in this one file.

## Key Properties & Elements
- **Color Palette**: We define constants like:
  - `primary`: The main indigo/blue accent color used for important buttons.
  - `background`: The very dark slate color used for the main screen backdrop.
  - `surface`: A slightly lighter dark color used for floating cards and menus.
  - `success` (green) and `error` (cherry red) for income and expenses.
- **`themeData`**: A giant bundle of visual rules given to Flutter. It configures:
  - `scaffoldBackgroundColor`: Setting the default backdrop of all screens.
  - `colorScheme`: Telling Flutter which colors to use for highlighting.
  - `textTheme`: Setting fonts like `Montserrat` and their default sizes and colors.
  - UI Element Styles: It also defines exactly how `ElevatedButton`, `TextField`, `Card`, and `BottomNavigationBar` should look globally, including rounded corners (`BorderRadius.circular`) and padding.
