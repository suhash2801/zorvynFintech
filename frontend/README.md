# zorvyn Finace application

A new Flutter project.

## Getting Started


Prerequisites
Flutter SDK (Stable)

Node.js (v16 or higher)

MongoDB Community Server
----------------------------------------------------------------------------------------------------------------

**1. Backend Setup**

In Terminal 
----------------------------------------------------------------------------------------------------------------
cd backend

npm install

----------------------------------------------------------------------------------------------------------------
 Ensure MongoDB is running (brew services start mongodb-community)
 
---------------------------------------------------------------------------------------------------------------- 
npm start

nodemon server.js


----------------------------------------------------------------------------------------------------------------
**2. Frontend Setup**

In Terminal
----------------------------------------------------------------------------------------------------------------
cd frontend

flutter pub get

----------------------------------------------------------------------------------------------------------------
 Generate Launcher Icons
dart run flutter_launcher_icons
 Run on connected device
 
 ----------------------------------------------------------------------------------------------------------------
flutter run

----------------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------------

** Features**

Real-time Dashboard: Track total balance, monthly income, and current day expenses.

Financial Insights: * Weekly Comparison: Automated logic to compare current week vs. last week spending.

Categorized Spending: Dynamic horizontal bar charts using fl_chart.

Top Expense Source: Identifies the highest spending category automatically.

Streak System: Maintains a daily logging streak to encourage financial consistency.

Local Notifications: Scheduled reminders for daily logging (Android 13+ compatible).

Pull-to-Refresh: Instant data synchronization with the MongoDB backend.

-----------------------------------------------------------------------------------------------------

**TECHSTACK**

**Frontend (Mobile App)**

Framework: Flutter (Dart) – Used for building the cross-platform UI for your MacBook Air and Android device (CPH2613).

State Management: Riverpod (v2.6.1) – Specifically StateNotifierProvider to manage the asynchronous state of your transactions and insights.

Data Visualization: fl_chart – Powers the dynamic, horizontally scrollable bar charts in the Insights screen.

Local Storage & Notifications: flutter_local_notifications – Handles the daily logging reminders and ensures they persist after a phone reboot.

Icons: flutter_launcher_icons – Used to automate the generation of your custom app logo across different Android densities.

----------------------------------------------------------------------------------------------------------------

**Backend (Server Logic)**
Runtime: Node.js – The engine running your server-side logic.

Framework: Express.js – Used to build the RESTful API endpoints that your Flutter app calls (e.g., GET /transactions, POST /add-transaction).

Environment Management: Dotenv – Manages sensitive environment variables like port numbers and connection strings.

----------------------------------------------------------------------------------------------------------------

**Database (Storage)**

Database: MongoDB (Community Server) – A NoSQL database used to store transaction JSON objects.

ODM: Mongoose – An Object Data Modeling library for MongoDB and Node.js. It provides a schema-based solution to model your application data (Amount, Date, Type, Category).

GUI: MongoDB Compass – Used for visually inspecting your transaction logs and verifying if dates are stored in UTC.

----------------------------------------------------------------------------------------------------------------

** Dev Ops & Tools**

Version Control: Git – (As reflected in your request for a GitHub-style README).

Package Managers: NPM (for Backend) and Pub (for Flutter).

Process Management: Launchctl (macOS) – Used to keep the MongoDB service running in the background of your Mac.

API Testing: Postman or Thunder Client – Essential for testing the connection between 127.0.0.1:3000 and the database before connecting the Flutter frontend.

----------------------------------------------------------------------------------------------------------------
** Connection Layer**

Protocol: HTTP/JSON – The "language" spoken between your Flutter app and the Node.js server.

Addressing: IPv4 (127.0.0.1) – Specifically used to ensure stable communication between your frontend and local database, bypassing common IPv6 localhost resolution errors.
