# Finanalyzer

Finanalyzer is a modern, responsive personal finance tracking application built with Flutter and Supabase. It offers users a comprehensive suite of tools to manage and analyze their personal finances effectively. With an intuitive interface, users can effortlessly track their incomes and expenses, manage multiple accounts, and categorize their transactions.

## Features

- **Dashboard Summary:** Get a quick overview of your total balance, monthly income, and monthly expenses.
- **Records Management:** Easily add, view, and organize financial records (incomes and expenses).
- **Category Tracking:** Detailed transaction categorization with custom colors and icons for easy identification.
- **Account Management:** Track balances across multiple accounts or wallets.
- **Authentication:** Secure user sign-up, login, and customized profiles powered by Supabase Auth.
- **Responsive UI:** Seamless experience optimized for both mobile and desktop platforms.
- **Modern Dark Theme:** A sleek and elegant dark mode UI.

## Tech Stack

- **Frontend:** Flutter
- **Backend:** Supabase (Database, Authentication)
- **Dependencies:** `supabase_flutter`, `image_picker`, `cupertino_icons`

## Environment Setup

This project uses Supabase for its backend. To ensure secrets are not exposed in the repository, you need to set up your own `secrets.dart` file.

1. Navigate to the `lib/` directory.
2. Copy the contents of `secrets.template.dart` into a new file named `secrets.dart`.
3. Replace the placeholder values in `secrets.dart` with your actual Supabase URL and Anon Key.
   ```dart
   class Secrets {
     static const String supabaseUrl = 'YOUR_ACTUAL_URL';
     static const String supabaseAnonKey = 'YOUR_ACTUAL_ANON_KEY';
   }
   ```
   *Note: `lib/secrets.dart` is included in `.gitignore` and will not be committed to version control.*

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
