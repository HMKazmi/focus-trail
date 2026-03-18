# Productivity Tracker

A cross-platform, offline-first task management app built with Flutter.  
Targets **Android**, **Windows**, and **Web**.

## Architecture

```
lib/
  core/
    config/        – API base URL & environment settings
    theme/         – Material 3 light/dark themes, theme provider
    network/       – Dio HTTP client with auth interceptor, connectivity
    storage/       – Hive initialisation & box constants
    utils/         – Result type, error mapping, breakpoints
  features/
    auth/
      data/        – DTOs, remote/local datasources, repository impl
      domain/      – UserEntity, AuthRepository contract
      presentation/– Login/Register pages, auth state provider
    tasks/
      data/        – TaskDto, remote/local datasources, sync queue, sync service, repo impl
      domain/      – TaskEntity, TaskRepository contract
      presentation/– Task list, form, shell, providers, widgets
    settings/
      presentation/– Settings page (theme, base URL, sync info, logout)
  app.dart         – MaterialApp.router entry
  router.dart      – go_router configuration
  main.dart        – bootstrap (Hive init → ProviderScope → app)
```

### Key Patterns
| Concern | Solution |
|---|---|
| State management | flutter_riverpod (StateNotifier) |
| Routing | go_router with auth redirect |
| Networking | Dio + auth interceptor |
| Local storage | Hive (tasks, auth, sync queue, settings) |
| Offline-first | Local Hive is source of truth; SyncService pushes a queue to the API |
| Responsive | NavigationRail on wide screens, BottomNav on narrow |
| Theming | Material 3 with light/dark modes |

## Offline-First Behaviour

1. **All CRUD operations write to Hive immediately** and are reflected in the UI.  
2. Each mutation is **enqueued** as a `SyncOperation` (create / update / delete + payload + timestamp).  
3. `SyncService` runs:
   - **Periodically** (every 30 seconds)
   - **On app start** (initial task load with `forceRefresh`)
   - **On manual trigger** (sync button in app bar / settings)
4. During sync the queue is flushed in order, then a full pull from the server replaces local data (**last-write-wins** by `updatedAt`).
5. An **offline banner** appears when connectivity is lost. A **badge** shows the pending operation count.

## Running the App

### Prerequisites
- Flutter SDK ≥ 3.7
- The backend server running (see `/server`)

### Install dependencies
```bash
cd app
flutter pub get
```

### Android
```bash
flutter run -d android
```
> The app auto-detects the Android emulator and uses `10.0.2.2:4000` as the base URL.

### Windows
```bash
flutter run -d windows
```

### Web
```bash
flutter run -d chrome
```

### Pointing to the Server
The default base URL is `http://localhost:4000`.  
For Android emulator it's `http://10.0.2.2:4000`.

You can **override the base URL at runtime** from **Settings → API Base URL** (stored in Hive, persists across sessions). A restart is recommended for the Dio client to pick up the change.

You can also edit `lib/core/config/app_config.dart` directly.

## Running Tests
```bash
cd app
flutter test
```

This runs:
- `test/task_dto_test.dart` – unit tests for TaskDto ↔ TaskEntity mapping
- `test/widget_test.dart` – widget tests for empty state and task card UI

## API Contract (matches /server)

| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/auth/register` | Register a new user |
| POST | `/api/auth/login` | Login → `{accessToken, user}` |
| GET | `/api/tasks` | List all tasks (auth required) |
| POST | `/api/tasks` | Create a task |
| PUT | `/api/tasks/:id` | Update a task |
| DELETE | `/api/tasks/:id` | Delete a task |

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
