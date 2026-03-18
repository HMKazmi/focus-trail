import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/storage/hive_boxes.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../tasks/data/sync_service.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late final TextEditingController _urlCtrl;

  @override
  void initState() {
    super.initState();
    final box = Hive.box(HiveBoxes.settings);
    final saved = box.get(AppConfig.baseUrlOverrideKey) as String? ?? '';
    _urlCtrl = TextEditingController(text: saved);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  void _saveUrl() {
    Hive.box(HiveBoxes.settings).put(AppConfig.baseUrlOverrideKey, _urlCtrl.text.trim());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Base URL saved. Restart the app for full effect.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final themeMode = ref.watch(themeModeProvider);
    final syncState = ref.watch(syncServiceProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── User info ────────────────────────────────────
          if (authState.user != null) ...[
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: cs.primaryContainer,
                  child: Icon(Icons.person, color: cs.onPrimaryContainer),
                ),
                title: Text(authState.user!.name ?? authState.user!.email),
                subtitle: Text(authState.user!.email),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Theme ────────────────────────────────────────
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined),
              title: const Text('Dark Mode'),
              value: themeMode == ThemeMode.dark,
              onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
            ),
          ),
          const SizedBox(height: 16),

          // ── Base URL override ─────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('API Base URL', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    'Leave empty to use default (${AppConfig.baseUrl})',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _urlCtrl,
                    decoration: InputDecoration(
                      hintText: AppConfig.baseUrl,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.save),
                        onPressed: _saveUrl,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Sync info ────────────────────────────────────
          Card(
            child: ListTile(
              leading: const Icon(Icons.sync),
              title: const Text('Sync Status'),
              subtitle: Text(
                syncState.lastSyncTime != null
                    ? 'Last sync: ${syncState.lastSyncTime!.toLocal()}'
                    : 'Never synced',
              ),
              trailing: syncState.isSyncing
                  ? const SizedBox(
                      width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Badge(
                      isLabelVisible: syncState.pendingCount > 0,
                      label: Text('${syncState.pendingCount}'),
                      child: IconButton(
                        icon: const Icon(Icons.sync),
                        onPressed: () => ref.read(syncServiceProvider.notifier).sync(),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 32),

          // ── Logout ───────────────────────────────────────
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: cs.error,
              side: BorderSide(color: cs.error),
            ),
          ),
        ],
      ),
    );
  }
}
