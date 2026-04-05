# 🛠️ ClickBuy: Entity-Relationship (ER) Diagram

This document contains the core Entity-Relationship (ER) data architecture for **ClickBuy**, a modern, full-stack application designed to streamline inventory management, sales tracking, and customer credit.

The diagram is written in Mermaid syntax and reflects the exact domain models used across both the ClickBuy backend (MongoDB Atlas) and frontend (Flutter).

```mermaid
erDiagram
    %% Entities
    OWNER {
        string id PK
        string ownerId "Used as identifier"
        string name
        string shopName
        string phone
        string email
        string password "Backend Only"
        datetime createdAt
        datetime updatedAt "Backend Only"
    }

    CUSTOMER {
        string id PK
        string ownerId FK "Multi-tenant ID"
        string name
        string phone
        string imageUrl
        number totalOutstanding
        number creditLimit
        string status
        datetime lastPurchase
        datetime createdAt
        datetime updatedAt "Backend Only"
    }

    SUPPLIER {
        string id PK
        string ownerId FK "Multi-tenant ID"
        string name
        string phone
        string address
        string email
        string notes
        string status
        number totalPayable
        datetime createdAt
        datetime updatedAt "Backend Only"
    }

    PRODUCT {
        string id PK
        string ownerId FK "Multi-tenant ID"
        string name
        string category
        number sellingPrice
        number purchasePrice
        number stockQuantity
        number minimumStockLevel
        string description
        string imageUrl
        string unit
        boolean notifyOutOfStock
        boolean isLowStock "Calculated"
        number inventoryValue "Calculated"
        datetime createdAt
        datetime updatedAt "Backend Only"
    }

    SALE {
        string id PK
        string ownerId FK "Multi-tenant ID"
        string customerId FK "Optional"
        string customerName
        array items "List of maps (products)"
        number subtotal
        number totalAmount
        string paymentMethod
        string status
        datetime createdAt
        datetime updatedAt "Backend Only"
    }

    PURCHASE {
        string id PK
        string ownerId FK "Multi-tenant ID"
        string supplierId FK "Optional"
        string supplierName
        string invoiceNumber
        datetime purchaseDate
        array items "List of maps (products for restock)"
        number subtotal
        number tax
        number totalAmount
        number amountPaid
        number remaining
        string status
        string notes
        datetime createdAt
        datetime updatedAt "Backend Only"
    }

    CREDIT_TRANSACTION {
        string id PK
        string ownerId FK "Multi-tenant ID"
        string customerId FK
        string type "credit or payment"
        string title
        number amount
        datetime date
        datetime createdAt
    }

    APP_NOTIFICATION {
        string id PK
        string ownerId FK "Multi-tenant ID"
        string type "warning, success, info, alert"
        string title
        string message
        boolean isRead
        datetime createdAt
    }

    %% Relationships
    CUSTOMER ||--o{ SALE : "makes"
    CUSTOMER ||--o{ CREDIT_TRANSACTION : "has"
    SUPPLIER ||--o{ PURCHASE : "provides"
    
    %% Note: SALE and PURCHASE embed 'items' arrays (document-style NoSQL JSON arrays) 
    %% that reflect snapshots of Product details at the time of transaction.
    SALE }o--|{ PRODUCT : "contains snapshot"
    PURCHASE }o--|{ PRODUCT : "contains snapshot"
```

## 📋 Architectural Notes

- **NoSQL Document Structure (MongoDB):** Since ClickBuy utilizes a MongoDB Atlas document database via Mongoose, relationships like `SALE <-> PRODUCT` or `PURCHASE <-> PRODUCT` are handled by embedding arrays of item snapshots rather than using strict foreign-key join tables. This guarantees historical invoice integrity and simplifies schema evolution.
- **Media Management (Cloudinary):** Product images are hosted externally on Cloudinary. The system persists only the secure URLs, while automated backend hooks manage the file lifecycle (delete/update) in sync with MongoDB records.
- **Authentication Layer (Firebase Phone OTP):** The primary entry point for Owners is Firebase Phone Authentication. The `phone` field in the `OWNER` entity serves as the unique identifier for account mapping across Firebase and Atlas.
- **Multi-tenant Core:** Every document is strictly scoped using an `ownerId` field, ensuring 100% data isolation between different shop owners across the Atlas cluster.
- **Calculated Fields (Frontend UI):** Several fields such as `Product.isLowStock` and `Product.inventoryValue` are dynamically provided via getters by the backend or evaluated globally to assist the frontend UI representation directly.
- **Customer & Supplier Relations:** A 1-to-Many relationship binds the customer profile to their checkout `SALE` records and `CREDIT_TRANSACTION` logs. Suppliers share a similar association tracing back through `PURCHASE` records.

---
*Architectural Document - ClickBuy Beta Environment.*
