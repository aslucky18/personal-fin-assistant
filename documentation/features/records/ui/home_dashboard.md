# home_dashboard.dart

## What this file does
This is the heart of the Finanalyzer application. It contains the beautiful main summary page that greets the user, AND it contains the `MainLayout` wrapping shell that dictates how the user navigates everywhere else.

## Key Parts
### Part A: The `MainLayout` Shell
- **`BottomNavigationBar`**: Draws 5 icons at the bottom of the screen (Home, Accounts, Add, Categories, Settings).
- **`IndexedStack`**: Secretly holds all 4 of our main screens inside memory like a deck of cards. 
- **`_onItemTapped()`**: When you push a button, it shuffles the deck of cards until the correct screen is on top. Since the Add (+) button isn't truly an everyday tab, it treats it specially: clicking the "+" button triggers a sleek sliding animation to pop-up the `AddRecordScreen` instead of shuffling the deck.

### Part B: The `HomeDashboard` Visuals
- **The Header (`_buildHeader`)**: Shows the user's Profile Avatar, greeting their name, and prominently displaying the Total Balance across *all* their checking/savings accounts in large text.
- **The Month Summary (`_buildSummaryCards`)**: 
  - Calls `_calculateMonthlyTotals()`, which reads all loaded transactions and isolates just the ones that happened during the current calendar month. 
  - Adds up all the Income, and all the Expenses, to draw visually distinct green and red summary cards so the user knows exactly how much money they gained and lost this month.
- **The Recent Activity (`_buildRecentTransactions`)**: Draws a vertical list of the last 5 things the user purchased, showing the name, the date, and a red minus sign (if it was an expense) or a green plus sign (if it was income).

This page automatically tells `RecordService` and `AccountService` to download the newest data every time the user comes back to it!
