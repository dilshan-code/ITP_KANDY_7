# 🛠️ ClickBuy: Entity-Relationship (ER) Diagram

This document contains the core Entity-Relationship (ER) data architecture for **ClickBuy**, a modern, full-stack application designed to streamline inventory management, sales tracking, and customer credit.

The diagram is written in Mermaid syntax and reflects the exact domain models used across both the ClickBuy backend (Firestore) and frontend (Flutter).

```mermaid
erDiagram
    %% Entities
    OWNER {
        string id PK
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
        string name
        string category
        number sellingPrice
        number stockQuantity
        number minimumStockLevel
        string description
        string imageUrl
        string unit
        boolean isLowStock "Calculated"
        number inventoryValue "Calculated"
        datetime createdAt
        datetime updatedAt "Backend Only"
    }

    SALE {
        string id PK
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
        string customerId FK
        string type "credit or payment"
        string title
        number amount
        datetime date
        datetime createdAt
    }

    APP_NOTIFICATION {
        string id PK
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

- **NoSQL Document Structure:** Since ClickBuy utilizes a Firestore-like document database, relationships like `SALE <-> PRODUCT` or `PURCHASE <-> PRODUCT` are handled by embedding arrays of item snapshots rather than using strict foreign-key join tables. This guarantees historical invoice integrity if product prices or names change later.
- **Calculated Fields (Frontend UI):** Several fields such as `Product.isLowStock` and `Product.inventoryValue` are dynamically provided via getters by the backend or evaluated globally to assist the frontend UI representation directly.
- **Backend vs Frontend Models:** The `updatedAt` field acts generally as an internal backend timestamp hook for syncing, while it is primarily omitted in the dart-level app state models for simplicity.
- **Customer & Supplier Relations:** A 1-to-Many relationship binds the customer profile to their checkout `SALE` records and `CREDIT_TRANSACTION` logs. Suppliers share a similar association tracing back through `PURCHASE` records.

---
*Architectural Document - ClickBuy Beta Environment.*
