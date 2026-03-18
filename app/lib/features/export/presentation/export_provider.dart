import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/network/dio_client.dart';
import '../../tasks/data/datasource/task_remote_datasource.dart';

// ── Export Provider ─────────────────────────────────────────

class ExportState {
  final bool isExporting;
  final String? error;
  final String? successMessage;

  const ExportState({
    this.isExporting = false,
    this.error,
    this.successMessage,
  });

  ExportState copyWith({
    bool? isExporting,
    String? error,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return ExportState(
      isExporting: isExporting ?? this.isExporting,
      error: clearMessages ? null : (error ?? this.error),
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }
}

class ExportNotifier extends StateNotifier<ExportState> {
  final TaskRemoteDataSource _remote;

  ExportNotifier(this._remote) : super(const ExportState());

  Future<void> exportAsCsv() async {
    state = state.copyWith(isExporting: true, clearMessages: true);
    
    try {
      final csvData = await _remote.exportTasksAsCsv();
      await _saveAndShare(csvData, 'tasks_export.csv', 'text/csv');
      state = state.copyWith(isExporting: false, successMessage: 'Tasks exported as CSV');
    } catch (e) {
      state = state.copyWith(isExporting: false, error: e.toString());
    }
  }

  Future<void> exportAsJson() async {
    state = state.copyWith(isExporting: true, clearMessages: true);
    
    try {
      final jsonData = await _remote.exportTasksAsJson();
      final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);
      await _saveAndShare(jsonString, 'tasks_export.json', 'application/json');
      state = state.copyWith(isExporting: false, successMessage: 'Tasks exported as JSON');
    } catch (e) {
      state = state.copyWith(isExporting: false, error: e.toString());
    }
  }

  Future<void> _saveAndShare(String content, String filename, String mimeType) async {
    if (kIsWeb) {
      // Web: Use download functionality via share
      await Share.share(content, subject: filename);
    } else {
      // Mobile/Desktop: Save to file and share
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final file = File('${directory.path}/${timestamp}_$filename');
      await file.writeAsString(content);
      
      await Share.shareXFiles(
        [XFile(file.path, mimeType: mimeType)],
        subject: 'FocusTrail Tasks Export',
      );
    }
  }

  void clearMessages() {
    state = state.copyWith(clearMessages: true);
  }
}

final exportProvider = StateNotifierProvider<ExportNotifier, ExportState>((ref) {
  final remote = TaskRemoteDataSource(ref.watch(dioProvider));
  return ExportNotifier(remote);
});

// ── Export Dialog Widget ─────────────────────────────────────

class ExportDialog extends ConsumerWidget {
  const ExportDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const ExportDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(exportProvider);
    final cs = Theme.of(context).colorScheme;

    // Show snackbar on success/error
    ref.listen<ExportState>(exportProvider, (prev, next) {
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.successMessage!)),
        );
        Navigator.of(context).pop();
      } else if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: cs.error,
          ),
        );
      }
    });

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
                child: _ExportOption(
                  icon: Icons.table_chart,
                  label: 'CSV',
                  description: 'Spreadsheet format',
                  isLoading: state.isExporting,
                  onTap: () => ref.read(exportProvider.notifier).exportAsCsv(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ExportOption(
                  icon: Icons.code,
                  label: 'JSON',
                  description: 'Data interchange',
                  isLoading: state.isExporting,
                  onTap: () => ref.read(exportProvider.notifier).exportAsJson(),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: state.isExporting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _ExportOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool isLoading;
  final VoidCallback onTap;

  const _ExportOption({
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
      onTap: isLoading ? null : onTap,
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
