# user_profile_screen.dart

## What this file does
This is the specialized editor screen where a user can change their display name or their profile picture.

## How it works
- Uses the `image_picker` package to hook into the phone's native iOS/Android camera roll or gallery. 
- **`_pickImage()`**: Opens the phone's gallery, lets the user select a picture, scales it down, and previews it locally on the screen.
- **`_saveProfile()`**: First, it takes the bytes of the raw image and asks `AuthService.uploadAvatarBytes()` to save the image to the remote Supabase Bucket. Second, it takes the URL returned by the bucket and asks `AuthService.updateProfile()` to save the updated name and new photo URL together into the active user's profile.
- Shows spinning loading indicators (`CircularProgressIndicator`) over the image and save button so the user knows they have to wait for the photo to upload over the internet.
