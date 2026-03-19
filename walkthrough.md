# Walkthrough: Optional Registration Fields & Demo Data

The registration flow now only requires a phone number and password, and both the login and registration screens are pre-filled with demo information to make testing effortless.

## What was Changed

### Backend Adjustments
- Modified [AuthController.js](file:///C:/Users/SADINSA/Desktop/IT%20Project/Mobile%20Application/Beta/small_store_app/backend/src/interfaces/controllers/AuthController.js) to only validate that `phone` and `password` are truthy on registration. A default name is generated if not provided.
- Modified [AuthController.js](file:///C:/Users/SADINSA/Desktop/IT%20Project/Mobile%20Application/Beta/small_store_app/backend/src/interfaces/controllers/AuthController.js) to accept a generic `identifier` or `email` field for login, and dispatch to phone vs. email based on whether it contains `@`.
- Updated [authUseCases.js](file:///c:/Users/SADINSA/Desktop/IT%20Project/Mobile%20Application/Beta/small_store_app/backend/src/usecases/authUseCases.js) and [FirestoreOwnerRepository.js](file:///C:/Users/SADINSA/Desktop/IT%20Project/Mobile%20Application/Beta/small_store_app/backend/src/infrastructure/FirestoreOwnerRepository.js) to support looking up owners by phone number using a new [findByPhone](file:///C:/Users/SADINSA/Desktop/IT%20Project/Mobile%20Application/Beta/small_store_app/backend/src/infrastructure/FirestoreOwnerRepository.js#35-42) method.
- Fixed missing try/catch closing braces in [AuthController.js](file:///C:/Users/SADINSA/Desktop/IT%20Project/Mobile%20Application/Beta/small_store_app/backend/src/interfaces/controllers/AuthController.js) that were causing compilation issues.

### Frontend Adjustments
- Updated [register_screen.dart](file:///c:/Users/SADINSA/Desktop/IT%20Project/Mobile%20Application/Beta/small_store_app/frontend/lib/features/auth/presentation/screens/register_screen.dart) with demo initialization in [initState](file:///c:/Users/SADINSA/Desktop/IT%20Project/Mobile%20Application/Beta/small_store_app/frontend/lib/features/auth/presentation/screens/login_screen.dart#21-26). Added `OPTIONAL` labels effectively matching the original UI structure for the Name, Shop Name, and Email text fields.
- Updated [login_screen.dart](file:///c:/Users/SADINSA/Desktop/IT%20Project/Mobile%20Application/Beta/small_store_app/frontend/lib/features/auth/presentation/screens/login_screen.dart) with demo initialization in [initState](file:///c:/Users/SADINSA/Desktop/IT%20Project/Mobile%20Application/Beta/small_store_app/frontend/lib/features/auth/presentation/screens/login_screen.dart#21-26) and updated the input hint from "Email or Username" to "Email or Phone".
- Refactored [auth_repository_impl.dart](file:///c:/Users/SADINSA/Desktop/IT%20Project/Mobile%20Application/Beta/small_store_app/frontend/lib/features/auth/data/repositories/auth_repository_impl.dart) to send `identifier` along with the password, removing the hardcoded `email` payload key.
- Improved the general error parsing within [api_client.dart](file:///c:/Users/SADINSA/Desktop/IT%20Project/Mobile%20Application/Beta/small_store_app/frontend/lib/core/network/api_client.dart) so backend `res.status(...).json({ error: "xyz" })` causes frontend exceptions with text "xyz" (e.g., "Account already exists") instead of the "Failed to load data: 409" generic fallback.

## Navigation and Flow
- **Splash Screen**: Auto-redirects to LoginScreen after 3 seconds.
- **Login Screen**: Uses the demo credentials on load. Supports toggling password visibility and navigating to "Apply for Partnership".
- **Register Screen**: Uses all demo credentials on load. Submitting creates a new owner through [AuthController](file:///c:/Users/SADINSA/Desktop/IT%20Project/Mobile%20Application/Beta/small_store_app/backend/src/interfaces/controllers/AuthController.js#1-51) and proceeds to [MainShell](file:///c:/Users/SADINSA/Desktop/IT%20Project/Mobile%20Application/Beta/small_store_app/frontend/lib/shared/main_shell.dart#9-15) if `success`. Error states accurately appear above the register button directly via the newly parsed backend error values.
- **MainShell**: The successful auth action navigates permanently to the main app layout. No bugs or state leaks found.
