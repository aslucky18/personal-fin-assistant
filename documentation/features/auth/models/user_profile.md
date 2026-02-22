# user_profile.dart

## What this file does
This is the "Blueprint" for a user's details, expanding beyond basic auth to include personal and professional information.

## Key Properties & Functions
- **`UserProfile (Class)`**: The blueprint containing:
  - `id`: Unique database string.
  - `fullName`: The user's typed name.
  - `avatarUrl`: Link to their profile picture.
  - `gender`: Optional personal info.
  - `dateOfBirth`: Optional personal info.
  - `professionalSalary`: User's income details.
  - `fixedAllowances`: Fixed professional benefits.
  - `salaryCreditDate`: Day of the month they receive payment.
  - `jobTitle` / `companyName`: Professional identity.
- **`completeness`**: A getter that calculates how much of the profile is filled (0 to 1).
- **`fromJson()`**: Converts DB data into a `UserProfile` object.
