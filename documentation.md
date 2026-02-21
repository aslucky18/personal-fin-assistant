# Finanalyzer: The Complete Beginner’s Guide

Welcome to the ultimate guide to understanding how the **Finanalyzer** app works! We’re going to break down every single part of this app so that absolutely anyone can understand it step-by-step. 

Think of building an app like building a house. You need a foundation (database), plumbing and electricity (services/logic), and the visible rooms, paint, and furniture (the User Interface or UI). 

---

## Part 1: The Big Picture (Architecture)

Finanalyzer is a personal finance tracking app. It allows users to:
1. Create an account and log in.
2. Group their money into "Accounts" (like checking, savings, or credit cards).
3. Create "Categories" (like groceries, rent, or salary).
4. Add "Records" — actual money moving in (income) or out (expense).
5. See all their money summarized on a beautiful Dashboard.

We built this house using two main tools:
- **Flutter (Dart code):** The frontend. This builds what you see on the screen and runs on your phone or web browser.
- **Supabase:** The backend. This is our remote server that provides a database (to save data permanently) and handles user authentication (logging in/out).

### How the Folders are Organized
We organize our code into folders to keep the house clean. Inside `lib/`, you will see:
- `core/`: Contains stuff used everywhere (like colors, themes, screen-size logic).
- `features/`: The main rooms of the house. We split features by function:
   - `auth/`: Everything related to users logging in and profiles.
   - `accounts/`: Bank accounts.
   - `categories/`: Income and expense categories.
   - `records/`: Individual transactions.

---

## Part 2: The Foundation (Supabase Backend)

Before writing app code, we set up **Supabase**. Supabase stores our data in a **Postgres Database**, which is basically a set of large, organized Excel spreadsheets.

Here are the "spreadsheets" (Tables) we created:
1. **`user_profiles`**: Stores the user's name and their profile picture link.
2. **`accounts`**: Stores the user's bank accounts, balance, and bank names.
3. **`categories`**: Stores the name, color, and icon for different expense/income types.
4. **`financial_records`**: Stores every single transaction (amount, date, which account it belongs to, and which category it falls under).

### Security
We turned on **Row Level Security (RLS)**. This is a bouncer at the door of the database. It guarantees that User A can only see and edit User A's data. User B cannot see User A's data.

### Encryption
Financial data is sensitive. We used a special database tool called `pgcrypto`. When the app saves your bank account number or balance, the database scrambles it with a secret password. Even if a hacker stole the database, they would just see random letters and numbers. We created special database functions called **RPCs** (Remote Procedure Calls) to securely save and read this scrambled data.

### Storage Bucket
We created a storage folder in Supabase called `avatars` to hold user profile pictures.

---

## Part 3: The Front Door (`main.dart`)

`lib/main.dart` is the very first file that runs when the app starts.
- It "turns on" the app.
- It connects the app to our Supabase database using our unique URL and key.
  - **Security Configuration:** These keys are no longer hardcoded in `main.dart`. Instead, they are loaded from a special `lib/secrets.dart` file. This file is blocked from being uploaded to GitHub via `.gitignore`. A `secrets.template.dart` file serves as a blueprint for developers cloning the app.
- It automatically checks `Supabase.instance.client.auth.currentSession` to see if the user was already logged in from a previous session.
- If they **are** logged in, it sends them straight to the `HomeDashboard`. If they are not logged in, it sends them to the `LoginScreen`.

---

## Part 4: The Rooms (Features)

Each feature in our app is split into three main files:
1. **Model** (`model.dart`): The blueprint. Defines what data looks like.
2. **Service** (`service.dart`): The plumber. Talks to Supabase to save or fetch the data.
3. **Screen / UI** (`screen.dart`): The paint and furniture. What the user actually taps and looks at.

Let's look at every feature.

### 4.1 Authentication feature (`lib/features/auth/`)
This handles logging users in and letting them edit their profiles.

* **Model (`user_profile.dart`)**: Holds the `id`, `fullName`, and `avatarUrl`.
* **Service (`auth_service.dart`)**: 
   * `signUp()`: Creates a new user in Supabase.
   * `signIn()`: Logs them in.
   * `signOut()`: Logs them out.
   * `getCurrentUserProfile()`: Asks Supabase for the logged-in user's name and picture.
   * `updateProfile()` / `uploadAvatarBytes()`: Saves a new photo to the Supabase Storage Bucket and updates their name.
* **Screens**:
   * `LoginScreen` & `SignupScreen`: Simple pages with email and password text boxes.
   * `UserProfileScreen`: A page showing the user's current photo. It allows them to tap the photo, open their phone gallery to pick a new one, type a new name, and click "Save."
   * `SettingsScreen`: Shows the avatar and a big red "Sign Out" button.

### 4.2 Accounts feature (`lib/features/accounts/`)
This is where users tell the app about their bank accounts.

* **Model (`account.dart`)**: Holds the `id`, `bankName`, `accountNumber` (encrypted),, and `balance` (encrypted).
* **Service (`account_service.dart`)**: 
   * `getAccounts()`: Calls an RPC function on Supabase to decrypt and download the user's accounts.
   * `addAccount()`: Calls an RPC function on Supabase to encrypt and save a new account.
* **Screens**:
   * `AccountsListScreen`: Shows a list of all your bank accounts and their balances.
   * `AddAccountScreen`: A form with text boxes for Bank Name, ending digits, starting balance, and account type (Checking vs Savings).

### 4.3 Categories feature (`lib/features/categories/`)
This defines what kind of things the user spends money on.

* **Model (`category.dart`)**: Holds the `name`, `type` (income or expense), `colorHex` (a visual color code), and `iconName` (a visual icon code).
* **Service (`category_service.dart`)**: Talks to the `categories` table in Supabase to fetch or insert new categories.
* **Screens**:
   * `CategoriesListScreen`: Shows a list of categorized boxes with their colors and icons.
   * `AddCategoryScreen`: A form that lets users type a name, choose Income/Expense, and pick a color and icon from a list.

### 4.4 Records feature (`lib/features/records/`)
This is the core of the app: keeping track of money moving!

* **Model (`record.dart`)**: Ties everything together. It holds an `amount`, the `accountId`, the `categoryId`, whether it was a `credit` (Money IN) or `debit` (Money OUT), and the `timestamp` (when it happened).
* **Service (`record_service.dart`)**: 
   * `getRecords()`: Asks Supabase for a list of transactions, ordering them by the most recent first.
   * `addRecord()`: Calculates the math. When you add a new Record, this service saves the record, AND it updates the balance of the Bank Account.
* **Screens**:
   * `AddRecordScreen`: The form for money. It asks for an Amount, a Title, and gives the user Dropdown menus to select which Category and Account to use.
   * `HomeDashboard`: The beautiful main screen.
     - **Top Section**: Says "Hello, [Your Name]", shows your profile picture, and shows your Total Balance across all accounts.
     - **Middle Section**: Shows green/red cards for "Monthly Income" and "Monthly Expenses". It calculates these by looking only at records from the current month.
     - **Bottom Section**: Shows a list of the 5 most recent transactions you made.

### 4.5 The App Skeleton (`MainLayout` in `home_dashboard.dart`)
Normally, apps have a bottom bar with buttons to switch between pages. Finanalyzer does this perfectly using a `MainLayout` widget.
- It has a `BottomNavigationBar` with icons for Home, Accounts, Add (+), Categories, and Settings.
- When you tap a button, it secretly just swaps out the middle of the screen for the correct feature page using an `IndexedStack` (which prevents the app from having to reload the page every time you click).

---

## Part 5: UI & Styling (`lib/core/`)

To make the app look stunning across all devices, we wrote utilities:
- **`app_theme.dart`**: This is our paint bucket. We defined exactly what "Primary Blue", "Success Green", and "Background Dark" look like. If we ever want to change the app's color, we only change it in this one file, and the whole app updates magically.
- **`responsive.dart` (`ResponsiveBuilder`)**: This makes the app smart. If you open the app on a small mobile phone, it stacking things vertically. If you stretch the app wide on a Desktop computer, the `ResponsiveBuilder` automatically puts things side-by-side to use the extra space beautifully.
- **`icon_color_mapper.dart`**: The database only understands text. So when a user picks a red heart icon for a category, this file translates the color Red and the Heart Icon into text keywords to save to the database, and then translates them back into real visual colored icons when the app downloads them later.

---

## Summary of How Data Flows
Let's look at an example of everything working together. The user wants to add an expense of $5 for Coffee.

1. **User Action:** The user taps the "+" button on the bottom bar and goes to the `AddRecordScreen`.
2. **UI Loading:** The `AddRecordScreen` asks the `AccountService` and `CategoryService` to fetch the user's data so it can fill out the Dropdown menus.
3. **User Entry:** The user types "5" and "Coffee", selects their Checking Account, and selects the Food Category. They press "Save".
4. **Service Action:** `AddRecordScreen` bundles all that info into a `FinancialRecord` model blueprint and hands it to the `RecordService`.
5. **Backend Save:** `RecordService` encrypts the data (if needed) and sends it over the internet to Supabase to insert into the `financial_records` table.
6. **UI Update:** The app closes the form, returns to the `HomeDashboard`, reads the new record, recalculates the Monthly Expense math, and shows the updated numbers on the screen!

And that is absolutely everything there is to the Finanalyzer system! You have a secure, beautiful, multi-platform financial tracking system.
