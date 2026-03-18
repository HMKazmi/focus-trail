import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../tasks/data/datasource/task_remote_datasource.dart';

// ── DI ─────────────────────────────────────────────────────

final dashboardRemoteProvider = Provider<TaskRemoteDataSource>((ref) {
  return TaskRemoteDataSource(ref.watch(dioProvider));
});

// ── Dashboard State ────────────────────────────────────────

class DashboardState {
  final DashboardStats? stats;
  final List<TrendDataPoint> completionTrend;
  final List<TrendDataPoint> createdVsCompletedTrend;
  final bool isLoading;
  final String? error;
  final String selectedPeriod; // 'day', 'week', 'month'

  const DashboardState({
    this.stats,
    this.completionTrend = const [],
    this.createdVsCompletedTrend = const [],
    this.isLoading = false,
    this.error,
    this.selectedPeriod = 'week',
  });

  DashboardState copyWith({
    DashboardStats? stats,
    List<TrendDataPoint>? completionTrend,
    List<TrendDataPoint>? createdVsCompletedTrend,
    bool? isLoading,
    String? error,
    String? selectedPeriod,
    bool clearError = false,
  }) {
    return DashboardState(
      stats: stats ?? this.stats,
      completionTrend: completionTrend ?? this.completionTrend,
      createdVsCompletedTrend: createdVsCompletedTrend ?? this.createdVsCompletedTrend,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
    );
  }
}

// ── Dashboard Notifier ─────────────────────────────────────

class DashboardNotifier extends StateNotifier<DashboardState> {
  final TaskRemoteDataSource _remote;

  DashboardNotifier(this._remote) : super(const DashboardState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      final results = await Future.wait([
        _remote.fetchDashboardStats(),
        _remote.fetchCompletionTrend(period: state.selectedPeriod),
        _remote.fetchCreatedVsCompletedTrend(days: _getDaysForPeriod(state.selectedPeriod)),
      ]);

      state = state.copyWith(
        stats: results[0] as DashboardStats,
        completionTrend: results[1] as List<TrendDataPoint>,
        createdVsCompletedTrend: results[2] as List<TrendDataPoint>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> changePeriod(String period) async {
    state = state.copyWith(selectedPeriod: period);
    await load();
  }

  int _getDaysForPeriod(String period) {
    switch (period) {
      case 'day':
        return 1;
      case 'month':
        return 30;
      case 'week':
      default:
        return 7;
    }
  }
}

// ── Provider ───────────────────────────────────────────────

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final remote = ref.watch(dashboardRemoteProvider);
  return DashboardNotifier(remote);
});
