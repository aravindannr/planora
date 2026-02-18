import 'package:flutter/foundation.dart';
import 'package:planora/features/tasks/data/models/task_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Data-access layer for tasks.
///
/// All methods use Supabase Row-Level-Security so every query is
/// automatically scoped to the authenticated user.
class TaskRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const _table = 'tasks';

  // ── Auth guard ────────────────────────────────────────────────────────────

  String _requireUserId() {
    final id = _supabase.auth.currentUser?.id;
    if (id == null) throw Exception('User is not authenticated');
    return id;
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Fetch all tasks for the current user, newest first.
  Future<List<TaskModel>> fetchTasks() async {
    try {
      final userId = _requireUserId();
      final rows = await _supabase
          .from(_table)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return rows.map(TaskModel.fromJson).toList();
    } catch (e) {
      debugPrint('TaskRepository.fetchTasks error: $e');
      throw Exception('Failed to load tasks. Please try again.');
    }
  }

  // ── Create ────────────────────────────────────────────────────────────────

  /// Insert a new task and return the persisted model (with Supabase-assigned id).
  Future<TaskModel> createTask(TaskModel task) async {
    try {
      _requireUserId(); // ensures auth guard
      final row = await _supabase
          .from(_table)
          .insert(task.toInsertJson())
          .select()
          .single();

      debugPrint('TaskRepository: task created ${row['id']}');
      return TaskModel.fromJson(row);
    } catch (e) {
      debugPrint('TaskRepository.createTask error: $e');
      throw Exception('Failed to create task. Please try again.');
    }
  }

  // ── Update ────────────────────────────────────────────────────────────────

  /// Update an existing task and return the refreshed model.
  Future<TaskModel> updateTask(TaskModel task) async {
    try {
      final userId = _requireUserId();
      final row = await _supabase
          .from(_table)
          .update(task.toUpdateJson())
          .eq('id', task.id)
          .eq('user_id', userId) // belt-and-braces on top of RLS
          .select()
          .single();

      debugPrint('TaskRepository: task updated ${task.id}');
      return TaskModel.fromJson(row);
    } catch (e) {
      debugPrint('TaskRepository.updateTask error: $e');
      throw Exception('Failed to update task. Please try again.');
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> deleteTask(String id) async {
    try {
      final userId = _requireUserId();
      await _supabase
          .from(_table)
          .delete()
          .eq('id', id)
          .eq('user_id', userId);

      debugPrint('TaskRepository: task deleted $id');
    } catch (e) {
      debugPrint('TaskRepository.deleteTask error: $e');
      throw Exception('Failed to delete task. Please try again.');
    }
  }

  // ── Toggle complete ───────────────────────────────────────────────────────

  /// Flips the status between [TaskStatus.completed] and [TaskStatus.pending].
  Future<TaskModel> toggleTaskComplete(TaskModel task) {
    final toggled = task.copyWith(
      status: task.isCompleted ? TaskStatus.pending : TaskStatus.completed,
    );
    return updateTask(toggled);
  }
}
