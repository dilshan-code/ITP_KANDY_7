# ClickBuy - Grocery Shop Manager

ClickBuy is a modern, full-stack application designed to streamline inventory management, sales tracking, and customer credit for small to medium-sized grocery stores. It features a premium, iOS-inspired mobile interface and a robust Node.js backend.

## 🚀 Key Features

- **Multi-tenant Core**: Secure data isolation using `ownerId` scoping across the entire stack.
- **Inventory Management**: Real-time tracking of product stock, categories, and inventory value with out-of-stock alerts.
- **Sales System**: Efficient cart management and payment processing with automatic stock updates.
- **Customer Credit Tracking**: Dedicated module for managing debtors, credit settlements, and credit limit alerts.
- **Robust Validation**: Centralized, dual-layer validation system (frontend/backend) for maximum data integrity.
- **Enhanced Notifications**: Advanced system for low-stock, out-of-stock, and credit limit alerts with icon badges.
- **Premium UI/UX**: iOS-inspired design with repositioned snackbars for a clutter-free experience.

## 🛠 Tech Stack

### Frontend
- **Framework**: [Flutter](https://flutter.dev/)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Styling**: Modern Material Design with custom iOS-style components.
- **Networking**: `http` package for REST API communication.

### Backend
- **Core**: Node.js & [Express](https://expressjs.com/)
- **Database**: [MongoDB Atlas](https://www.mongodb.com/cloud/atlas) (via [Mongoose](https://mongoosejs.com/))
- **Architecture**: Clean architecture with Use Cases, Interfaces, and Infrastructure layers (Repositories).

## 📂 Project Structure

```text
small_store_app/
├── frontend/           # Flutter application source code
│   ├── lib/
│   │   ├── core/       # Shared utilities, themes, and network logic (includes SnackBarUtils)
│   │   ├── features/   # Feature-based modules (Products, Sales, Auth, etc.)
│   │   └── shared/     # Shared UI components & navigation (MainShell)
├── backend/            # Node.js API server
│   ├── src/
│   │   ├── domain/     # Business entities (Mongoose Schemas)
│   │   ├── usecases/   # Business logic / application services
│   │   ├── interfaces/ # Controllers and route definitions
│   │   └── infrastructure/ # Database repositories (MongoDB/Mongoose)
└── README.md           # Project documentation
```

## ⚙️ Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Node.js](https://nodejs.org/) (v14+)
- **MongoDB Connection**: 
    > [!IMPORTANT]
    > Create a `.env` file in the `backend/` directory with your `MONGODB_URI`.
    > Example: `MONGODB_URI=mongodb+srv://<user>:<password>@cluster.mongodb.net/clickbuy`

- **Cloudinary Account**:
    > [!IMPORTANT]
    > For product image uploads, you need a Cloudinary account. 
    > 1. Create a free account at [Cloudinary](https://cloudinary.com/).
    > 2. Create an **Unsigned** upload preset in Cloudinary Settings -> Upload.
    > 3. Update the configuration in `frontend/lib/core/config/cloudinary_config.dart` with your `cloudName` and `uploadPreset`.

### Setup

1. **Backend Setup**:
   ```bash
   cd backend
   npm install
   npm start
   ```

2. **Frontend Setup**:
   ```bash
   cd frontend
   flutter pub get
   flutter run
   ```

> [!TIP]
> **Android Emulator Connection**: The app is pre-configured to use `10.0.2.2:3000` to connect to the backend running on your host's localhost. Ensure the backend is running before launching the app on an Android emulator.

## 📖 Documentation & Maintenance

- **[bugs_and_fixes.md](file:///c:/Users/SADINSA/Desktop/IT%20Project/Mobile%20Application/Beta/small_store_app/bugs_and_fixes.md)**: A chronological log of every technical challenge resolved.
- **[system_improvements.md](file:///c:/Users/SADINSA/Desktop/IT%20Project/Mobile%20Application/Beta/small_store_app/system_improvements.md)**: A roadmap of architectural evolution and feature updates.

## 📄 License
This project is for internal use and development purposes.
