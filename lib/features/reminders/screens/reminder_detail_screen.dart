import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../app/providers/category_provider.dart';
import '../../../app/providers/reminder_provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/extensions/date_extensions.dart';
import '../../../data/models/category.dart';
import '../../../data/models/completion_record.dart';
import '../../../data/models/reminder.dart';
import '../../../data/models/reminder_enums.dart';
import '../../../data/repositories/reminder_repository.dart';
import 'add_edit_reminder_screen.dart';

class ReminderDetailScreen extends StatefulWidget {
  final String reminderId;

  const ReminderDetailScreen({super.key, required this.reminderId});

  @override
  State<ReminderDetailScreen> createState() => _ReminderDetailScreenState();
}

class _ReminderDetailScreenState extends State<ReminderDetailScreen> {
  List<CompletionRecord> _history = [];
  bool _isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final repo = ReminderRepository();
      final history = await repo.getCompletionRecordsForReminder(
        widget.reminderId,
      );
      if (mounted) {
        setState(() {
          _history = history;
          _isLoadingHistory = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  void _showSnoozeDialog(BuildContext context, Reminder reminder) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Snooze reminder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('30 minutes'),
                onTap: () {
                  Navigator.pop(dialogCtx);
                  context.read<ReminderProvider>().snoozeReminder(
                    reminder.id,
                    DateTime.now().add(const Duration(minutes: 30)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('1 hour'),
                onTap: () {
                  Navigator.pop(dialogCtx);
                  context.read<ReminderProvider>().snoozeReminder(
                    reminder.id,
                    DateTime.now().add(const Duration(hours: 1)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('3 hours'),
                onTap: () {
                  Navigator.pop(dialogCtx);
                  context.read<ReminderProvider>().snoozeReminder(
                    reminder.id,
                    DateTime.now().add(const Duration(hours: 3)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.wb_sunny_outlined),
                title: const Text('Tomorrow 9:00 AM'),
                onTap: () {
                  Navigator.pop(dialogCtx);
                  final tomorrow = DateTime.now().add(const Duration(days: 1));
                  context.read<ReminderProvider>().snoozeReminder(
                    reminder.id,
                    DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleComplete(BuildContext context, Reminder reminder) async {
    final reminderProvider = context.read<ReminderProvider>();
    final categoryProvider = context.read<CategoryProvider>();
    final category =
        categoryProvider.getCategoryById(reminder.categoryId) ??
        Category.defaultCategory;

    final (updated, record) = await reminderProvider.completeReminder(
      reminder.id,
      categoryName: category.name,
    );

    await _loadHistory();

    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          reminder.isRecurring
              ? 'Occurrence completed! Next due ${DateFormat('d MMM yyyy').format(updated.nextDueDate)}'
              : 'Reminder completed',
        ),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            await reminderProvider.undoCompletion(
              reminder.id,
              record.id,
              reminder,
              categoryName: category.name,
            );
            _loadHistory();
          },
        ),
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context, Reminder reminder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete reminder?'),
        content: Text('Are you sure you want to delete "${reminder.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final reminderProvider = context.read<ReminderProvider>();
    final categoryProvider = context.read<CategoryProvider>();
    final category =
        categoryProvider.getCategoryById(reminder.categoryId) ??
        Category.defaultCategory;

    await reminderProvider.deleteReminder(reminder.id);

    if (!context.mounted) return;
    Navigator.pop(context);

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Reminder deleted'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            reminderProvider.restoreReminder(
              reminder.id,
              categoryName: category.name,
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reminderProvider = context.watch<ReminderProvider>();
    final categoryProvider = context.watch<CategoryProvider>();

    final reminder = reminderProvider.reminders.cast<Reminder?>().firstWhere(
      (r) => r?.id == widget.reminderId,
      orElse: () => null,
    );

    if (reminder == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reminder Details')),
        body: const Center(child: Text('Reminder not found.')),
      );
    }

    final category =
        categoryProvider.getCategoryById(reminder.categoryId) ??
        Category.defaultCategory;
    final statusColors =
        theme.extension<AppStatusColors>() ?? AppStatusColors.light;

    final isOverdue =
        reminder.effectiveDueDate.isBefore(DateTime.now()) &&
        !reminder.isCompleted;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminder Details'),
        actions: [
          IconButton(
            icon: Icon(
              reminder.isFavorite ? Icons.star : Icons.star_border,
              color: reminder.isFavorite ? theme.colorScheme.tertiary : null,
            ),
            tooltip: reminder.isFavorite ? 'Unstar' : 'Star',
            onPressed: () => reminderProvider.toggleFavorite(reminder.id),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditReminderScreen(reminder: reminder),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: () => _handleDelete(context, reminder),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Never truncate title (§4.6)
          Text(
            reminder.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              decoration: reminder.isCompleted
                  ? TextDecoration.lineThrough
                  : null,
            ),
          ),
          const SizedBox(height: 12),

          // Category & Priority Chips
          Row(
            children: [
              Chip(
                avatar: Icon(
                  Category.getIconData(category.iconKey),
                  color: Color(category.colorValue),
                  size: 18,
                ),
                label: Text(category.name),
              ),
              const SizedBox(width: 8),
              Chip(
                avatar: Icon(
                  reminder.priority == Priority.high
                      ? Icons.error
                      : (reminder.priority == Priority.medium
                            ? Icons.circle
                            : Icons.circle_outlined),
                  size: 14,
                ),
                label: Text('Priority: ${reminder.priority.displayName}'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Description Card
          if (reminder.description != null &&
              reminder.description!.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      reminder.description!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Schedule Details Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildDetailRow(
                    context,
                    icon: Icons.calendar_today,
                    label: 'Next Due Date',
                    value: reminder.effectiveDueDate.toFullDateTimeString(),
                    valueColor: isOverdue
                        ? statusColors.overdue
                        : statusColors.upcoming,
                  ),
                  const Divider(),
                  _buildDetailRow(
                    context,
                    icon: Icons.repeat,
                    label: 'Recurrence Schedule',
                    value: reminder.isRecurring
                        ? (reminder.repeatType == RepeatType.custom
                              ? 'Every ${reminder.repeatInterval} ${reminder.repeatUnit.displayName}'
                              : 'Every ${reminder.repeatType.displayName.toLowerCase()}')
                        : 'One-time (Never repeats)',
                  ),
                  const Divider(),
                  _buildDetailRow(
                    context,
                    icon: Icons.history,
                    label: 'Last Completed',
                    value: reminder.lastCompletedAt != null
                        ? reminder.lastCompletedAt!.toFullDateTimeString()
                        : 'Never completed',
                  ),
                  if (reminder.snoozedUntil != null) ...[
                    const Divider(),
                    _buildDetailRow(
                      context,
                      icon: Icons.snooze,
                      label: 'Snoozed Until',
                      value: reminder.snoozedUntil!.toFullDateTimeString(),
                      valueColor: statusColors.snoozed,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Completion History Section
          Text(
            'Completion History',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          if (_isLoadingHistory)
            const Center(child: CircularProgressIndicator())
          else if (_history.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'Not completed yet. Completions will show up here.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _history.length,
                separatorBuilder: (ctx, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final rec = _history[index];
                  return ListTile(
                    leading: Icon(
                      rec.wasLate ? Icons.warning_amber : Icons.check_circle,
                      color: rec.wasLate
                          ? statusColors.overdue
                          : statusColors.completed,
                    ),
                    title: Text(rec.completedAt.toFullDateTimeString()),
                    subtitle: Text(
                      'Due: ${rec.dueDateSnapshot.toFullDateTimeString()} · Source: ${rec.source}',
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (rec.wasLate
                                    ? statusColors.overdue
                                    : statusColors.completed)
                                .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        rec.wasLate ? 'Late' : 'On-time',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: rec.wasLate
                              ? statusColors.overdue
                              : statusColors.completed,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 80),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showSnoozeDialog(context, reminder),
                  icon: const Icon(Icons.snooze),
                  label: const Text('Snooze'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: () => _handleComplete(context, reminder),
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(
                    reminder.isCompleted ? 'Mark as Not Done' : 'Complete',
                  ),
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
