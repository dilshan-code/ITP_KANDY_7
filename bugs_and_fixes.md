# 🛠️ Project Bug & Fix Logs

A professional record of technical challenges encountered and resolved during the development of the **ClickBuy** application. Categorized by date to track evolution and stability.

---

## 📅 March 25, 2026
> *Focus: Data Consistency and Multi-tenant Integrity*

### `[FIXED]` Credit Balance Inconsistency
- **Issue**: Customer credit balances remained active/incorrect after a full settlement transaction.
- **Fix**: Updated `settle_credit.js` to properly clear balances and implemented a frontend refresh trigger upon successful settlement.
- **Context**: Ensuring data consistency across screens is critical. When a debt is paid, the user expects to see an immediate $0.00 balance.

### `[RESOLVED]` Backend Initialization Race Condition
- **Issue**: `ReferenceError: Cannot access 'notificationRepository' before initialization` in `server.js`.
- **Fix**: Reordered dependency injection logic to ensure repositories are fully instantiated before being passed to use cases.
- **Context**: Critical startup fix. This ensures the server starts reliably and all notification-related features have valid repository handles.

### `[FIXED]` Multi-tenant Data Isolation
- **Issue**: Specific accounts (e.g., `demo@gmail.com`) occasionally fetched data from other tenants or failed to load scoped data.
- **Fix**: Audited all Firestore queries to strictly enforce `where('ownerId', '==', ownerId)` and verified header propagation.
- **Context**: Security and privacy are paramount. Multi-tenant isolation must be enforced at the query level to prevent data leakage.

---

## 📅 March 24, 2026
> *Focus: Timezone Syncing and Infrastructure Stability*

### `[RESOLVED]` Invoice Date & Time Discrepancy
- **Issue**: Invoices showed incorrect dates/times in the history screen due to UTC/Local timezone mismatch.
- **Fix**: Implemented `.toLocal()` parsing in the Flutter frontend and standardized ISO strings from the backend.
- **Context**: Accuracy in record-keeping is vital for business auditing. Standardization ensures that "10:00 AM" in the shop means "10:00 AM" in the app.

### `[RESOLVED]` Port 3000 Collision
- **Issue**: Backend failed to start with `EADDRINUSE` on port 3000 during rapid restarts.
- **Fix**: Improved the `server.close()` logic and added a robust cleanup script to free the port on process exit.
- **Context**: This friction-reducing fix ensures a smooth developer experience during iterative coding and testing.

### `[FIXED]` Auth Hashing Login Failure
- **Issue**: Users were unable to log in after the implementation of password hashing during maintenance.
- **Fix**: Synchronized the bcrypt verification logic between the registration and login use cases.
- **Context**: Security upgrades shouldn't break accessibility. This restore access while maintaining the improved security posture.

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
*Last Review: 2026-03-25 • Total Issues Logged: 23*
