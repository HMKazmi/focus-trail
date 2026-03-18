import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/hive_boxes.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../tasks/data/datasource/task_remote_datasource.dart';
import '../../../tasks/data/sync_service.dart';

// Provider for task remote data source (for export)
final taskRemoteDataSourceProvider = Provider<TaskRemoteDataSource>((ref) {
  return TaskRemoteDataSource(ref.watch(dioProvider));
});

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
          const SizedBox(height: 16),

          // ── Export Data ─────────────────────────────────
          Card(
            child: ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export Tasks'),
              subtitle: const Text('Download your tasks as CSV or JSON'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showExportDialog(context),
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

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _ExportDialogContent(),
    );
  }
}

class _ExportDialogContent extends ConsumerStatefulWidget {
  const _ExportDialogContent();

  @override
  ConsumerState<_ExportDialogContent> createState() => _ExportDialogContentState();
}

class _ExportDialogContentState extends ConsumerState<_ExportDialogContent> {
  bool _isExporting = false;
  String _exportType = '';

  Future<void> _exportCsv() async {
    setState(() {
      _isExporting = true;
      _exportType = 'csv';
    });

    try {
      final remote = ref.read(taskRemoteDataSourceProvider);
      final csvData = await remote.exportTasksAsCsv();
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tasks exported as CSV')),
        );
        // For simplicity, show the data in a dialog (in production, use share_plus)
        _showExportResult(context, 'CSV Export', csvData);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _exportJson() async {
    setState(() {
      _isExporting = true;
      _exportType = 'json';
    });

    try {
      final remote = ref.read(taskRemoteDataSourceProvider);
      final jsonData = await remote.exportTasksAsJson();
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tasks exported as JSON')),
        );
        _showExportResult(context, 'JSON Export', jsonData.toString());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _showExportResult(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: SelectableText(
            content,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export Tasks'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Choose your preferred export format:'),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _ExportOptionCard(
                  icon: Icons.table_chart,
                  label: 'CSV',
                  description: 'Spreadsheet',
                  isLoading: _isExporting && _exportType == 'csv',
                  onTap: _isExporting ? null : _exportCsv,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ExportOptionCard(
                  icon: Icons.code,
                  label: 'JSON',
                  description: 'Data format',
                  isLoading: _isExporting && _exportType == 'json',
                  onTap: _isExporting ? null : _exportJson,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isExporting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _ExportOptionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool isLoading;
  final VoidCallback? onTap;

  const _ExportOptionCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outline.withAlpha(50)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            if (isLoading)
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(icon, size: 32, color: cs.primary),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
