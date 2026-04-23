# InspectSync Mobile Application

> **Tactical Field Operations Interface** — Built with Flutter.

This is the mobile client for the InspectSync platform. It is designed for engineers operating in challenging field environments, providing a high-performance, offline-first experience with robust data synchronization.

---

## ✨ Core Features

- **🔄 Synchronized Offline Mode**: Perform inspections in dead zones. Changes are queued and synced automatically when back online.
- **🛡️ Conflict Resolution UI**: Elegant side-by-side comparison for resolving data mismatches with the server.
- **📍 Location Intelligence**: Integrated maps for task visualization and precision coordinate capture.
- **🌑 Obsidian Command Theme**: A premium dark-mode aesthetic optimized for high-contrast field visibility.
- **📸 Secure Media Evidence**: Capture and upload inspection photos directly to AWS S3 using secure presigned URLs.

---

## 🏗️ Architecture

The app follows a **Feature-First Layered Architecture**, emphasizing separation of concerns and testability.

- **Presentation Layer**: BLoC / ChangeNotifier for state management, organized by feature.
- **Domain Layer**: Services and Business Logic (e.g., `SyncService`, `ConflictResolver`).
- **Data Layer**: 
    - **Local**: Drift (SQLite) for persistent state.
    - **Remote**: Dio for REST API communication.

---

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev)
- **Database**: [Drift](https://drift.simonbinder.eu/) (Reactive SQLite)
- **Routing**: [GoRouter](https://pub.dev/packages/go_router)
- **Networking**: [Dio](https://pub.dev/packages/dio)
- **State Management**: [Provider](https://pub.dev/packages/provider) / [ChangeNotifier](https://api.flutter.dev/flutter/foundation/ChangeNotifier-class.html)
- **Maps**: [flutter_map](https://pub.dev/packages/flutter_map) (OpenStreetMap)

---

## 📱 Screenshots

| Dashboard | Tasks | Sync Status |
|-----------|-------|-------------|
| *[Screenshot Placeholder]* | *[Screenshot Placeholder]* | *[Screenshot Placeholder]* |

*Note: Replace these placeholders with actual screenshots from your build.*

---

## 🚀 Getting Started

### 1. Prerequisites
- Flutter SDK `^3.11.0` (as defined in `pubspec.yaml`)
- A running instance of the [InspectSync Backend](../inspect-backend)

### 2. Installation
```bash
flutter pub get
```

### 3. Environment Configuration
Create a `.env` file or modify the API base URL in `lib/core/api/api_client.dart`:
```dart
static const String baseUrl = 'http://localhost:3000/api';
```

### 4. Run Analysis & Tests
```bash
# Analyze for lint issues
dart analyze

# Run unit tests
flutter test
```

---

## 🛡️ Design Philosophy

The application implements the **Tactical Architect** design system:
- **Tonal Layering**: Uses color separation instead of heavy shadows for depth.
- **High-Contrast Text**: Utilizes `Manrope` and `Inter` fonts for readability.
- **Interaction Feedback**: Smooth transitions and Haptic-ready interaction patterns.

---

Built by **[Shourya Sonu](https://github.com/shouryasonu)**
