# user_profile.dart

## What this file does
Similar to the Account model, this is the "Blueprint" for a user's basic profile details. We need this because Supabase Auth normally only handles emails and passwords, but we want to know the user's name and see their avatar picture.

## Key Properties & Functions
- **`UserProfile (Class)`**: The blueprint containing:
  - `id`: A unique database string matching their Login ID.
  - `fullName`: The user's typed name.
  - `avatarUrl`: A web link tracking where their uploaded profile picture is currently saved.
  - `createdAt`: When they signed up.
- **`fromJson()`**: Packages a user's details downloaded from the `user_profiles` database table into a `UserProfile` object.
