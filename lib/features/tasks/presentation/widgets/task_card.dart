import 'package:flutter/material.dart';
import 'package:planora/features/tasks/data/models/task_model.dart';

/// Displays a single [TaskModel].
///
/// Behaviour rules:
/// - Tapping the leading circle marks/unmarks the task as complete.
/// - While the task is **pending**: only swipe-to-delete is available.
/// - Once the task is **completed**: a visible trash-icon button appears so
///   the user must consciously delete. Swipe-to-delete still works too.
/// - Tapping the card body opens the detail/edit screen.
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onToggleComplete,
    required this.onTap,
    required this.onDelete,
  });

  final TaskModel task;
  final VoidCallback onToggleComplete;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: _DismissBackground(colorScheme: cs),
      confirmDismiss: (_) async {
        onDelete();
        return false; // removal is driven by the provider, not Dismissible
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        // Slightly dim completed cards to de-emphasise them
        color: task.isCompleted
            ? cs.surfaceContainerHighest.withValues(alpha: 0.6)
            : null,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 4, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Completion toggle ─────────────────────────────────────
                _CompleteCircle(
                  isCompleted: task.isCompleted,
                  onTap: onToggleComplete,
                  color: task.priority.color,
                ),

                const SizedBox(width: 10),

                // ── Content ───────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: cs.onSurfaceVariant,
                              color: task.isCompleted
                                  ? cs.onSurfaceVariant
                                  : cs.onSurface,
                            ),
                      ),
                      if (task.description != null &&
                          task.description!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          task.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _PriorityChip(priority: task.priority),
                          if (task.dueDate != null)
                            _DueDateChip(
                              dueDate: task.dueDate!,
                              isOverdue: task.isOverdue,
                              colorScheme: cs,
                            ),
                          if (task.category != null &&
                              task.category!.isNotEmpty)
                            _CategoryChip(
                              category: task.category!,
                              colorScheme: cs,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Trailing action ───────────────────────────────────────
                // Completed → explicit Delete button (signals irreversibility)
                // Pending   → subtle chevron (no destructive affordance shown)
                if (task.isCompleted)
                  _DeleteButton(onDelete: onDelete, colorScheme: cs)
                else
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: cs.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _DismissBackground extends StatelessWidget {
  const _DismissBackground({required this.colorScheme});
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.error,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete_rounded, color: Colors.white, size: 26),
          SizedBox(height: 4),
          Text(
            'Delete',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.onDelete, required this.colorScheme});
  final VoidCallback onDelete;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Delete task',
      child: IconButton(
        icon: Icon(Icons.delete_outline_rounded, color: colorScheme.error),
        iconSize: 22,
        onPressed: onDelete,
      ),
    );
  }
}

class _CompleteCircle extends StatelessWidget {
  const _CompleteCircle({
    required this.isCompleted,
    required this.onTap,
    required this.color,
  });

  final bool isCompleted;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCompleted ? color : Colors.transparent,
          border: Border.all(
            color: isCompleted ? color : Theme.of(context).colorScheme.outline,
            width: 2,
          ),
        ),
        child: isCompleted
            ? const Icon(Icons.check, size: 15, color: Colors.white)
            : null,
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.priority});
  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: priority.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: priority.color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(priority.icon, size: 11, color: priority.color),
          const SizedBox(width: 3),
          Text(
            priority.label,
            style: TextStyle(
              fontSize: 11,
              color: priority.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DueDateChip extends StatelessWidget {
  const _DueDateChip({
    required this.dueDate,
    required this.isOverdue,
    required this.colorScheme,
  });

  final DateTime dueDate;
  final bool isOverdue;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final color =
        isOverdue ? colorScheme.error : colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOverdue ? Icons.warning_amber_rounded : Icons.calendar_today,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            _format(dueDate),
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _format(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    final diff = date.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category, required this.colorScheme});
  final String category;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.label_outline,
            size: 11,
            color: colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 3),
          Text(
            category,
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
