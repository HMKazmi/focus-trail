# FocusTrail Mobile App

> A Flutter-based mobile task management application with offline-first architecture

![Flutter](https://img.shields.io/badge/Flutter-3.7.0+-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)
![License](https://img.shields.io/badge/license-MIT-green)

## 📱 Overview

The FocusTrail mobile app is a feature-rich task management application built with Flutter. It provides a seamless offline-first experience with automatic background synchronization, ensuring your tasks are always accessible regardless of network connectivity.

## ✨ Features

### Core Functionality
- **Task Management**: Create, edit, delete, and organize tasks
- **Priority Levels**: Categorize tasks as Low, Medium, or High priority
- **Status Tracking**: Track tasks through To Do, In Progress, and Done stages
- **Search & Filter**: Quickly find tasks by title, status, or priority
- **Due Dates**: Set and track task deadlines with visual indicators

### Advanced Features
- **Dashboard Analytics**: Visualize productivity with interactive charts
- **Trash Bin**: Safely delete and restore tasks within 30 days
- **Smart Reminders**: Get notified about upcoming and overdue tasks
- **Data Export**: Export tasks as CSV or JSON
- **Offline-First**: Full functionality without internet connection
- **Background Sync**: Automatic synchronization when online
- **Remember Me**: Stay logged in across app sessions

### UI/UX
- Modern glassmorphism design
- Smooth animations and transitions
- Pull-to-refresh functionality
- Empty state illustrations
- Loading indicators
- Error handling with user-friendly messages

## 🏗️ Architecture

The app follows Clean Architecture principles with feature-based organization:

```
lib/
├── core/
│   ├── config/          # App configuration
│   ├── network/         # API client (Dio)
│   └── utils/           # Utilities & logger
│
├── features/
│   ├── auth/
│   │   ├── data/        # Data layer (repos, models)
│   │   └── presentation/ # UI layer (pages, widgets, providers)
│   │
│   ├── tasks/
│   │   ├── data/        # Task repository, sync service
│   │   └── presentation/ # Task list, form, providers
│   │
│   ├── dashboard/       # Analytics & statistics
│   ├── trash/           # Trash bin feature
│   ├── reminders/       # Reminder management
│   └── export/          # Data export
│
├── main.dart            # App entry point
├── app.dart             # Root widget
└── router.dart          # Navigation routes
```

### Key Design Patterns

- **Repository Pattern**: Abstracts data sources
- **Provider Pattern**: State management with Riverpod
- **Dependency Injection**: Loose coupling between layers
- **Feature-First**: Organized by business features

## 🛠️ Tech Stack

| Category | Technology |
|----------|-----------|
| Framework | Flutter 3.7.0+ |
| Language | Dart 3.0+ |
| State Management | Riverpod 2.0+ |
| Routing | go_router |
| Local Database | Hive |
| HTTP Client | Dio |
| Charts | fl_chart |
| JSON Serialization | json_annotation |

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.7.0 or higher
- Dart SDK 3.0 or higher
- Android Studio / Xcode (for platform builds)
- VS Code or Android Studio (recommended IDEs)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/FocusTrail.git
   cd FocusTrail/app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API endpoint**
   
   Edit `lib/core/config/api_config.dart`:
   ```dart
   class ApiConfig {
     static const String baseUrl = 'http://your-api-url:4000/api';
   }
   ```

4. **Run the app**
   ```bash
   # For development
   flutter run
   
   # For specific device
   flutter run -d <device-id>
   
   # Release build
   flutter run --release
   ```

### Building for Production

#### Android
```bash
flutter build apk --release          # APK
flutter build appbundle --release    # App Bundle (for Play Store)
```

#### iOS
```bash
flutter build ios --release
```

## 📝 Configuration

### API Configuration

Edit `lib/core/config/api_config.dart`:

```dart
class ApiConfig {
  static const String baseUrl = 'http://localhost:4000/api';
  static const Duration timeout = Duration(seconds: 30);
  static const int maxRetries = 3;
}
```

### App Configuration

The app uses Hive for local storage with these boxes:
- `auth_box`: Stores authentication tokens and user data
- `tasks_box`: Local task cache
- `sync_box`: Sync operation queue
- `settings_box`: App settings and preferences

## 🧪 Testing

### Run Tests
```bash
# All tests
flutter test

# With coverage
flutter test --coverage

# Specific test file
flutter test test/task_dto_test.dart
```

### Test Structure
```
test/
├── unit/              # Unit tests
├── widget/            # Widget tests
└── integration/       # Integration tests
```

## 📊 State Management

The app uses Riverpod for state management. Key providers:

### Auth Providers
```dart
authProvider          // Authentication state
authRepositoryProvider // Auth repository
```

### Task Providers
```dart
taskProvider          // Task list state
taskFormProvider      // Task form state
syncStateProvider     // Sync status
```

### Dashboard Providers
```dart
dashboardProvider     // Dashboard data
chartDataProvider     // Chart data
```

## 🔄 Offline-First Sync

### How it Works

1. **Offline Operations**: All CRUD operations work offline
2. **Sync Queue**: Operations stored in local queue
3. **Background Sync**: Automatic sync when connection restored
4. **Conflict Resolution**: Server data takes precedence
5. **Optimistic Updates**: UI updates immediately

### Sync Operations

```dart
enum SyncOpType {
  create,   // Create new task
  update,   // Update existing task
  delete,   // Delete permanently
  trash,    // Move to trash
}
```

## 🎨 Theming

The app uses a custom glassmorphism theme:

```dart
// Primary colors
primaryColor: Color(0xFF6366F1)  // Indigo
accentColor: Color(0xFF8B5CF6)   // Purple

// Background
scaffoldBackground: Linear gradient with glassmorphism

// Card style
cardDecoration: Frosted glass effect with blur
```

## 📱 Screens

### Authentication
- **Login Screen**: Email/password login with Remember Me
- **Register Screen**: New user registration

### Main Features
- **Task List**: Display all tasks with search and filters
- **Task Form**: Create/edit tasks with full details
- **Dashboard**: Analytics with charts and statistics
- **Trash Bin**: View and restore deleted tasks
- **Reminders**: Manage task reminders
- **Export**: Export data as CSV/JSON

## 🔐 Security

- JWT token authentication
- Secure token storage in Hive
- Encrypted local database
- HTTPS communication (production)
- Input validation and sanitization

## 🐛 Debugging

### Enable Logging

The app includes comprehensive logging:

```dart
AppLogger.info('Message', module: 'ModuleName');
AppLogger.error('Error', error: e, stackTrace: stackTrace);
```

### Common Issues

**Issue**: App won't connect to API
```
Solution: Check API_BASE_URL in api_config.dart
         Ensure backend is running
         Check network permissions in AndroidManifest.xml
```

**Issue**: Sync not working
```
Solution: Check internet connection
         Verify auth token is valid
         Check sync queue in Hive
```

## 📦 Dependencies

### Core Dependencies
```yaml
# State Management
flutter_riverpod: ^2.0.0

# Routing
go_router: ^6.0.0

# Local Storage
hive: ^2.2.3
hive_flutter: ^1.1.0

# HTTP
dio: ^5.0.0

# Charts
fl_chart: ^0.60.0

# JSON
json_annotation: ^4.8.0
```

## 🚢 Deployment

### Android Deployment

1. **Update version** in `pubspec.yaml`
2. **Generate keystore** (first time only)
   ```bash
   keytool -genkey -v -keystore ~/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key
   ```
3. **Configure signing** in `android/app/build.gradle`
4. **Build release**
   ```bash
   flutter build appbundle --release
   ```

### iOS Deployment

1. **Update version** in Xcode
2. **Configure certificates** in Apple Developer
3. **Build archive**
   ```bash
   flutter build ios --release
   ```
4. **Submit via Xcode**

## 📈 Performance

### Optimization Techniques
- Lazy loading of lists
- Image caching
- Efficient state updates
- Background sync throttling
- Pagination for large datasets

## 🤝 Contributing

1. Follow Flutter style guide
2. Write tests for new features
3. Update documentation
4. Run `flutter analyze` before committing
5. Ensure all tests pass

## 📄 License

This project is part of FocusTrail and is licensed under the MIT License.

---

For issues and questions, please refer to the main repository README.
