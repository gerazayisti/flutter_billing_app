# 🛒 Mobile POS & Billing App 

A feature-rich, high-performance offline-first billing and Point of Sale (POS) application built with Flutter. Designed for seamless retail checkout operations featuring barcode scanning, thermal Bluetooth printing, and robust local data persistence.

## 🌟 New Features (v1.1)

- **🔐 Role-Based Access Control (RBAC)**: Secure system with Admin and Cashier roles. Admins have full control, while Cashiers are limited to selling and viewing their history.
- **📄 Professional PDF Reports**: Generate detailed financial reports (Daily, Weekly, Monthly) directly from the app. Includes transaction details and category summaries.
- **👥 User Management**: Admins can manage staff accounts, set PIN codes, and assign roles.
- **💾 Automated Backups**: Export and import your entire database as a JSON file for safety or device migration.

## 🎯 Project Scope

This application serves as a complete offline POS system for small to medium-sized retail shops. It streamlines the checkout process, catalog management, and receipt generation securely entirely on-device.

### Core Features:
- **Product Management System**: Complete CRUD operations for inventory items with barcode/QR code support.
- **Smart Checkout System**: Rapid cart building via camera-based barcode scanning or manual entry, and robust order calculation functionality.
- **Bluetooth Thermal Printing**: Direct integration with thermal printers (`print_bluetooth_thermal`) to instantly output physical receipts.
- **Shop Settings & Customization**: Centrally managed shop details printed dynamically on receipts.
- **Offline-First Architecture**: Powered by `Hive` for lightning-fast localized NoSQL data storage. No active internet connectivity required.

## 🛠 Tech Stack & Architecture

Built leveraging industry-standard architectural principles (Clean Architecture & Feature-Driven Design) ensuring scalability, separation of concerns, and robust testability. 

- **Framework**: [Flutter](https://flutter.dev/) (SDK >=3.1.0)
- **State Management**: `flutter_bloc`
- **Dependency Injection**: `get_it`
- **Routing**: `go_router`
- **Local Database**: `hive` & `hive_flutter`
- **Reporting**: `pdf` & `printing`
- **Hardware Integrations**: `mobile_scanner` (barcodes), `print_bluetooth_thermal`

## 📁 File Structure

The codebase is organized using a **Feature-First Clean Architecture** utilizing domain-driven concepts.

```text
lib/
├── core/                       # Core application utilities and shared components
│   ├── theme/                  # UI aesthetics, typography, styling
│   ├── utils/                  # Helpers (ReportService, BackupService, PrinterHelper)
│   ├── widgets/                # Reusable global UI widgets (AppDrawer, Buttons)
│   └── service_locator.dart    # get_it dependency injection setup
│
└── features/                   # Independent feature modules
    ├── auth/                   # RBAC, Login, User Management
    ├── billing/                # Core POS operations: Cart, Checkout, Order History
    ├── dashboard/              # Financial Analytics & Reporting UI
    ├── product/                # Inventory management
    ├── settings/               # App configuration & Printer connections
    └── shop/                   # Shop details configuration
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `^3.1.0` or higher
- Android Studio / Xcode for building.

### Installation

1. Clone and install:
   ```bash
   flutter pub get
   ```

2. Run code generation:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

3. Run the project:
   ```bash
   flutter run
   ```

## 🤝 Contributing Guidelines
1. **Clean Architecture Rules**: Maintain strict boundaries between layers.
2. **Immutable States**: Emit only immutable states from BLoCs.
3. **No Direct Exceptions**: Utilize `fpdart`'s `Either` pattern for error handling.
