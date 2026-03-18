import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/utils/logger.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/tasks/presentation/pages/task_shell_page.dart';
import 'features/tasks/presentation/pages/task_list_page.dart';
import 'features/tasks/presentation/pages/task_form_page.dart';
import 'features/settings/presentation/pages/settings_page.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'features/trash/presentation/pages/trash_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.token != null;
      final isAuthRoute =
          state.matchedLocation == '/login' || state.matchedLocation == '/register';

      AppLogger.navigation('Redirect check', state.matchedLocation);
      AppLogger.debug('Auth status: ${isLoggedIn ? "logged in" : "not logged in"}', module: 'Router');

      if (!isLoggedIn && !isAuthRoute) {
        AppLogger.navigation('Redirecting to login', '/login');
        return '/login';
      }
      if (isLoggedIn && isAuthRoute) {
        AppLogger.navigation('Redirecting to tasks', '/tasks');
        return '/tasks';
      }
      
      AppLogger.debug('No redirect needed', module: 'Router');
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) {
          AppLogger.navigation('Building page', '/login');
          return const LoginPage();
        },
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) {
          AppLogger.navigation('Building page', '/register');
          return const RegisterPage();
        },
      ),
      ShellRoute(
        builder: (context, state, child) => TaskShellPage(child: child),
        routes: [
          GoRoute(
            path: '/tasks',
            builder: (context, state) {
              AppLogger.navigation('Building page', '/tasks');
              return const TaskListPage();
            },
          ),
          GoRoute(
            path: '/tasks/create',
            builder: (context, state) {
              AppLogger.navigation('Building page', '/tasks/create');
              return const TaskFormPage();
            },
          ),
          GoRoute(
            path: '/tasks/edit/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              AppLogger.navigation('Building page', '/tasks/edit/$id');
              return TaskFormPage(taskId: id);
            },
          ),
          GoRoute(
            path: '/dashboard',
            builder: (context, state) {
              AppLogger.navigation('Building page', '/dashboard');
              return const DashboardPage();
            },
          ),
          GoRoute(
            path: '/trash',
            builder: (context, state) {
              AppLogger.navigation('Building page', '/trash');
              return const TrashPage();
            },
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) {
              AppLogger.navigation('Building page', '/settings');
              return const SettingsPage();
            },
          ),
        ],
      ),
    ],
  );
});
