import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/connectivity_provider.dart';
import '../../../../core/utils/breakpoints.dart';
import '../../data/sync_service.dart';
import '../providers/task_provider.dart';

/// Adaptive shell: BottomNavigationBar on narrow, NavigationRail on wide.
class TaskShellPage extends ConsumerWidget {
  final Widget child;
  const TaskShellPage({super.key, required this.child});

  static const _destinations = [
    NavigationDestination(icon: Icon(Icons.check_circle_outline), label: 'Tasks'),
    NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
  ];

  int _indexFromRoute(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/settings')) return 1;
    return 0;
  }

  void _onTap(BuildContext context, int idx) {
    switch (idx) {
      case 0:
        context.go('/tasks');
        break;
      case 1:
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
                  Icon(Icons.cloud_off, size: 16, color: Theme.of(context).colorScheme.onErrorContainer),
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
          if (syncState.isSyncing)
            const LinearProgressIndicator(minHeight: 2),
          // Body
          Expanded(
            child: isWide
                ? Row(
                    children: [
                      NavigationRail(
                        selectedIndex: idx,
                        onDestinationSelected: (i) => _onTap(context, i),
                        labelType: NavigationRailLabelType.all,
                        leading: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _SyncButton(syncState: syncState, ref: ref),
                        ),
                        destinations: const [
                          NavigationRailDestination(
                            icon: Icon(Icons.check_circle_outline),
                            label: Text('Tasks'),
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
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: idx,
              onDestinationSelected: (i) => _onTap(context, i),
              destinations: _destinations,
            ),
    );
  }
}

class _SyncButton extends StatelessWidget {
  final SyncState syncState;
  final WidgetRef ref;

  const _SyncButton({required this.syncState, required this.ref});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: syncState.lastSyncTime != null
          ? 'Last sync: ${_fmt(syncState.lastSyncTime!)}'
          : 'Tap to sync',
      onPressed: syncState.isSyncing
          ? null
          : () async {
              await ref.read(syncServiceProvider.notifier).sync();
              // Refresh task list after sync
              ref.invalidate(taskListProvider);
            },
      icon: syncState.isSyncing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Badge(
              isLabelVisible: syncState.pendingCount > 0,
              label: Text('${syncState.pendingCount}'),
              child: const Icon(Icons.sync),
            ),
    );
  }

  String _fmt(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
