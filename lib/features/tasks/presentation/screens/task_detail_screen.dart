import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planora/features/tasks/data/models/task_model.dart';
import 'package:planora/features/tasks/providers/task_provider.dart';

/// Create a new task (pass [task] = null) or edit an existing one.
///
/// Returns `true` via `Navigator.pop` when a task is saved/deleted so the
/// caller can react (e.g., refresh the list).
class TaskDetailScreen extends ConsumerStatefulWidget {
  const TaskDetailScreen({
    super.key,
    required this.userId,
    this.task,
  });

  /// The authenticated user's id – needed when creating a new task.
  final String userId;

  /// Existing task to edit. `null` means we are creating a new task.
  final TaskModel? task;

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();

  late TaskPriority _priority;
  late TaskStatus _status;
  DateTime? _dueDate;
  bool _isSaving = false;
  bool _isDeleting = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleCtrl.text = t?.title ?? '';
    _descCtrl.text = t?.description ?? '';
    _categoryCtrl.text = t?.category ?? '';
    _priority = t?.priority ?? TaskPriority.medium;
    _status = t?.status ?? TaskStatus.pending;
    _dueDate = t?.dueDate;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final notifier = ref.read(taskProvider.notifier);
    bool ok;

    if (_isEditing) {
      final updated = widget.task!.copyWith(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        dueDate: _dueDate,
        priority: _priority,
        status: _status,
        category: _categoryCtrl.text.trim().isEmpty
            ? null
            : _categoryCtrl.text.trim(),
      );
      ok = await notifier.updateTask(updated);
    } else {
      final newTask = TaskModel.create(
        userId: widget.userId,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        dueDate: _dueDate,
        priority: _priority,
        category: _categoryCtrl.text.trim().isEmpty
            ? null
            : _categoryCtrl.text.trim(),
      );
      ok = await notifier.createTask(newTask);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      final err = ref.read(taskProvider).errorMessage ?? 'Something went wrong';
      _snack(err, isError: true);
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Delete "${widget.task!.title}"? This cannot be undone.'),
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
    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    final ok =
        await ref.read(taskProvider.notifier).deleteTask(widget.task!.id);

    if (!mounted) return;
    setState(() => _isDeleting = false);

    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      final err =
          ref.read(taskProvider).errorMessage ?? 'Failed to delete task';
      _snack(err, isError: true);
    }
  }

  // ── Date picker ───────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _clearDate() => setState(() => _dueDate = null);

  // ── Helper ────────────────────────────────────────────────────────────────

  void _snack(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: isError
              ? Theme.of(context).colorScheme.error
              : const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isBusy = _isSaving || _isDeleting;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Task' : 'New Task'),
        actions: [
          // Edit mode: delete icon + save shortcut in AppBar
          if (_isEditing) ...[
            _isDeleting
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: Icon(Icons.delete_rounded, color: cs.error),
                    tooltip: 'Delete task',
                    onPressed: isBusy ? null : _delete,
                  ),
            // Quick-save shortcut only in edit mode (bottom button is primary CTA)
            _isSaving
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : TextButton(
                    onPressed: isBusy ? null : _save,
                    child: const Text('Save'),
                  ),
          ],
          // Create mode: no AppBar buttons – "Create Task" button is the sole CTA
        ],
      ),

      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Title ─────────────────────────────────────────────────
              _FieldLabel('Title *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleCtrl,
                autofocus: !_isEditing,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'What do you need to do?',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              ),

              const SizedBox(height: 20),

              // ── Description ───────────────────────────────────────────
              _FieldLabel('Description'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Add details (optional)',
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 24),

              // ── Priority ──────────────────────────────────────────────
              _FieldLabel('Priority'),
              const SizedBox(height: 10),
              _PrioritySelector(
                selected: _priority,
                onChanged: (p) => setState(() => _priority = p),
              ),

              const SizedBox(height: 24),

              // ── Due date ──────────────────────────────────────────────
              _FieldLabel('Due Date'),
              const SizedBox(height: 6),
              _DueDateTile(
                dueDate: _dueDate,
                colorScheme: cs,
                onPick: _pickDate,
                onClear: _clearDate,
              ),

              const SizedBox(height: 24),

              // ── Category ──────────────────────────────────────────────
              _FieldLabel('Category'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _categoryCtrl,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  hintText: 'e.g. Work, Personal, Health',
                  prefixIcon: Icon(Icons.label_outline),
                ),
              ),

              // ── Status (edit mode only) ───────────────────────────────
              if (_isEditing) ...[
                const SizedBox(height: 24),
                _FieldLabel('Status'),
                const SizedBox(height: 10),
                _StatusSelector(
                  selected: _status,
                  onChanged: (s) => setState(() => _status = s),
                ),
              ],

              const SizedBox(height: 36),

              // ── Primary save button ───────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isBusy ? null : _save,
                  icon: isBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(_isEditing ? Icons.save_rounded : Icons.add),
                  label: Text(_isEditing ? 'Save Changes' : 'Create Task'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _PrioritySelector extends StatelessWidget {
  const _PrioritySelector({required this.selected, required this.onChanged});
  final TaskPriority selected;
  final ValueChanged<TaskPriority> onChanged;

  // Pick black or white label text based on WCAG contrast against the chip bg.
  // Luminance threshold 0.35 gives ≥ 4.5:1 contrast for both choices.
  static Color _contrastOn(Color bg) =>
      bg.computeLuminance() > 0.35 ? Colors.black87 : Colors.white;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: TaskPriority.values.map((p) {
        final isSelected = p == selected;
        final labelColor = isSelected ? _contrastOn(p.color) : p.color;
        final iconColor = isSelected ? _contrastOn(p.color) : p.color;
        return ChoiceChip(
          avatar: Icon(p.icon, size: 16, color: iconColor),
          label: Text(p.label),
          selected: isSelected,
          selectedColor: p.color,
          labelStyle: TextStyle(color: labelColor, fontWeight: FontWeight.w600),
          side: BorderSide(color: p.color.withValues(alpha: 0.5)),
          onSelected: (_) => onChanged(p),
        );
      }).toList(),
    );
  }
}

class _StatusSelector extends StatelessWidget {
  const _StatusSelector({required this.selected, required this.onChanged});
  final TaskStatus selected;
  final ValueChanged<TaskStatus> onChanged;

  // Only meaningful statuses to set manually
  static const _statuses = [
    TaskStatus.pending,
    TaskStatus.inProgress,
    TaskStatus.completed,
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      children: _statuses.map((s) {
        final isSelected = s == selected;
        return ChoiceChip(
          label: Text(s.label),
          selected: isSelected,
          selectedColor: cs.primaryContainer,
          labelStyle: TextStyle(
            color: isSelected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
          onSelected: (_) => onChanged(s),
        );
      }).toList(),
    );
  }
}

class _DueDateTile extends StatelessWidget {
  const _DueDateTile({
    required this.dueDate,
    required this.colorScheme,
    required this.onPick,
    required this.onClear,
  });

  final DateTime? dueDate;
  final ColorScheme colorScheme;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(12),
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month_rounded,
              color: dueDate != null
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                dueDate != null ? _formatDate(dueDate!) : 'Set due date',
                style: TextStyle(
                  color: dueDate != null
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                  fontSize: 15,
                ),
              ),
            ),
            if (dueDate != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
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
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
