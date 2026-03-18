import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;

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
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final box = Hive.box(HiveBoxes.settings);
    final saved = box.get(AppConfig.baseUrlOverrideKey) as String? ?? '';
    _urlCtrl = TextEditingController(text: saved);

    // Update every second to keep sync time fresh
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _saveUrl() {
    Hive.box(
      HiveBoxes.settings,
    ).put(AppConfig.baseUrlOverrideKey, _urlCtrl.text.trim());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Base URL saved. Restart the app for full effect.'),
      ),
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
                  Text(
                    'API Base URL',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Leave empty to use default (${AppConfig.baseUrl})',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
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
              title: Text('Sync Status', style: TextStyle()),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    syncState.lastSyncTime != null
                        ? 'Last sync: ${_formatSyncTime(syncState.lastSyncTime!)}'
                        : 'Never synced',
                  ),
                  if (syncState.pendingCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${syncState.pendingCount} pending changes',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              trailing:
                  syncState.isSyncing
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Badge(
                        isLabelVisible: syncState.pendingCount > 0,
                        label: Text('${syncState.pendingCount}'),
                        child: IconButton(
                          icon: const Icon(Icons.sync),
                          onPressed:
                              () =>
                                  ref.read(syncServiceProvider.notifier).sync(),
                        ),
                      ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Export Data ─────────────────────────────────
          Card(
            child: ListTile(
              leading: const Icon(Icons.download),
              title: Text('Export Tasks', style: TextStyle()),
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

  String _formatSyncTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds} seconds ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    } else {
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    }
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
  ConsumerState<_ExportDialogContent> createState() =>
      _ExportDialogContentState();
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
        await _saveFile(csvData, 'tasks_export.csv', 'text/csv');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tasks exported as CSV')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
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
      final jsonString = json.encode(jsonData);

      if (mounted) {
        Navigator.of(context).pop();
        await _saveFile(jsonString, 'tasks_export.json', 'application/json');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tasks exported as JSON')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _saveFile(
    String content,
    String filename,
    String mimeType,
  ) async {
    if (kIsWeb) {
      // Web: Use download API
      final bytes = utf8.encode(content);
      final blob = html.Blob([bytes], mimeType);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // Mobile/Desktop: Use share_plus
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsString(content);
      await Share.shareXFiles([XFile(file.path)], text: 'Exported tasks');
    }
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
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
