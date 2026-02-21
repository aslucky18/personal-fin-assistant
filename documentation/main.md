# main.dart

## What this file does
This is the starting point of the entire application. When you open Finanalyzer, your phone looks for this file to know how to turn the app on.

## Key Functions & Classes
- **`main()`**: The very first function that runs. It ensures Flutter is ready to draw on the screen and connects the app to our remote Supabase Database using our specific URL and secret key.
  - **Security Note:** It loads the database URL and Anon Key from a decoupled `secrets.dart` file. This file is explicitly ignored in our repository's `.gitignore` to prevent hackers from stealing our database keys. Developers setting up this project use `secrets.template.dart` to configure their own keys locally.
- **`FinanalyzerApp (StatelessWidget)`**: This is the main frame of the house. It sets the title of the app to 'Finanalyzer', loads our custom dark theme from `AppTheme`, and decides what screen to show first.
  - It checks `Supabase.instance.client.auth.currentSession` to see if there is an active user logged in on this device.
  - If there **is** an active session, it sends them straight into the `HomeDashboard` so they don't have to re-enter their password after closing the app. 
  - If they are **not** logged in, it redirects them to the `LoginScreen`.
