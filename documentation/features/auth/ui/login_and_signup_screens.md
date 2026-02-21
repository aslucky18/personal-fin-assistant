# login_screen.dart & signup_screen.dart

## What these files do
These are the visual locked doors at the front of the app. Users cannot pass these screens into the main app until they prove who they are.

## How they work
- Both files use forms (`TextFormField`) specifically asking for sensitive info like email and password.
- They have a button that triggers the `AuthService.signIn()` or `AuthService.signUp()` commands.
- If the login is successful, they navigate the user straight into the `MainLayout` (the dashboard).
- If the login fails (like a typo in the password or an email that doesn't exist), they catch the error and display an alert popup (`SnackBar`) telling the user what went wrong.
- `login_screen.dart` has a text button allowing users to switch to the `signup_screen.dart` if they are new to the app.
