# add_record_screen.dart

## What this file does
The main data entry form when users click the big "+" button in the middle of their tab bar. 

## How it works
- It needs to know all your bank accounts and categories *before* it can show you the form, so you can select them from a list.
- **`_loadData()`**: The very first thing the screen does. It calls `AccountService` and `CategoryService` simultaneously to fetch your data, while showing a loading spinner.
- Displays a giant `TextField` at the top for entering the money amount.
- Displays dropdown menus (`DropdownButtonFormField`) populated with the Accounts and Categories it just downloaded. It automatically selects the first one in the list.
- **`_pickDate()`**: Opens a native visual calendar popup (`showDatePicker`) letting the user choose exactly what day the transaction happened on.
- **`_saveRecord()`**: Triggers when they click save. Verifies they inputted a real number, packages everything into a `FinancialRecord` object, and gives it to `RecordService` to be encrypted and added to the database.
