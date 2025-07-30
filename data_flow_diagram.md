# SMS Transaction Analyzer - Data Flow Diagram

## System Overview

The SMS Transaction Analyzer is a Flutter-based personal finance tracking application that processes SMS messages from mobile money services (eDahab and EVC) to automatically categorize and track financial transactions.

## Data Flow Diagram

```mermaid
graph TB
    %% External Data Sources
    SMS[📱 SMS Messages<br/>eDahab & EVC] --> SMS_Parser[SMS Parser<br/>Transaction.fromSms()]

    %% User Authentication Flow
    User[👤 User] --> Auth[Firebase Authentication]
    Auth --> UserDB[(Firebase Firestore<br/>Users Collection)]

    %% Device & Token Management
    Device[📱 Device Info] --> DeviceID[Device ID Generator]
    FCM[Firebase Cloud Messaging] --> FCMToken[FCM Token]
    DeviceID --> UserDB
    FCMToken --> UserDB

    %% SMS Processing Pipeline
    SMS_Parser --> TransactionModel[Transaction Model<br/>Parsed Data]
    TransactionModel --> Encryption[Data Encryption<br/>AES-256]
    Encryption --> LocalStorage[Local Storage<br/>SharedPreferences]
    Encryption --> CloudDB[(Firebase Firestore<br/>Transactions Collection)]

    %% Transaction Processing
    TransactionModel --> TransactionID[Transaction ID<br/>SHA-256 Hash]
    TransactionModel --> CategoryClassifier[Category Classifier<br/>eDahab/EVC]
    TransactionModel --> AmountExtractor[Amount Extractor<br/>Regex Pattern]
    TransactionModel --> PhoneExtractor[Phone Extractor<br/>Regex Pattern]
    TransactionModel --> DateExtractor[Date Extractor<br/>Regex Pattern]

    %% Budget Management
    User --> BudgetInput[Budget Input]
    BudgetInput --> BudgetModel[Budget Model]
    BudgetModel --> BudgetDB[(Firebase Firestore<br/>Budgets Collection)]

    %% Budget Monitoring
    CloudDB --> BudgetCalculator[Budget Calculator<br/>Spent vs Budget]
    BudgetCalculator --> BudgetDB
    BudgetDB --> CloudFunction[Cloud Function<br/>Budget Threshold Monitor]
    CloudFunction --> FCM
    FCM --> LocalNotifications[Local Notifications<br/>Budget Alerts]

    %% Dashboard & Analytics
    CloudDB --> Dashboard[Dashboard Screen<br/>Financial Analytics]
    Dashboard --> Charts[Charts & Graphs<br/>fl_chart]
    Dashboard --> Statistics[Statistics<br/>Income/Expense Totals]

    %% Search & Filter
    User --> SearchInput[Search Input]
    SearchInput --> SearchEngine[Search Engine<br/>Phone/Amount/Date]
    SearchEngine --> FilteredResults[Filtered Results]
    CloudDB --> SearchEngine

    %% Notifications System
    CloudFunction --> NotificationModel[Notification Model]
    NotificationModel --> NotificationDB[(Firebase Firestore<br/>Notifications Collection)]
    NotificationDB --> NotificationScreen[Notifications Screen]

    %% Data Security
    Encryption --> SecureStorage[Secure Storage<br/>flutter_secure_storage]
    SecureStorage --> EncryptionKey[Encryption Key<br/>AES-256]

    %% UI Components
    TransactionScreen[Transaction Screen<br/>Main Interface] --> SMS_Parser
    TransactionScreen --> Dashboard
    TransactionScreen --> BudgetScreen[Budget Screen]
    TransactionScreen --> NotificationScreen

    %% Styling
    classDef external fill:#e1f5fe
    classDef process fill:#f3e5f5
    classDef storage fill:#e8f5e8
    classDef ui fill:#fff3e0
    classDef security fill:#ffebee

    class SMS,User,Device external
    class SMS_Parser,TransactionModel,BudgetModel,NotificationModel process
    class UserDB,CloudDB,BudgetDB,NotificationDB,LocalStorage storage
    class TransactionScreen,Dashboard,BudgetScreen,NotificationScreen ui
    class Encryption,SecureStorage,EncryptionKey security
```

## Detailed Data Flow Description

### 1. Authentication & User Management

- **Input**: User credentials (email/password)
- **Process**: Firebase Authentication
- **Storage**: User document in Firestore with device ID and FCM token
- **Output**: Authenticated user session

### 2. SMS Processing Pipeline

- **Input**: Raw SMS messages from eDahab and EVC services
- **Process**:
  - Parse SMS content using regex patterns
  - Extract transaction amount, phone number, date
  - Classify transaction type (income/expense)
  - Generate unique transaction ID using SHA-256 hash
- **Storage**: Encrypted transaction data in Firestore
- **Output**: Structured transaction objects

### 3. Budget Management Flow

- **Input**: User-defined monthly budget
- **Process**:
  - Calculate spent amount from transactions
  - Monitor budget thresholds (50%, 90%, 100%)
  - Trigger notifications via Cloud Functions
- **Storage**: Budget data in Firestore
- **Output**: Budget alerts and spending analytics

### 4. Analytics & Dashboard

- **Input**: Transaction data from Firestore
- **Process**:
  - Filter transactions by date range
  - Calculate income/expense totals
  - Generate charts and statistics
- **Output**: Visual financial reports and insights

### 5. Search & Filtering

- **Input**: Search criteria (phone number, amount, date)
- **Process**: Query Firestore with filters
- **Output**: Filtered transaction results

### 6. Notification System

- **Input**: Budget threshold events
- **Process**: Cloud Function triggers FCM notifications
- **Storage**: Notification records in Firestore
- **Output**: Local and push notifications

## Key Data Models

### Transaction Model

```dart
{
  isExpense: boolean,
  amount: double,
  phoneNumber: string,
  date: DateTime,
  originalMessage: string,
  category: string, // 'eDahab' or 'EVC'
  transactionID: string // SHA-256 hash
}
```

### Budget Model

```dart
{
  amount: double,
  month: DateTime,
  spent: double,
  userId: string,
  notified50: boolean,
  notified90: boolean,
  notified100: boolean
}
```

### Notification Model

```dart
{
  id: string,
  title: string,
  body: string,
  timestamp: DateTime,
  isRead: boolean,
  userId: string
}
```

## Security Features

- **Data Encryption**: AES-256 encryption for sensitive data
- **Secure Storage**: Encrypted local storage for keys
- **Authentication**: Firebase Auth with email/password
- **Device Binding**: Device ID tracking for security

## External Dependencies

- **Firebase Services**: Authentication, Firestore, Cloud Functions, Cloud Messaging
- **SMS Processing**: Telephony package for SMS access
- **Charts**: fl_chart for data visualization
- **Encryption**: encrypt package for data security
- **Notifications**: flutter_local_notifications for local alerts

## Data Flow Summary

1. **SMS Collection** → **Parsing** → **Encryption** → **Cloud Storage**
2. **User Input** → **Authentication** → **User Profile Creation**
3. **Budget Input** → **Threshold Monitoring** → **Notification Triggers**
4. **Transaction Data** → **Analytics Processing** → **Dashboard Visualization**
5. **Search Queries** → **Filtered Results** → **User Interface Display**
