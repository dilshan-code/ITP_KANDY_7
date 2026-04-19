# ClickBuy - Grocery Shop Manager

ClickBuy is a modern, full-stack application designed to streamline inventory management, sales tracking, and customer credit for small to medium-sized grocery stores. It features a premium, iOS-inspired mobile interface and a robust Node.js backend.

## 🚀 Key Features

- **Multi-tenant Core**: Secure data isolation using `ownerId` scoping across the entire stack.
- **Inventory Management**: Real-time tracking of product stock, categories, and inventory value with out-of-stock alerts.
- **Supplier & Purchase Accounting**: Detailed tracking of historical purchase records with automated balance (actual debt) synchronization.
- **Sales System**: Efficient cart management and atomic payment processing with automatic stock updates and PDF invoicing.
- **Customer Credit Tracking**: Dedicated module for managing debtors, credit settlements, and credit limit alerts.
- **Standardized Business-First PDF Reporting**: Professional, high-fidelity PDF reporting engine with standardized layouts and full Unicode support across all business modules.
- **Server-Side Database Backup**: Integrated utility for administrators to trigger and download secure database collection archives.
- **UDP Auto-Discovery**: Automated backend discovery service that dynamically identifies the host machine's IP address on the local network.
- **Total Wipeout Control**: Coordinated, multi-collection data erasure system for total privacy compliance and account deletion.
- **Administrative Dashboard Evolution**: Specialized portal for system managers with advanced feedback filtering and owner triage tools.
- **Advanced Error Diagnostics**: Comprehensive technical breakdown of backend failures (mapping status codes like 404, 500) within the mobile interface.
- **Premium UI/UX**: iOS-inspired design with frosted glass elements and frosted mint aesthetics for a cluttered-free experience.

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
    > Create a `.env` file in the `backend/` directory. You can use `.env.example` as a template.
    > Example: `MONGODB_URI=mongodb+srv://<user>:<password>@cluster.mongodb.net/clickbuy`
    > 
    > **Blocked by Atlas?**: If the server exits immediately, your IP may not be whitelisted. 
    > Run `node src/utils/checkIp.js` in the `backend` folder to find your IP and add it to the Atlas console.

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
> **Dynamic Backend Discovery**: ClickBuy now features an automated UDP discovery service. When you launch the app on your local network, it will automatically attempt to identify the backend server's IP address. If it fails, you can manually configure the IP in the "Backend Settings" dialog available on the Login screen.

## 📖 Documentation & Maintenance

- **[bugs_and_fixes.md](./bugs_and_fixes.md)**: A chronological log of every technical challenge resolved.
- **[system_improvements.md](./system_improvements.md)**: A roadmap of architectural evolution and feature updates.

## 📄 License
This project is for internal use and development purposes.
