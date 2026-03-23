# 🛠️ Project Bug & Fix Logs

A professional record of technical challenges encountered and resolved during the development of the **ClickBuy** application. Categorized by date to track evolution and stability.

---

## 📅 March 23, 2026
> *Focus: Data Normalization and Backend Auditing*

### `[FIXED]` Phone Number Inconsistency
- **Issue**: Variations in phone number formats (spaces, dashes, country codes) caused search failures and duplicate records.
- **Fix**: Implemented a unified `normalizePhoneNumber` utility and added a comprehensive test suite to handle various edge cases.
- **Context**: Data integrity starts at the input level. Standardizing phone numbers ensures that "077 123 4567" and "0771234567" are treated as the same entity.

### `[RESOLVED]` Sale Record Discrepancies
- **Issue**: Minor discrepancies were found in some sale records during high-concurrency testing.
- **Fix**: Refactored `SaleController.js` to ensure atomic operations and created a `check_sales.js` audit script for field verification.
- **Context**: Trust is the foundation of a POS system. These backend safeguards ensure that every cent is accounted for and records matches the physical transactions.

---

## 📅 March 22, 2026
> *Focus: Notification UX and Layout Consistency*

### `[FIXED]` Notification Alignment & Clipping
- **Issue**: Top popup notifications were misaligned, and long messages were clipped in the notification list.
- **Fix**: Re-centered the notification overlay and implemented expanded text layouts for the notification history screen.
- **Context**: Information should be readable at a glance. Ensuring notifications don't cut off important context improves user awareness of system actions.

---

## 📅 March 21, 2026
> *Focus: Stabilizing UI State and Backend Error Parsing*

### `[PATCHED]` Dropdown Assertion Crash
- **Issue**: Flutter threw an assertion error: *"Either zero or 2 or more [DropdownMenuItem]s were detected with the same value"*.
- **Fix**: Implemented `.toSet()` on supplier/product lists to filter out duplicate IDs from the backend response.
- **Context**: This is a classic "stale data" issue. By ensuring unique IDs, we prevent the UI from trying to render two items as the same selection, which crashes the entire screen.

### `[RESOLVED]` UI Crash on Purchase Save
- **Issue**: The application crashed immediately after a successful purchase record was saved to the database.
- **Fix**: Applied `ValueKey` to the top-level dropdown widgets to force a clean element tree rebuild when the state resets.
- **Context**: Sometimes Flutter tries to recycle old widgets that don't match the new empty state. The `ValueKey` acts like a "hard reset" button for the widget.

### `[PATCHED]` Splash Screen Lifecycle
- **Issue**: The splash screen would occasionally hang or redirect to the wrong screen upon app startup.
- **Fix**: Updated `splash_screen.dart` to use a reliable `Timer` and explicit navigation to the `LoginScreen`.
- **Context**: First impressions matter! A smooth splash-to-login transition makes the app feel responsive right from the start.

### `[RESOLVED]` Generic 409 Error Handling
- **Issue**: Users saw a cryptic "409" when registration failed.
- **Fix**: Enhanced `api_client.dart` to parse the `message` field from JSON error bodies instead of just the status code.
- **Context**: "Fail early, tell the truth." Users are much less frustrated when told "Account Already Exists" rather than "Error 409."

---

## 📅 March 20, 2026
> *Focus: Supplier Management UX and Navigation*

### `[PATCHED]` Unresponsive Supplier Rows
- **Issue**: Tapping on a supplier in the management list did nothing.
- **Fix**: Wrapped list items in `InkWell` widgets with appropriate `onTap` callbacks.
- **Context**: Designing the UI is one thing; making it functional is another. We ensured the feedback (ripple effect) matches the action.

### `[RESOLVED]` Supplier Navigation Logic
- **Issue**: Navigation to `SupplierTabsScreen` was inconsistent or loaded the wrong initial state.
- **Fix**: Implemented direct navigation logic that specifically targets the "Purchase Records" tab for the selected supplier context.
- **Context**: We want to reduce "clicks-to-action." Clicking a supplier usually means the user wants to see their history immediately.

### `[FIXED]` Widget Tree Nesting Errors
- **Issue**: UI layout errors occurred in supplier screens due to incorrect brace nesting and orphaned widgets.
- **Fix**: Audited and corrected the widget tree structure in `supplier_management_screen.dart` and `supplier_tabs_screen.dart`.
- **Context**: Complex Flutter trees are easy to mess up. Keeping the code clean and properly indented helps prevent these "invisible" UI bugs.

---

## 📅 March 18, 2026
> *Focus: Visual Polish and Build Configuration*

### `[PATCHED]` Ghost Divider Lines
- **Issue**: Stubborn black lines appeared at the bottom of expansion tiles and list items.
- **Fix**: Removed hardcoded `Divider` widgets and set `dividerColor: Colors.transparent` in local themes.
- **Context**: Small visual glitches can make an app feel "cheap." Removing these lines gives the UI a premium, seamless "Material 3" feel.

### `[RESOLVED]` Windows Build Configuration
- **Issue**: "No Windows desktop project configured" blocked PC testing.
- **Fix**: Ran `flutter create --platforms=windows .` and configured necessary C++ build tools.
- **Context**: Expanding to desktop support early helps in rapid testing and provides a wider reach for the management portal.

---

## 📅 March 17, 2026
> *Focus: Backend Integration and Data Migration*

### `[RESOLVED]` Auth Identifier Payload
- **Issue**: Login failed because the backend expected `identifier` but the frontend sent `email`.
- **Fix**: Refactored `AuthRepository` to use the unified `identifier` key to support both Email and Phone login.
- **Context**: Flexibility is key. By using one field for both, we simplify the login logic on both ends of the stack.

### `[FIXED]` Backend Syntax Errors
- **Issue**: Backend compilation failed due to missing closing braces in `AuthController.js`.
- **Fix**: Restored missing `try/catch` and function closing braces in the authentication controller.
- **Context**: Even small syntax errors can take down the whole API. Constant auditing of controller logic is a must for stability.

### `[RESOLVED]` Cost-Price Field Deletion
- **Issue**: Crashes occurred after the `costPrice` field was removed from the database but remained in code.
- **Fix**: Audited all entity models and UI screens to remove references to the legacy field.
- **Context**: Technical debt cleanup. We moved to a simpler price-only model to streamline the user interface.

---
*Last Review: 2026-03-23 • Total Issues Logged: 17*
