import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/extensions/date_extensions.dart';
import '../../../data/models/category.dart';
import '../../../data/models/reminder.dart';
import '../../../data/models/reminder_enums.dart';

class ReminderTile extends StatelessWidget {
  final Reminder reminder;
  final Category category;
  final ValueChanged<bool?>? onCompleteChanged;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onDelete;
  final VoidCallback? onSnooze;

  const ReminderTile({
    super.key,
    required this.reminder,
    required this.category,
    this.onCompleteChanged,
    this.onTap,
    this.onFavoriteToggle,
    this.onDelete,
    this.onSnooze,
  });

  Color _getStatusColor(BuildContext context) {
    final statusColors =
        Theme.of(context).extension<AppStatusColors>() ?? AppStatusColors.light;
    if (reminder.isCompleted) return statusColors.completed;

    final effective = reminder.effectiveDueDate;
    final now = DateTime.now();

    if (effective.isBefore(now)) {
      return statusColors.overdue;
    } else if (effective.isSameDay(now)) {
      return statusColors.today;
    } else {
      return statusColors.upcoming;
    }
  }

  String _getDueDateLabel() {
    final effective = reminder.effectiveDueDate;
    String dateStr = effective.toRelativeString();
    if (reminder.dueTime != null) {
      dateStr += ' · ${reminder.dueTime!.toTimeString()}';
    }
    return dateStr;
  }

  Widget _buildPriorityBadge(ThemeData theme) {
    Color color;
    String label;
    switch (reminder.priority) {
      case Priority.high:
        color = theme.colorScheme.error;
        label = 'High';
        break;
      case Priority.medium:
        color = theme.colorScheme.primary;
        label = 'Med';
        break;
      case Priority.low:
        color = theme.colorScheme.outline;
        label = 'Low';
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.94),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Checkbox target (>= 48x48dp)
              SizedBox(
                width: 48,
                height: 48,
                child: Checkbox(
                  value: reminder.isCompleted,
                  onChanged: onCompleteChanged,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Main content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            reminder.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              decoration: reminder.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: reminder.isCompleted
                                  ? theme.colorScheme.outline
                                  : theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 10,
                      runSpacing: 3,
                      children: [
                        // Category Icon + Name
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Category.getIconData(category.iconKey),
                              size: 14,
                              color: Color(category.colorValue),
                            ),
                            const SizedBox(width: 5),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 112),
                              child: Text(
                                category.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Relative due date label
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              reminder.isCompleted
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.schedule_rounded,
                              size: 14,
                              color: statusColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getDueDateLabel(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 12,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _buildPriorityBadge(theme),
                        if (reminder.notificationEnabled)
                          Tooltip(
                            message: 'Notifications on',
                            child: Icon(
                              Icons.notifications_active_outlined,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        if (reminder.isRecurring) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.autorenew_rounded,
                                size: 14,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                reminder.repeatType.displayName,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (reminder.snoozedUntil != null) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.snooze_rounded,
                                size: 14,
                                color: statusColor,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Snoozed',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  reminder.isFavorite
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: reminder.isFavorite
                      ? theme.colorScheme.tertiary
                      : theme.colorScheme.outline,
                ),
                onPressed: onFavoriteToggle,
                tooltip: reminder.isFavorite
                    ? 'Unstar reminder'
                    : 'Star reminder',
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz_rounded),
                tooltip: 'More options',
                onSelected: (value) {
                  if (value == 'snooze' && onSnooze != null) onSnooze!();
                  if (value == 'delete' && onDelete != null) onDelete!();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'snooze',
                    child: Row(
                      children: [
                        Icon(Icons.snooze_rounded, size: 20),
                        SizedBox(width: 12),
                        Text('Snooze'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Delete',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
