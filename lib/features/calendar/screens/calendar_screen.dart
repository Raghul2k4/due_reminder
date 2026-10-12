import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../app/providers/category_provider.dart';
import '../../../app/providers/reminder_provider.dart';
import '../../../app/providers/settings_provider.dart';
import '../../../app/providers/subscription_provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/recurrence.dart';
import '../../../data/models/category.dart';
import '../../../data/models/reminder.dart';
import '../../../data/models/subscription.dart';
import '../../../data/models/subscription_enums.dart';
import '../../reminders/screens/add_edit_reminder_screen.dart';
import '../../reminders/screens/reminder_detail_screen.dart';
import '../../reminders/widgets/reminder_tile.dart';
import '../../subscriptions/screens/add_edit_subscription_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedMonth;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _focusedMonth = DateTime(now.year, now.month, 1);
      _selectedDay = DateTime(now.year, now.month, now.day);
    });
  }

  /// Expands occurrences for the focused month bounded per §17.1
  Map<DateTime, List<Reminder>> _buildMonthOccurrencesMap(List<Reminder> allReminders) {
    final Map<DateTime, List<Reminder>> map = {};

    final monthStart = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final monthEnd = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0, 23, 59, 59);

    for (final reminder in allReminders) {
      if (reminder.isDeleted) continue;

      if (!reminder.isRecurring) {
        final date = DateTime(reminder.effectiveDueDate.year, reminder.effectiveDueDate.month, reminder.effectiveDueDate.day);
        map.putIfAbsent(date, () => []).add(reminder);
      } else {
        // Expand occurrences in visible month
        DateTime candidate = computeNextDueDate(
          anchor: reminder.dueDate,
          from: monthStart.subtract(const Duration(days: 1)),
          type: reminder.repeatType,
          interval: reminder.repeatInterval,
          unit: reminder.repeatUnit,
        );

        while (!candidate.isAfter(monthEnd)) {
          final dateKey = DateTime(candidate.year, candidate.month, candidate.day);
          map.putIfAbsent(dateKey, () => []).add(reminder);
          candidate = addSingleStep(
            candidate,
            type: reminder.repeatType,
            interval: reminder.repeatInterval,
            unit: reminder.repeatUnit,
          );
        }
      }
    }
    return map;
  }

  /// Active subscription renewal dates that fall within the focused month,
  /// bounded to the visible month (§4, §17.1). Returns date -> subscription.
  Map<DateTime, List<Subscription>> _buildMonthRenewalsMap(List<Subscription> subscriptions) {
    final map = <DateTime, List<Subscription>>{};
    final monthStart = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final monthEnd = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0, 23, 59, 59);

    for (final sub in subscriptions) {
      if (!sub.isActive) continue;
      final dateKey = DateTime(sub.nextRenewalDate.year, sub.nextRenewalDate.month, sub.nextRenewalDate.day);
      if (dateKey.isBefore(monthStart) || dateKey.isAfter(monthEnd)) continue;
      map.putIfAbsent(dateKey, () => []).add(sub);
    }
    return map;
  }

  void _showDayRemindersBottomSheet(
    BuildContext context,
    DateTime day,
    List<Reminder> dayReminders,
    List<Subscription> dayRenewals,
  ) {
    final categoryProvider = context.read<CategoryProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.6,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('EEEE, d MMMM yyyy').format(day),
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Add reminder for this date',
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddEditReminderScreen(initialDate: day),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const Divider(),
              if (dayRenewals.isNotEmpty) ...[
                Text(
                  'Subscription renewals',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.tertiary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                ...dayRenewals.map((s) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.autorenew),
                      title: Text(s.name),
                      subtitle: Text('${s.price.toStringAsFixed(2)} ${s.currency} · ${s.billingCycle.displayName}'),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddEditSubscriptionScreen(subscription: s),
                          ),
                        );
                      },
                    )),
                const Divider(),
              ],
              if (dayReminders.isEmpty && dayRenewals.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(child: Text('No reminders scheduled for this day.')),
                )
              else if (dayReminders.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: dayReminders.length,
                    itemBuilder: (context, idx) {
                      final r = dayReminders[idx];
                      final category = categoryProvider.getCategoryById(r.categoryId) ?? Category.defaultCategory;
                      return ReminderTile(
                        reminder: r,
                        category: category,
                        onCompleteChanged: (_) {
                          context.read<ReminderProvider>().completeReminder(r.id, categoryName: category.name);
                          Navigator.pop(ctx);
                        },
                        onFavoriteToggle: () => context.read<ReminderProvider>().toggleFavorite(r.id),
                        onTap: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReminderDetailScreen(reminderId: r.id),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();
    final reminderProvider = context.watch<ReminderProvider>();
    final subscriptionProvider = context.watch<SubscriptionProvider>();

    final occurrencesMap = _buildMonthOccurrencesMap(reminderProvider.reminders);
    final renewalsMap = _buildMonthRenewalsMap(subscriptionProvider.subscriptions);

    final weekStartsMonday = settings.weekStartsMonday;
    final weekdays = weekStartsMonday
        ? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
        : ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    final daysInMonthCount = DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);

    int startOffset = firstDayOfMonth.weekday;
    if (weekStartsMonday) {
      startOffset = firstDayOfMonth.weekday - 1;
    } else {
      startOffset = firstDayOfMonth.weekday % 7;
    }

    final totalGridCells = ((startOffset + daysInMonthCount) / 7).ceil() * 7;
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);

    final selectedDayReminders = occurrencesMap[_selectedDay] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('MMMM yyyy').format(_focusedMonth)),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Go to Today',
            onPressed: _goToToday,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous month',
            onPressed: _previousMonth,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next month',
            onPressed: _nextMonth,
          ),
        ],
      ),
      body: Column(
        children: [
          // Weekday Headers
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: weekdays
                  .map((w) => SizedBox(
                        width: 40,
                        child: Text(
                          w,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),

          // Month Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: totalGridCells,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemBuilder: (context, index) {
                final dayNumber = index - startOffset + 1;
                if (dayNumber < 1 || dayNumber > daysInMonthCount) {
                  return const SizedBox.shrink();
                }

                final cellDate = DateTime(_focusedMonth.year, _focusedMonth.month, dayNumber);
                final isToday = cellDate.isAtSameMomentAs(todayDate);
                final isSelected = cellDate.isAtSameMomentAs(_selectedDay);

                final dayReminders = occurrencesMap[cellDate] ?? [];
                final dayRenewals = renewalsMap[cellDate] ?? const [];
                final hasOverdue = dayReminders.any((r) => !r.isCompleted && cellDate.isBefore(todayDate));

                final statusColors = theme.extension<AppStatusColors>() ?? AppStatusColors.light;

                return InkWell(
                  onTap: () {
                    setState(() => _selectedDay = cellDate);
                    _showDayRemindersBottomSheet(context, cellDate, dayReminders, dayRenewals);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : (isToday ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.5) : null),
                      border: isToday ? Border.all(color: theme.colorScheme.primary, width: 2) : null,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$dayNumber',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                            color: hasOverdue ? statusColors.overdue : null,
                          ),
                        ),
                        if (dayReminders.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: dayReminders.take(3).map((r) {
                              return Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: r.isCompleted
                                      ? statusColors.completed
                                      : (cellDate.isBefore(todayDate) ? statusColors.overdue : theme.colorScheme.primary),
                                ),
                              );
                            }).toList(),
                          ),
                          if (dayRenewals.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.tertiary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.autorenew, size: 9, color: theme.colorScheme.tertiary),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${dayRenewals.length}',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.tertiary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 9,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 24),

          // Selected Day Detail List Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('EEEE, d MMMM').format(_selectedDay),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${selectedDayReminders.length} items',
                  style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Expanded(
            child: selectedDayReminders.isEmpty
                ? Center(
                    child: Text(
                      'No reminders on this day.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  )
                : ListView.builder(
                    itemCount: selectedDayReminders.length,
                    itemBuilder: (context, idx) {
                      final r = selectedDayReminders[idx];
                      final categoryProvider = context.watch<CategoryProvider>();
                      final category = categoryProvider.getCategoryById(r.categoryId) ?? Category.defaultCategory;
                      return ReminderTile(
                        reminder: r,
                        category: category,
                        onCompleteChanged: (_) {
                          context.read<ReminderProvider>().completeReminder(r.id, categoryName: category.name);
                        },
                        onFavoriteToggle: () => context.read<ReminderProvider>().toggleFavorite(r.id),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReminderDetailScreen(reminderId: r.id),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddEditReminderScreen(initialDate: _selectedDay),
            ),
          );
        },
        tooltip: 'Add reminder for selected date',
        child: const Icon(Icons.add),
      ),
    );
  }
}
