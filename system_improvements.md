# 🚀 System Evolution & Feature Log

A roadmap of architectural enhancements and user experience updates implemented to make **ClickBuy** a more robust and scalable platform.

---

## 📅 March 25, 2026
> *Focus: Enterprise-Grade Architecture and Validation*

### `[ARCH]` Full Multi-tenant Propagation
- **Feature**: End-to-end `ownerId` scoping.
- **Description**: Propagated the `ownerId` from the authenticated user context through all backend layers (Route -> Controller -> Use Case -> Repository) and integrated it into the Flutter `ApiClient`.
- **Benefit**: Ensures absolute data isolation between different shop owners. Each user only sees their own products, sales, and customers, making the app production-ready for multiple businesses.

### `[FEAT]` Credit Settlement Invoices
- **Feature**: Formal Invoice generation for credit payments.
- **Description**: Implemented a new workflow to generate a professional PDF invoice whenever a customer settles their outstanding credit balance.
- **Benefit**: Provides transparency and professional record-keeping for both the shop owner and the customer.

### `[ARCH]` Centralized Dual-Layer Validation
- **Feature**: Unified validation schema for frontend and backend.
- **Description**: Established a consistent set of validation rules for all major entities (Products, Suppliers, Auth). Implemented real-time form validation in Flutter and strict schema enforcement in Node.js.
- **Benefit**: Dramatically reduces "bad data" entries and improves UX by providing immediate feedback before the user even hits "Save."

### `[UX]` Context-Aware Snackbar Positioning
- **Feature**: Repositioned floating notifications.
- **Description**: Moved all success/error snackbars to appear just above the bottom navigation bar.
- **Benefit**: Prevents notifications from obstructing the top-level app bar or main content, keeping important information within the user's focus area without being intrusive.

### `[DEVOPS]` Backend ESLint Integration
- **Feature**: Automated code quality auditing.
- **Description**: Configured ESLint for the Node.js backend to enforce consistent coding standards and catch potential bugs early.
- **Benefit**: Improves maintainability and long-term stability of the backend codebase.

---

## 📅 March 24, 2026
> *Focus: Proactive Monitoring and Notifications*

### `[FEAT]` Out-Of-Stock Alert System
- **Feature**: Automatic inventory notifications.
- **Description**: Implemented a backend trigger that monitors stock levels during sales and notifies the owner immediately when a product hits zero.
- **Benefit**: Prevents lost sales by ensuring shop owners are always aware when critical items need restocking.

### `[FEAT]` Credit Limit Enforcement & Badges
- **Feature**: Real-time credit monitoring.
- **Description**: Added logic to alert users when a credit customer exceeds their pre-defined limit. Included a notification badge on the app icon.
- **Benefit**: Minimizes financial risk for the shop by providing immediate warnings when a customer's debt exceeds safe thresholds.

---

## 📅 March 23, 2026
> *Focus: Developer Tooling and Data Integrity*

### `[ARCH]` Phone Normalization Engine
- **Feature**: Core utility for sanitizing and standardizing phone number inputs.
- **Description**: Centralized normalization logic that strips non-numeric characters and enforces a standard format across the app.
- **Benefit**: dramatically improves the reliability of customer searches and SMS notification delivery.

### `[DEVOPS]` Backend Audit Utilities
- **Feature**: `check_sales.js` Sales Verification Script.
- **Description**: A CLI tool for backend developers to quickly scan and validate the integrity of sale and credit records in Firestore.
- **Benefit**: Reduces the time needed to debug data issues and provides a safety net during large-scale database migrations.

### `[UX]` Refined Credit History View
- **Feature**: Enhanced layout for `credit_list_screen.dart`.
- **Description**: Optimized the rendering of credit transactions for better readability and performance.
- **Benefit**: Provides shop owners with a clearer view of their outstanding balance and payment history, facilitating faster decision-making.

---

## 📅 March 22, 2026
> *Focus: Data Export and Visual Refinement*

### `[FEAT]` Universal PDF Export
- **Feature**: PDF download capability for Credit Customers, Suppliers, and Purchase Records.
- **Description**: Integrated `pdf` and `printing` packages to generate professional documents from application data.
- **Benefit**: shop owners can now keep physical records or share transaction histories via external platforms, adding a "pro" tier feature to the app.

### `[UI]` Supplier Lifecycle Enhancements
- **Feature**: Refined Supplier Management UI and Profile editing.
- **Description**: Updated the "Total Payable" card to a success-green theme, added supplier editing capabilities, and standardized currency symbols ($).
- **Benefit**: Makes financial data more intuitive (Green = Settled/Calculated) and gives users better control over their contact database.

### `[UX]` Contextual Placeholders
- **Feature**: Auth Screen hint text integration.
- **Description**: Added descriptive placeholders (e.g., "Enter your email") to all input fields in Login and Registration screens.
- **Benefit**: reduces cognitive load for new users and prevents input errors by providing immediate visual cues on what information is required.

### `[UI]` Global Notification Branding
- **Feature**: Consistent Notification Icons.
- **Description**: Added a uniform notification bell icon across all primary dashboard screens.
- **Benefit**: Provides a predictable anchor point for users to check their activity logs, improving navigation "muscle memory."

---

## 📅 March 21, 2026
> *Focus: UX Resilience and Shell Architecture*

### `[UX]` Loading-Gate Pattern
- **Feature**: Introduced `_buildLoadingDropdown` method across recording screens.
- **Description**: Screens now display a `CircularProgressIndicator` during data re-fetches or async operations.
- **Benefit**: Prevents users from interacting with "half-loaded" dropdowns, which is the #1 cause of state-mismatch crashes. It feels much smoother!

### `[ARCH]` Shared Main Shell Architecture
- **Feature**: Unified `MainShell` navigation system.
- **Description**: Centralized the bottom navigation bar and screen-switching logic into a single dedicated widget.
- **Benefit**: Simplifies the app's foundation. It makes adding new tabs easier and ensures that global state (like user profile) persists across screen swaps.

---

## 📅 March 20, 2026
> *Focus: UI Standardization*

### `[UI]` Premium Component Design
- **Feature**: Global `_containerDecoration` and standard UI tokens.
- **Description**: Standardized borders, gradients, and shadows using reusable helper methods.
- **Benefit**: Ensures the app has a consistent "high-end" look regardless of which screen the user is on. No more mismatched button styles!

---

## 📅 March 18, 2026
> *Focus: Onboarding Flow and Error Resilience*

### `[UX]` Demo-First Testing Strategy
- **Feature**: Pre-filled "One-Tap" credentials on Auth screens.
- **Description**: The app now defaults to `demo@clickbuy.com` for rapid tester entry.
- **Benefit**: Makes it incredibly easy for reviewers and stakeholders to see the "meat" of the app without typing on a mobile keyboard.

### `[UX]` Simplified Registration Flow
- **Feature**: Requirement reduction for new accounts.
- **Description**: Limited initial registration to just Phone and Password, with Name/Shop Name as optional fields.
- **Benefit**: Increases conversion rates. Users can "get in" quickly and fill out their full profile once they see the value of the app.

### `[ARCH]` Global Network Error Handling
- **Feature**: Centralized Exception Parser in `api_client.dart`.
- **Description**: Unified all API calls to pass through a single error-translation layer.
- **Benefit**: We can now show human-friendly SnackBar messages instead of technical JSON dumps. It makes the app feel much more "finished."

---

## 📅 March 17, 2026
> *Focus: Data Integrity and Hybrid Access*

### `[ARCH]` Unified Identifier Authentication
- **Feature**: Dual Email/Phone login support.
- **Description**: Enabled the backend to process both formats through a single `identifier` login field.
- **Benefit**: Provides maximum flexibility for users. Some prefer email, others prefer phone; ClickBuy supports both seamlessly.

### `[DATA]` Unique Identifier Enforcement
- **Feature**: Domain Entity overrides (`==` and `hashCode`).
- **Description**: Implemented explicit equality checks for the `Product` and `Supplier` models.
- **Benefit**: Vital for Flutter's state management. It ensures that when a product updates, the UI knows *exactly* which list item needs to change.

### `[DATA]` Clean Slate State Management
- **Feature**: "Reset-Before-Fetch" pattern.
- **Description**: Always clear local state variables before triggering a new data arrival from the server.
- **Benefit**: Eliminates "Ghost Data" where an old ID might still be active while a new list is loading.

---

## 📅 March 16, 2026
> *Focus: Record Management and Transparency*

### `[FEAT]` Invoice History Refactor
- **Feature**: Dedicated "Invoice" tab with date categorization.
- **Description**: Grouped purchase records chronologically for easier auditing.
- **Benefit**: Businesses run on dates. Category-based grouping makes it much faster for shop owners to find specific transactions.

### `[FEAT]` Record Deletion Capability
- **Feature**: Secure deletion for purchase invoices.
- **Description**: Added backend and frontend hooks to remove erroneous or outdated records.
- **Benefit**: Gives the user full control over their data. Mistakes happen—now they can be fixed.

---
*Last Update: 2026-03-25 • Status: Stable (Beta)*
