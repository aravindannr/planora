import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:planora/features/auth/providers/auth_provider.dart';
import 'package:planora/features/tasks/data/models/task_model.dart';
import 'package:planora/features/tasks/presentation/screens/task_detail_screen.dart';
import 'package:planora/features/tasks/presentation/widgets/task_card.dart';
import 'package:planora/features/tasks/providers/task_provider.dart';

/// Calendar view that shows tasks on their due dates.
///
/// - Month grid from [table_calendar] with dot markers on days that have tasks.
/// - Tapping a day reveals the task list for that day in the bottom panel.
/// - Tasks can be completed/deleted from here; tapping opens the detail screen.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Strip time so all keys are midnight-local – avoids timezone mismatch.
  static DateTime _normalize(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  /// Builds a map of date-only → tasks for the [TableCalendar] event loader.
  Map<DateTime, List<TaskModel>> _buildEventMap(List<TaskModel> tasks) {
    final map = <DateTime, List<TaskModel>>{};
    for (final task in tasks) {
      if (task.dueDate == null) continue;
      final key = _normalize(task.dueDate!);
      map.putIfAbsent(key, () => []).add(task);
    }
    return map;
  }

  List<TaskModel> _tasksForDay(
    Map<DateTime, List<TaskModel>> map,
    DateTime day,
  ) => map[_normalize(day)] ?? const [];

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(taskProvider);
    final cs = Theme.of(context).colorScheme;

    final eventMap = _buildEventMap(taskState.tasks);
    final selectedTasks = _tasksForDay(eventMap, _selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today_rounded),
            tooltip: 'Go to today',
            onPressed: () => setState(() {
              _focusedDay = DateTime.now();
              _selectedDay = DateTime.now();
            }),
          ),
        ],
      ),

      body: Column(
        children: [
          // ── Month calendar ────────────────────────────────────────────────
          TableCalendar<TaskModel>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            eventLoader: (day) => _tasksForDay(eventMap, day),
            startingDayOfWeek: StartingDayOfWeek.monday,
            // Lock format to month-only (no week toggle button)
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {CalendarFormat.month: ''},
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: Theme.of(
                context,
              ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
              leftChevronIcon: Icon(Icons.chevron_left, color: cs.onSurface),
              rightChevronIcon: Icon(Icons.chevron_right, color: cs.onSurface),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              // Selected day
              selectedDecoration: BoxDecoration(
                color: cs.primary,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: TextStyle(
                color: cs.onPrimary,
                fontWeight: FontWeight.bold,
              ),
              // Today (when not selected)
              todayDecoration: BoxDecoration(
                color: cs.primaryContainer,
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(
                color: cs.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
              // Event dots
              markerDecoration: BoxDecoration(
                color: cs.primary,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 3,
              markerSize: 5.5,
              markerMargin: const EdgeInsets.symmetric(horizontal: 0.8),
              weekendTextStyle: TextStyle(color: cs.error),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              weekendStyle: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: cs.error.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
            onDaySelected: (selected, focused) => setState(() {
              _selectedDay = selected;
              _focusedDay = focused;
            }),
            onPageChanged: (focusedDay) =>
                setState(() => _focusedDay = focusedDay),
          ),

          const Divider(height: 1),

          // ── Selected day header ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: [
                Text(
                  _dayLabel(_selectedDay),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                if (selectedTasks.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${selectedTasks.length}',
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Task list for selected day ─────────────────────────────────────
          Expanded(
            child: taskState.isLoading && taskState.tasks.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : selectedTasks.isEmpty
                ? _NoTasksForDay(colorScheme: cs)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    itemCount: selectedTasks.length,
                    itemBuilder: (_, i) {
                      final task = selectedTasks[i];
                      return TaskCard(
                        key: ValueKey(task.id),
                        task: task,
                        onToggleComplete: () => ref
                            .read(taskProvider.notifier)
                            .toggleTaskComplete(task),
                        onTap: () => _openDetail(context, ref, task),
                        onDelete: () => _confirmDelete(context, ref, task),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _dayLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(day.year, day.month, day.day);
    if (d == today) return 'Today';
    if (d == today.add(const Duration(days: 1))) return 'Tomorrow';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${weekdays[day.weekday - 1]}, ${months[day.month - 1]} ${day.day}';
  }

  Future<void> _openDetail(
    BuildContext context,
    WidgetRef ref,
    TaskModel? task,
  ) async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;

    // Pre-fill dueDate to the selected day when creating from calendar
    final prefilledTask = task == null
        ? TaskModel.create(userId: userId, title: '', dueDate: _selectedDay)
        : null;

    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            TaskDetailScreen(task: task ?? prefilledTask, userId: userId),
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
    if (confirmed == true && context.mounted) {
      ref.read(taskProvider.notifier).deleteTask(task.id);
    }
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _NoTasksForDay extends StatelessWidget {
  const _NoTasksForDay({required this.colorScheme});
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available_rounded,
            size: 56,
            color: colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks scheduled',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap + New Task to add one for this day',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
