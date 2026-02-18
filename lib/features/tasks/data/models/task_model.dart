import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum TaskPriority {
  low,
  medium,
  high,
  urgent;

  String get label => switch (this) {
        TaskPriority.low => 'Low',
        TaskPriority.medium => 'Medium',
        TaskPriority.high => 'High',
        TaskPriority.urgent => 'Urgent',
      };

  // Value stored in Supabase – matches CHECK constraint
  String get dbValue => name; // 'low' | 'medium' | 'high' | 'urgent'

  Color get color => switch (this) {
        TaskPriority.low => const Color(0xFF6B7280),    // grey
        TaskPriority.medium => const Color(0xFF3B82F6), // blue
        TaskPriority.high => const Color(0xFFF59E0B),   // amber
        TaskPriority.urgent => const Color(0xFFEF4444), // red
      };

  IconData get icon => switch (this) {
        TaskPriority.low => Icons.arrow_downward,
        TaskPriority.medium => Icons.remove,
        TaskPriority.high => Icons.arrow_upward,
        TaskPriority.urgent => Icons.priority_high,
      };

  static TaskPriority fromString(String? value) => switch (value) {
        'low' => TaskPriority.low,
        'high' => TaskPriority.high,
        'urgent' => TaskPriority.urgent,
        _ => TaskPriority.medium,
      };
}

enum TaskStatus {
  pending,
  inProgress,
  completed,
  cancelled;

  String get label => switch (this) {
        TaskStatus.pending => 'Pending',
        TaskStatus.inProgress => 'In Progress',
        TaskStatus.completed => 'Completed',
        TaskStatus.cancelled => 'Cancelled',
      };

  // Value stored in Supabase – matches CHECK constraint
  String get dbValue => switch (this) {
        TaskStatus.pending => 'pending',
        TaskStatus.inProgress => 'in_progress',
        TaskStatus.completed => 'completed',
        TaskStatus.cancelled => 'cancelled',
      };

  static TaskStatus fromString(String? value) => switch (value) {
        'in_progress' => TaskStatus.inProgress,
        'completed' => TaskStatus.completed,
        'cancelled' => TaskStatus.cancelled,
        _ => TaskStatus.pending,
      };
}

// ---------------------------------------------------------------------------
// Sentinel – lets copyWith clear nullable fields explicitly
// ---------------------------------------------------------------------------

// ignore: prefer_const_constructors_in_immutables
final class _Absent {
  const _Absent();
}

const _absent = _Absent();

// ---------------------------------------------------------------------------
// TaskModel
// ---------------------------------------------------------------------------

class TaskModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final TaskPriority priority;
  final TaskStatus status;
  final String? category;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.dueDate,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.pending,
    this.category,
    required this.createdAt,
    required this.updatedAt,
  });

  // ── Computed properties ───────────────────────────────────────────────────

  bool get isCompleted => status == TaskStatus.completed;

  bool get isOverdue =>
      dueDate != null &&
      dueDate!.isBefore(DateTime.now()) &&
      !isCompleted;

  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  bool get isDueUpcoming {
    if (dueDate == null) return false;
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final tomorrow = todayStart.add(const Duration(days: 1));
    return dueDate!.isAfter(tomorrow) || dueDate!.isAtSameMomentAs(tomorrow);
  }

  // ── De/serialisation ──────────────────────────────────────────────────────

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String).toLocal()
          : null,
      priority: TaskPriority.fromString(json['priority'] as String?),
      status: TaskStatus.fromString(json['status'] as String?),
      category: json['category'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Full JSON – for reading back from Supabase
  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'description': description,
        'due_date': dueDate?.toUtc().toIso8601String(),
        'priority': priority.dbValue,
        'status': status.dbValue,
        'category': category,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  /// Used for INSERT – omits id / timestamps (Supabase generates them)
  Map<String, dynamic> toInsertJson() => {
        'user_id': userId,
        'title': title,
        'description': description,
        'due_date': dueDate?.toUtc().toIso8601String(),
        'priority': priority.dbValue,
        'status': status.dbValue,
        'category': category,
      };

  /// Used for UPDATE – omits immutable fields
  Map<String, dynamic> toUpdateJson() => {
        'title': title,
        'description': description,
        'due_date': dueDate?.toUtc().toIso8601String(),
        'priority': priority.dbValue,
        'status': status.dbValue,
        'category': category,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

  // ── copyWith – supports clearing nullable fields via _absent sentinel ─────

  TaskModel copyWith({
    String? id,
    String? userId,
    String? title,
    Object? description = _absent,
    Object? dueDate = _absent,
    TaskPriority? priority,
    TaskStatus? status,
    Object? category = _absent,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: identical(description, _absent)
          ? this.description
          : description as String?,
      dueDate:
          identical(dueDate, _absent) ? this.dueDate : dueDate as DateTime?,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      category:
          identical(category, _absent) ? this.category : category as String?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ── Factory for new unsaved task ──────────────────────────────────────────

  /// Creates a local TaskModel ready for insertion.
  /// `id` is left empty – Supabase will assign a real UUID.
  factory TaskModel.create({
    required String userId,
    required String title,
    String? description,
    DateTime? dueDate,
    TaskPriority priority = TaskPriority.medium,
    String? category,
  }) {
    final now = DateTime.now();
    return TaskModel(
      id: '',
      userId: userId,
      title: title,
      description: description,
      dueDate: dueDate,
      priority: priority,
      status: TaskStatus.pending,
      category: category,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is TaskModel && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'TaskModel(id: $id, title: $title, status: ${status.label})';
}
