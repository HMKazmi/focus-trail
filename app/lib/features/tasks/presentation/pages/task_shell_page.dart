import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/connectivity_provider.dart';
import '../../../../core/utils/breakpoints.dart';
import '../../data/sync_service.dart';
import '../providers/task_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Adaptive shell: BottomNavigationBar on narrow, NavigationRail on wide.
class TaskShellPage extends ConsumerWidget {
  final Widget child;
  const TaskShellPage({super.key, required this.child});

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.check_circle_outline),
      label: 'Tasks',
    ),
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      label: 'Dashboard',
    ),
    NavigationDestination(icon: Icon(Icons.delete_outline), label: 'Trash'),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      label: 'Settings',
    ),
  ];

  int _indexFromRoute(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/dashboard')) return 1;
    if (location.startsWith('/trash')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  void _onTap(BuildContext context, int idx) {
    switch (idx) {
      case 0:
        context.go('/tasks');
        break;
      case 1:
        context.go('/dashboard');
        break;
      case 2:
        context.go('/trash');
        break;
      case 3:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= Breakpoints.compact;
    final idx = _indexFromRoute(context);
    final syncState = ref.watch(syncServiceProvider);
    final connectivity = ref.watch(connectivityProvider);
    final online = connectivity.when(
      data: (r) => isOnline(r),
      loading: () => true,
      error: (_, __) => true,
    );

    return Scaffold(
      body: Column(
        children: [
          // Offline banner
          if (!online)
            Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.errorContainer,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_off,
                    size: 16,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You are offline. Changes will sync when connectivity returns.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                  if (syncState.pendingCount > 0)
                    Chip(
                      label: Text('${syncState.pendingCount} pending'),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ),
          // Sync indicator bar
          if (syncState.isSyncing) const LinearProgressIndicator(minHeight: 2),
          // Body
          Expanded(
            child:
                isWide
                    ? Row(
                      children: [
                        NavigationRail(
                          selectedIndex: idx,
                          onDestinationSelected: (i) => _onTap(context, i),
                          labelType: NavigationRailLabelType.all,
                          leading: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Logo with black background
                              Container(
                                padding: const EdgeInsets.all(8),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  width: 40,
                                  height: 40,
                                ),
                              ),
                              _SyncButton(syncState: syncState, ref: ref),
                            ],
                          ),
                          trailing: Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _LogoutButton(ref: ref),
                              ),
                            ),
                          ),
                          destinations: const [
                            NavigationRailDestination(
                              icon: Icon(Icons.check_circle_outline),
                              label: Text('Tasks'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.dashboard_outlined),
                              label: Text('Dashboard'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.delete_outline),
                              label: Text('Trash'),
                            ),
                            NavigationRailDestination(
                              icon: Icon(Icons.settings_outlined),
                              label: Text('Settings'),
                            ),
                          ],
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(child: child),
                      ],
                    )
                    : child,
          ),
        ],
      ),
      bottomNavigationBar:
          isWide
              ? null
              : NavigationBar(
                selectedIndex: idx,
                onDestinationSelected: (i) => _onTap(context, i),
                destinations: _destinations,
              ),
    );
  }
}

class _SyncButton extends StatefulWidget {
  final SyncState syncState;
  final WidgetRef ref;

  const _SyncButton({required this.syncState, required this.ref});

  @override
  State<_SyncButton> createState() => _SyncButtonState();
}

class _SyncButtonState extends State<_SyncButton> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Update every second to keep the time ago fresh
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final timeAgo =
        widget.syncState.lastSyncTime != null
            ? _getTimeAgo(widget.syncState.lastSyncTime!)
            : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip:
              widget.syncState.lastSyncTime != null
                  ? 'Last sync: ${_fmt(widget.syncState.lastSyncTime!)}'
                  : 'Tap to sync',
          onPressed:
              widget.syncState.isSyncing
                  ? null
                  : () async {
                    await widget.ref.read(syncServiceProvider.notifier).sync();
                    // Refresh task list after sync
                    widget.ref.invalidate(taskListProvider);
                  },
          icon:
              widget.syncState.isSyncing
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : Badge(
                    isLabelVisible: widget.syncState.pendingCount > 0,
                    label: Text('${widget.syncState.pendingCount}'),
                    child: const Icon(Icons.sync),
                  ),
        ),
        if (timeAgo != null) ...[
          const SizedBox(height: 2),
          Text(
            timeAgo,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  String _fmt(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _getTimeAgo(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}

class _LogoutButton extends StatelessWidget {
  final WidgetRef ref;

  const _LogoutButton({required this.ref});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Sign Out',
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text('Sign Out'),
                content: const Text('Are you sure you want to sign out?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
        );

        if (confirmed == true && context.mounted) {
          await ref.read(authProvider.notifier).logout();
          if (context.mounted) context.go('/login');
        }
      },
      icon: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
    );
  }
}
