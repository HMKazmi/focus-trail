import 'package:dio/dio.dart';

import '../dto/task_dto.dart';

/// Dashboard statistics from server.
class DashboardStats {
  final int total;
  final int todo;
  final int inProgress;
  final int done;
  final int lowPriority;
  final int mediumPriority;
  final int highPriority;
  final int overdue;
  final int dueSoon;
  final int completedToday;
  final int completedThisWeek;
  final int completedThisMonth;
  final int streak;
  final double? avgCompletionTime;

  const DashboardStats({
    this.total = 0,
    this.todo = 0,
    this.inProgress = 0,
    this.done = 0,
    this.lowPriority = 0,
    this.mediumPriority = 0,
    this.highPriority = 0,
    this.overdue = 0,
    this.dueSoon = 0,
    this.completedToday = 0,
    this.completedThisWeek = 0,
    this.completedThisMonth = 0,
    this.streak = 0,
    this.avgCompletionTime,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    final byStatus = json['byStatus'] as Map<String, dynamic>? ?? {};
    final byPriority = json['byPriority'] as Map<String, dynamic>? ?? {};
    return DashboardStats(
      total: json['total'] as int? ?? 0,
      todo: byStatus['todo'] as int? ?? 0,
      inProgress: byStatus['in_progress'] as int? ?? 0,
      done: byStatus['done'] as int? ?? 0,
      lowPriority: byPriority['low'] as int? ?? 0,
      mediumPriority: byPriority['medium'] as int? ?? 0,
      highPriority: byPriority['high'] as int? ?? 0,
      overdue: json['overdue'] as int? ?? 0,
      dueSoon: json['dueSoon'] as int? ?? 0,
      completedToday: json['completedToday'] as int? ?? 0,
      completedThisWeek: json['completedThisWeek'] as int? ?? 0,
      completedThisMonth: json['completedThisMonth'] as int? ?? 0,
      streak: json['streak'] as int? ?? 0,
      avgCompletionTime: (json['avgCompletionTime'] as num?)?.toDouble(),
    );
  }

  double get completionRate => total > 0 ? (done / total) * 100 : 0;
}

/// Trend data point.
class TrendDataPoint {
  final String date;
  final int count;
  final int? created;
  final int? completed;

  const TrendDataPoint({
    required this.date,
    this.count = 0,
    this.created,
    this.completed,
  });

  factory TrendDataPoint.fromJson(Map<String, dynamic> json) {
    return TrendDataPoint(
      date: json['date'] as String? ?? '',
      count: json['count'] as int? ?? 0,
      created: json['created'] as int?,
      completed: json['completed'] as int?,
    );
  }
}

class TaskRemoteDataSource {
  final Dio _dio;
  TaskRemoteDataSource(this._dio);

  // ═══════════════════════════════════════════════════════════
  // CRUD Operations
  // ═══════════════════════════════════════════════════════════

  Future<List<TaskDto>> fetchTasks({
    String? status,
    String? priority,
    String? search,
    String? sort,
  }) async {
    final queryParams = <String, dynamic>{};
    if (status != null) queryParams['status'] = status;
    if (priority != null) queryParams['priority'] = priority;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (sort != null) queryParams['sort'] = sort;

    final res = await _dio.get('/api/tasks', queryParameters: queryParams);
    final data = res.data['data'] ?? res.data;
    final list = (data['tasks'] ?? data) as List<dynamic>;
    return list.map((e) => TaskDto.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<TaskDto> createTask(TaskDto dto) async {
    final body = <String, dynamic>{
      'title': dto.title,
      'status': dto.status,
      'priority': dto.priority,
    };
    if (dto.description != null) body['description'] = dto.description;
    if (dto.dueDate != null) body['dueDate'] = dto.dueDate!.endsWith('Z') ? dto.dueDate : '${dto.dueDate}Z';
    if (dto.reminderAt != null) body['reminderAt'] = dto.reminderAt!.endsWith('Z') ? dto.reminderAt : '${dto.reminderAt}Z';
    
    final res = await _dio.post('/api/tasks', data: body);
    final data = res.data['data'] ?? res.data;
    return TaskDto.fromJson(Map<String, dynamic>.from(data['task'] ?? data));
  }

  Future<TaskDto> updateTask(TaskDto dto) async {
    final body = <String, dynamic>{
      'title': dto.title,
      'status': dto.status,
      'priority': dto.priority,
    };
    // Include description (can be null to clear it)
    body['description'] = dto.description;
    // Include dates - null means clear them
    body['dueDate'] = dto.dueDate != null 
        ? (dto.dueDate!.endsWith('Z') ? dto.dueDate : '${dto.dueDate}Z')
        : null;
    body['reminderAt'] = dto.reminderAt != null 
        ? (dto.reminderAt!.endsWith('Z') ? dto.reminderAt : '${dto.reminderAt}Z')
        : null;
    
    final res = await _dio.put('/api/tasks/${dto.id}', data: body);
    final data = res.data['data'] ?? res.data;
    return TaskDto.fromJson(Map<String, dynamic>.from(data['task'] ?? data));
  }

  Future<void> deleteTask(String id) async {
    await _dio.delete('/api/tasks/$id');
  }

  // ═══════════════════════════════════════════════════════════
  // Trash Bin
  // ═══════════════════════════════════════════════════════════

  Future<TaskDto> trashTask(String id) async {
    final res = await _dio.patch('/api/tasks/$id/trash');
    final data = res.data['data'] ?? res.data;
    return TaskDto.fromJson(Map<String, dynamic>.from(data['task'] ?? data));
  }

  Future<TaskDto> restoreTask(String id) async {
    final res = await _dio.patch('/api/tasks/$id/restore');
    final data = res.data['data'] ?? res.data;
    return TaskDto.fromJson(Map<String, dynamic>.from(data['task'] ?? data));
  }

  Future<List<TaskDto>> fetchTrash() async {
    final res = await _dio.get('/api/tasks/trash');
    final data = res.data['data'] ?? res.data;
    final list = (data['tasks'] ?? data) as List<dynamic>;
    return list.map((e) => TaskDto.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<int> emptyTrash() async {
    final res = await _dio.delete('/api/tasks/trash');
    final data = res.data['data'] ?? res.data;
    return data['deletedCount'] as int? ?? 0;
  }

  // ═══════════════════════════════════════════════════════════
  // Reminders & Notifications
  // ═══════════════════════════════════════════════════════════

  Future<List<TaskDto>> fetchUpcomingReminders({int hoursAhead = 24}) async {
    final res = await _dio.get('/api/tasks/reminders', queryParameters: {'hours': hoursAhead});
    final data = res.data['data'] ?? res.data;
    final list = (data['tasks'] ?? data) as List<dynamic>;
    return list.map((e) => TaskDto.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<List<TaskDto>> fetchDueSoonTasks({int hoursAhead = 24}) async {
    final res = await _dio.get('/api/tasks/due-soon', queryParameters: {'hours': hoursAhead});
    final data = res.data['data'] ?? res.data;
    final list = (data['tasks'] ?? data) as List<dynamic>;
    return list.map((e) => TaskDto.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<List<TaskDto>> fetchOverdueTasks() async {
    final res = await _dio.get('/api/tasks/overdue');
    final data = res.data['data'] ?? res.data;
    final list = (data['tasks'] ?? data) as List<dynamic>;
    return list.map((e) => TaskDto.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  // ═══════════════════════════════════════════════════════════
  // Dashboard & Analytics
  // ═══════════════════════════════════════════════════════════

  Future<DashboardStats> fetchDashboardStats() async {
    final res = await _dio.get('/api/tasks/stats');
    final data = res.data['data'] ?? res.data;
    return DashboardStats.fromJson(Map<String, dynamic>.from(data['stats'] ?? data));
  }

  Future<List<TrendDataPoint>> fetchCompletionTrend({String period = 'week'}) async {
    final res = await _dio.get('/api/tasks/analytics/completion', queryParameters: {'period': period});
    final data = res.data['data'] ?? res.data;
    final list = (data['trend'] ?? data) as List<dynamic>;
    return list.map((e) => TrendDataPoint.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<List<TrendDataPoint>> fetchCreatedVsCompletedTrend({int days = 7}) async {
    final res = await _dio.get('/api/tasks/analytics/trend', queryParameters: {'days': days});
    final data = res.data['data'] ?? res.data;
    final list = (data['trend'] ?? data) as List<dynamic>;
    return list.map((e) => TrendDataPoint.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  // ═══════════════════════════════════════════════════════════
  // Export
  // ═══════════════════════════════════════════════════════════

  Future<String> exportTasksAsCsv() async {
    final res = await _dio.get('/api/tasks/export', queryParameters: {'format': 'csv'});
    return res.data as String;
  }

  Future<Map<String, dynamic>> exportTasksAsJson() async {
    final res = await _dio.get('/api/tasks/export', queryParameters: {'format': 'json'});
    return Map<String, dynamic>.from(res.data);
  }
}
