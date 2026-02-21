# add_account_screen.dart

## What this file does
This is the visual screen where a user types in a new bank account they want to track.

## How it works
- It contains text boxes (`TextField`) for "Bank Name", "Last 4 Digits", and "Starting Balance".
- It contains a dropdown menu (`DropdownButtonFormField`) for Account Type.
- It uses a `StatefulWidget` because it needs to remember what the user is typing in real-time.
- **`_saveAccount()`**: The function triggered when the user taps "Save Profile". It checks if the text boxes are empty. If they are filled out, it packages the data into an `Account` object and hands it to the `AccountService` to save to the database.
- Uses `ResponsiveBuilder` from `core` to render a narrow centered card on Desktop, or a full width layout on Mobile.
