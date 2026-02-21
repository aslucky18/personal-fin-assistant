# accounts_list_screen.dart

## What this file does
This is the visual screen that draws a scrolling list of all your created Bank Accounts.

## How it works
- It uses a `FutureBuilder`, which is a special Flutter tool that displays a loading spinning circle while it waits for `AccountService.getAccounts()` to finish downloading the data from the internet.
- Once the data arrives, it builds a `ListView` containing colorful cards (`Card` widget) that display the bank's icon, the name, and the current balance formatted nicely with dollar signs.
- It provides a floating action button (a large "+" button in the corner) that routes the user to `AddAccountScreen`. If a new account is added, it re-runs the download function to instantly refresh the screen.
