# ClickBuy - Data Flow Diagram (DFD) Reference

This document provides a Data Flow Diagram (DFD) for the ClickBuy Grocery Shop Manager system for your reference.

## Level 0: Context Diagram
The Context Diagram shows the system as a single process and its interactions with external entities.

```mermaid
graph TD
    Manager((Store Manager))
    System[ClickBuy System]
    DB[(Firebase Firestore)]

    Manager -- "Login Credentials" --> System
    Manager -- "Product & Sale Entries" --> System
    System -- "Authentication Status" --> Manager
    System -- "Reports & Notifications" --> Manager

    System -- "CRUD Operations" --> DB
    DB -- "Stored Data Updates" --> System
```

---

## Level 1: Functional Decomposition
The Level 1 DFD breaks down the system into its primary functional modules and shows the data flow between them.

```mermaid
graph TD
    Manager((Store Manager))
    DB[(Firebase Firestore)]

    subgraph ClickBuy System
        P1[Authentication Module]
        P2[Inventory Management]
        P3[Sales & Transactions]
        P4[Customer Credit Tracking]
        P5[Supplier & Purchase Mgmt]
        P6[Notifications & Analytics]
    end

    %% Auth Flow
    Manager -- "Credentials" --> P1
    P1 -- "Auth Token / Status" --> Manager
    P1 -- "User Data" --> DB

    %% Inventory Flow
    Manager -- "Product Info / Category" --> P2
    P2 -- "Stock Updates / Product CRUD" --> DB
    DB -- "Inventory Data" --> P2
    P2 -- "Low Stock Trigger" --> P6

    %% Sales Flow
    Manager -- "Cart Items / Payments" --> P3
    P3 -- "Invoice / Transaction Summary" --> Manager
    P3 -- "Deduct Stock" --> P2
    P3 -- "Sale Records" --> DB

    %% Customer Credit Flow
    Manager -- "Debtor Details / Payments" --> P4
    P4 -- "Credit Transactions" --> DB
    P4 -- "Credit Status Report" --> Manager
    P3 -- "Credit Sale Entry" --> P4

    %% Supplier & Purchase Flow
    Manager -- "Purchase Invoices" --> P5
    P5 -- "Purchase Records" --> DB
    P5 -- "Add to Stock" --> P2
    DB -- "Supplier Lists" --> P5

    %% Notifications & Analytics
    DB -- "Aggregated Metrics" --> P6
    P6 -- "Low Stock & Business Alerts" --> Manager
    P6 -- "Performance Reports" --> Manager
```

## Key Data Entities
- **Products**: Stores items, barcodes, prices, and stock levels.
- **Sales**: Records of completed transactions and individual invoice items.
- **Customers**: Profiles for credit-eligible customers and their current balance.
- **Credit Transactions**: History of debts and repayments.
- **Suppliers**: Contact info and purchase history.
- **Notifications**: Log of system-generated alerts.
