# responsive.dart

## What this file does
This file gives the app a brain to understand how big the screen is. Since Finanalyzer can run on a small iPhone or a massive 4k Desktop Monitor, it needs to know how to rearrange the furniture (UI elements) to look good.

## Key Classes
- **`ResponsiveBuilder (StatelessWidget)`**: A smart container that checks the width of the screen using `MediaQuery.of(context).size.width`.
  - If the screen is less than 850 pixels wide (like a phone or small tablet), it renders the `mobile` layout provided to it.
  - If the screen is wider than 850 pixels (like a desktop web browser), it automatically switches to rendering the `desktop` layout provided to it. 

This prevents things from looking squished on phones or ridiculously stretched on computers.
