# onboarding_screen.dart

## What this file does
This screen provides a welcoming introduction for first-time users. It explains the main features of the app and handles the logic to ensure it only shows up during the first launch.

## Key Features
- **Visual Slides**: Four slides explaining the core value of the app:
  1. Welcome & Wallet Tracking
  2. Financial Goals
  3. Debt Manager
  4. Privacy & Security
- **`_completeOnboarding()`**: Uses `shared_preferences` to save a flag so the user doesn't see these screens again.
- **Navigation**: Automatically redirects to the Home Dashboard once finished or skipped.
