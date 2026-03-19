# ClickBuy - Grocery Shop Manager

ClickBuy is a modern, full-stack application designed to streamline inventory management, sales tracking, and customer credit for small to medium-sized grocery stores. It features a premium, iOS-inspired mobile interface and a robust Node.js backend.

## 🚀 Key Features

- **Inventory Management**: Real-time tracking of product stock, categories, and inventory value.
- **Sales System**: Efficient cart management and payment processing.
- **Customer Credit Tracking**: Dedicated module for managing debtors and credit transactions.
- **Supplier Module**: Keep track of purchases and supplier relationships.
- **Enhanced Notifications**: A robust notification system for low-stock alerts and business updates, dynamically aligned to clear the status bar and notch on mobile devices.
- **Premium UI/UX**: Optimized for speed and aesthetics with a modern, clean design.

## 🛠 Tech Stack

### Frontend
- **Framework**: [Flutter](https://flutter.dev/)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Styling**: Modern Material Design with custom iOS-style components.
- **Networking**: `http` package for REST API communication.

### Backend
- **Core**: Node.js & [Express](https://expressjs.com/)
- **Database**: [Firebase Firestore](https://firebase.google.com/docs/firestore)
- **Admin**: Firebase Admin SDK
- **Architecture**: Clean architecture with Use Cases, Interfaces, and Infrastructure layers.

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
│   │   ├── domain/     # Business entities
│   │   ├── usecases/   # Business logic / application services
│   │   ├── interfaces/ # Controllers and route definitions
│   │   └── infrastructure/ # Database repositories (Firestore)
└── README.md           # Project documentation
```

## ⚙️ Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Node.js](https://nodejs.org/) (v14+)
- **Firebase Service Account**: Ensure `serviceAccountKey.json` is placed in the `backend` root.

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

## 📄 License
This project is for internal use and development purposes.
