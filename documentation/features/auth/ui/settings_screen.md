# settings_screen.dart

## What this file does
This serves as the Control Center for a user's personal app experience. Found on the far right tab of the bottom navigation bar.

## How it works
- It automatically loads the user's details using `AuthService.getCurrentUserProfile()`.
- It displays a round `CircleAvatar` taking up the top center of the screen, showing the user's profile picture. If they don't have one, it shows the first letter of their name on a colored background.
- It provides a large "Edit Profile" button to send the user to the `UserProfileScreen`.
- It contains a massive red "Sign Out" button at the bottom. When clicked, it asks `AuthService.signOut()` to kill the session and dumps the user back to the login page.
