# auth_service.dart

## What this file does
This acts as the "Bouncer" for our app. It handles everything security-related with Supabase, specifically around user identity.

## Key Functions
- **`signUp(email, password, fullName)`**: Packages new user details and sends them to Supabase Auth to create a brand new account and a matching User Profile in the database.
- **`signIn(email, password)`**: Asks Supabase to verify a user's typed password against their email.
- **`signOut()`**: Kills the current active session, forcing the user back to the Login Screen.
- **`getCurrentUserProfile()`**: Finds out who exactly is holding the phone right now, and fetches their name and picture from the `user_profiles` database table.
- **`updateProfile(fullName)`**: Allows users to rename themselves.
- **`uploadAvatarBytes(bytes, ext)`**: Takes a raw photo file chosen from the user's phone gallery, uploads it to a `avatars` bucket locker in the Supabase Storage, gets the public link to the new photo, and saves that link to the user's profile.
- **`onAuthStateChange` (Stream)**: A magic listener that instantly tells the app anytime a user's sign-in status changes (like if their session expires).
