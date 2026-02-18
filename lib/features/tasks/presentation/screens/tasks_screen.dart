import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planora/features/auth/providers/auth_provider.dart';
import 'package:planora/features/tasks/data/models/task_model.dart';
import 'package:planora/features/tasks/presentation/screens/task_detail_screen.dart';
import 'package:planora/features/tasks/presentation/widgets/task_card.dart';
import 'package:planora/features/tasks/providers/task_provider.dart';

/// Main tasks list screen with filter chips and FAB.
class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskState = ref.watch(taskProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => ref.read(taskProvider.notifier).fetchTasks(),
          ),
        ],
      ),

      // ── FAB ──────────────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_task_fab',
        onPressed: () => _openDetail(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),

      body: Column(
        children: [
          // ── Overdue banner ─────────────────────────────────────────────
          if (taskState.overdueCount > 0)
            _OverdueBanner(count: taskState.overdueCount, colorScheme: cs),

          // ── Filter chips ───────────────────────────────────────────────
          _FilterRow(taskState: taskState),

          // ── Task list ──────────────────────────────────────────────────
          Expanded(
            child: _TaskListBody(
              taskState: taskState,
              onRefresh: () => ref.read(taskProvider.notifier).fetchTasks(),
              onToggleComplete: (task) =>
                  ref.read(taskProvider.notifier).toggleTaskComplete(task),
              onDelete: (task) => _confirmDelete(context, ref, task),
              onTap: (task) => _openDetail(context, ref, task),
            ),
          ),
        ],
      ),
    );
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  Future<void> _openDetail(
    BuildContext context,
    WidgetRef ref,
    TaskModel? task,
  ) async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;

    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TaskDetailScreen(task: task, userId: userId),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    TaskModel task,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Delete "${task.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(taskProvider.notifier).deleteTask(task.id);
    }
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _OverdueBanner extends StatelessWidget {
  const _OverdueBanner({required this.count, required this.colorScheme});
  final int count;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: colorScheme.error.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 16, color: colorScheme.error),
          const SizedBox(width: 8),
          Text(
            '$count task${count == 1 ? '' : 's'} overdue',
            style: TextStyle(
              color: colorScheme.error,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends ConsumerWidget {
  const _FilterRow({required this.taskState});
  final TaskState taskState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: TaskFilter.values.map((filter) {
          final count = taskState.countFor(filter);
          final isSelected = taskState.activeFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(
                count > 0 ? '${filter.label} $count' : filter.label,
              ),
              onSelected: (_) =>
                  ref.read(taskProvider.notifier).setFilter(filter),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TaskListBody extends StatelessWidget {
  const _TaskListBody({
    required this.taskState,
    required this.onRefresh,
    required this.onToggleComplete,
    required this.onDelete,
    required this.onTap,
  });

  final TaskState taskState;
  final Future<void> Function() onRefresh;
  final void Function(TaskModel) onToggleComplete;
  final void Function(TaskModel) onDelete;
  final void Function(TaskModel) onTap;

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (taskState.isLoading && taskState.tasks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state
    if (taskState.errorMessage != null && taskState.tasks.isEmpty) {
      return _ErrorState(
        message: taskState.errorMessage!,
        onRetry: onRefresh,
      );
    }

    final tasks = taskState.filteredTasks;

    // Empty state
    if (tasks.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: 400,
            child: _EmptyState(filter: taskState.activeFilter),
          ),
        ),
      );
    }

    // Task list
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        itemCount: tasks.length,
        itemBuilder: (_, index) {
          final task = tasks[index];
          return TaskCard(
            key: ValueKey(task.id),
            task: task,
            onToggleComplete: () => onToggleComplete(task),
            onTap: () => onTap(task),
            onDelete: () => onDelete(task),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter});
  final TaskFilter filter;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final (icon, title, subtitle) = switch (filter) {
      TaskFilter.all => (
          Icons.checklist_rounded,
          'No tasks yet',
          'Tap + New Task to add your first task',
        ),
      TaskFilter.today => (
          Icons.today_rounded,
          'Nothing due today',
          'Tasks due today will appear here',
        ),
      TaskFilter.upcoming => (
          Icons.upcoming_rounded,
          'No upcoming tasks',
          'Tasks scheduled for later will appear here',
        ),
      TaskFilter.completed => (
          Icons.task_alt_rounded,
          'No completed tasks',
          'Tasks you finish will appear here',
        ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: cs.primary.withValues(alpha: 0.35)),
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: cs.error),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.error)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
