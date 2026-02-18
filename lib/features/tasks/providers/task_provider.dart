import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planora/features/tasks/data/models/task_model.dart';
import 'package:planora/features/tasks/data/repositories/task_repository.dart';

// ---------------------------------------------------------------------------
// Filter enum
// ---------------------------------------------------------------------------

enum TaskFilter {
  all,
  today,
  upcoming,
  completed;

  String get label => switch (this) {
        TaskFilter.all => 'All',
        TaskFilter.today => 'Today',
        TaskFilter.upcoming => 'Upcoming',
        TaskFilter.completed => 'Done',
      };
}

// ---------------------------------------------------------------------------
// TaskState
// ---------------------------------------------------------------------------

class TaskState {
  final List<TaskModel> tasks;
  final bool isLoading;
  final String? errorMessage;
  final TaskFilter activeFilter;

  const TaskState({
    this.tasks = const [],
    this.isLoading = false,
    this.errorMessage,
    this.activeFilter = TaskFilter.all,
  });

  factory TaskState.initial() => const TaskState();

  // ── Derived lists – consumed directly by the UI ───────────────────────────

  List<TaskModel> get filteredTasks => switch (activeFilter) {
        // Pending tasks first, completed tasks at the bottom
        TaskFilter.all => [
            ...tasks.where((t) => !t.isCompleted),
            ...tasks.where((t) => t.isCompleted),
          ],
        TaskFilter.today =>
          tasks.where((t) => t.isDueToday && !t.isCompleted).toList(),
        TaskFilter.upcoming =>
          tasks.where((t) => t.isDueUpcoming && !t.isCompleted).toList(),
        TaskFilter.completed =>
          tasks.where((t) => t.isCompleted).toList(),
      };

  // Stats badges shown in the filter chips
  int countFor(TaskFilter filter) => switch (filter) {
        TaskFilter.all => tasks.where((t) => !t.isCompleted).length,
        TaskFilter.today =>
          tasks.where((t) => t.isDueToday && !t.isCompleted).length,
        TaskFilter.upcoming =>
          tasks.where((t) => t.isDueUpcoming && !t.isCompleted).length,
        TaskFilter.completed => tasks.where((t) => t.isCompleted).length,
      };

  int get overdueCount =>
      tasks.where((t) => t.isOverdue && !t.isCompleted).length;

  TaskState copyWith({
    List<TaskModel>? tasks,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    TaskFilter? activeFilter,
  }) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      activeFilter: activeFilter ?? this.activeFilter,
    );
  }
}

// ---------------------------------------------------------------------------
// TaskNotifier – Riverpod 3 Notifier
// ---------------------------------------------------------------------------

class TaskNotifier extends Notifier<TaskState> {
  TaskRepository get _repo => ref.read(taskRepositoryProvider);

  @override
  TaskState build() {
    // Kick off initial fetch when the provider is first read
    Future.microtask(fetchTasks);
    return TaskState.initial();
  }

  // ── Fetch ─────────────────────────────────────────────────────────────────

  Future<void> fetchTasks() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final tasks = await _repo.fetchTasks();
      state = state.copyWith(tasks: tasks, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // ── Create ────────────────────────────────────────────────────────────────

  Future<bool> createTask(TaskModel task) async {
    try {
      final created = await _repo.createTask(task);
      // Prepend so the new task appears at the top of the list
      state = state.copyWith(tasks: [created, ...state.tasks]);
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  // ── Update ────────────────────────────────────────────────────────────────

  Future<bool> updateTask(TaskModel task) async {
    try {
      final updated = await _repo.updateTask(task);
      state = state.copyWith(
        tasks: state.tasks
            .map((t) => t.id == updated.id ? updated : t)
            .toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<bool> deleteTask(String id) async {
    try {
      await _repo.deleteTask(id);
      state = state.copyWith(
        tasks: state.tasks.where((t) => t.id != id).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  // ── Toggle complete (optimistic) ──────────────────────────────────────────

  Future<bool> toggleTaskComplete(TaskModel task) async {
    // Apply optimistic update immediately for a snappy UI
    final optimistic = task.copyWith(
      status: task.isCompleted ? TaskStatus.pending : TaskStatus.completed,
    );
    state = state.copyWith(
      tasks: state.tasks.map((t) => t.id == task.id ? optimistic : t).toList(),
    );

    try {
      final confirmed = await _repo.toggleTaskComplete(task);
      state = state.copyWith(
        tasks: state.tasks
            .map((t) => t.id == confirmed.id ? confirmed : t)
            .toList(),
      );
      return true;
    } catch (e) {
      // Roll back on failure
      state = state.copyWith(
        tasks: state.tasks.map((t) => t.id == task.id ? task : t).toList(),
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  // ── Filter ───────────────────────────────────────────────────────────────

  void setFilter(TaskFilter filter) =>
      state = state.copyWith(activeFilter: filter);

  void clearError() => state = state.copyWith(clearError: true);
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final taskRepositoryProvider = Provider<TaskRepository>(
  (_) => TaskRepository(),
);

final taskProvider = NotifierProvider<TaskNotifier, TaskState>(
  TaskNotifier.new,
);
