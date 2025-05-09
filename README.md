his is a Personal Finance Tracker mobile application built with Flutter. Here's a comprehensive overview:
Core Features:
Authentication System
User signup and login using Firebase Authentication
Device ID verification for security
Modern UI with gradient backgrounds and clean design
Transaction Management
SMS-based transaction tracking (supports eDahab and EVC services)
Automatic parsing of transaction details from SMS
Transaction categorization (Income/Expense)
Secure storage in Firebase Cloud Firestore
Dashboard & Analytics
Financial overview with income, expense, and profit cards
Visual representation using bar charts
Monthly comparison of financial data
Transaction filtering by date and phone number
Multi-device Support
Device verification system
Read-only access for secondary devices
Full access (including SMS processing) for primary device
User Interface
Dark theme with professional color scheme
Bottom navigation for easy access to different sections
Modern card-based transaction display
Interactive date selector
Search functionality for transactions
Technical Stack:
Frontend: Flutter
Backend: Firebase (Authentication, Firestore)
SMS Processing: Native SMS access
State Management: Built-in Flutter state management
Data Visualization: fl_chart library
Security: Device verification and Firebase security rules
Key Security Features:
Device ID verification
Secure transaction storage
Protected SMS access
Encrypted transaction IDs
User authentication
The app is designed to help users track their financial transactions automatically by processing SMS notifications from financial services (eDahab and EVC), providing a comprehensive view of their financial status with visual analytics and detailed transaction history.
