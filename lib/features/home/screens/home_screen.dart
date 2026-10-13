import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../app/providers/category_provider.dart';
import '../../../app/providers/reminder_provider.dart';
import '../../../core/services/quick_add_parser.dart';
import '../../../data/models/category.dart';
import '../../../data/models/reminder.dart';
import '../../../data/models/reminder_enums.dart';
import '../../../data/repositories/reminder_repository.dart';
import '../../../shared/empty_state_widget.dart';
import '../../reminders/screens/add_edit_reminder_screen.dart';
import '../../reminders/screens/reminder_detail_screen.dart';
import '../../reminders/widgets/reminder_tile.dart';

import '../../reminders/widgets/reminder_template_sheet.dart';

class HomeScreen extends StatefulWidget {
  final Function(int index)? onNavigateToTab;

  const HomeScreen({super.key, this.onNavigateToTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _recentlyCompletedExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReminderProvider>().loadReminders();
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _showQuickAddBottomSheet(BuildContext context) {
    final textController = TextEditingController();
    QuickAddParseResult? parseResult;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (bottomCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(bottomCtx).viewInsets.bottom + 16,
                top: 24,
                left: 20,
                right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Quick Add Reminder',
                        style: Theme.of(bottomCtx).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.tune),
                        tooltip: 'Full options form',
                        onPressed: () {
                          Navigator.pop(bottomCtx);
                          _openFullAddForm(
                            context,
                            initialTitle: textController.text,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: textController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'e.g. "Bike service every 3 months", "Gym today at 6pm"',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        parseResult = QuickAddParser.parse(val);
                      });
                    },
                    onSubmitted: (val) =>
                        _submitQuickAdd(context, bottomCtx, val),
                  ),
                  if (parseResult != null &&
                      textController.text.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(bottomCtx).colorScheme.primaryContainer
                            .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Parsed preview:',
                            style: Theme.of(bottomCtx).textTheme.labelSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(bottomCtx)
                                      .colorScheme
                                      .primary,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Title: ${parseResult!.title}',
                            style: Theme.of(bottomCtx).textTheme.bodySmall,
                          ),
                          if (parseResult!.repeatType != RepeatType.none)
                            Text(
                              'Recurrence: ${parseResult!.repeatType.displayName} (interval ${parseResult!.repeatInterval})',
                              style: Theme.of(bottomCtx).textTheme.bodySmall,
                            ),
                          Text(
                            'Due: ${DateFormat('d MMM yyyy').format(parseResult!.dueDate)}${parseResult!.dueTime != null ? ' at ${DateFormat('h:mm a').format(parseResult!.dueTime!)}' : ''}',
                            style: Theme.of(bottomCtx).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(bottomCtx),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => _submitQuickAdd(
                          context,
                          bottomCtx,
                          textController.text,
                        ),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(88, 48),
                        ),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitQuickAdd(
    BuildContext context,
    BuildContext bottomSheetContext,
    String input,
  ) async {
    if (input.trim().isEmpty) return;
    Navigator.pop(bottomSheetContext);

    final parsed = QuickAddParser.parse(input);
    final categoryProvider = context.read<CategoryProvider>();
    final reminderProvider = context.read<ReminderProvider>();

    final catId = parsed.categoryHintId ?? 'cat_other';
    final category =
        categoryProvider.getCategoryById(catId) ?? Category.defaultCategory;

    final now = DateTime.now();
    final reminder = Reminder(
      id: '',
      title: parsed.title,
      categoryId: catId,
      priority: parsed.priorityHint,
      createdAt: now,
      startDate: parsed.dueDate,
      dueDate: parsed.dueDate,
      dueTime: parsed.dueTime,
      repeatType: parsed.repeatType,
      repeatInterval: parsed.repeatInterval,
      repeatUnit: parsed.repeatUnit,
      notificationId: 0,
      nextDueDate: parsed.dueDate,
    );

    await reminderProvider.createReminder(
      reminder,
      categoryName: category.name,
    );
  }

  void _openFullAddForm(BuildContext context, {String initialTitle = ''}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditReminderScreen(initialTitle: initialTitle),
      ),
    );
  }

  void _showTemplateSheet(BuildContext context) async {
    final template = await ReminderTemplateSheet.show(context);
    if (template == null || !context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditReminderScreen(template: template),
      ),
    );
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

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          reminder.isRecurring
              ? 'Completed occurrence! Rolled forward to ${DateFormat('d MMM').format(updated.nextDueDate)}'
              : 'Reminder completed',
        ),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            reminderProvider.undoCompletion(
              reminder.id,
              record.id,
              reminder,
              categoryName: category.name,
            );
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
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
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

    final now = DateTime.now();
    final todayStr = DateFormat('EEEE, d MMMM yyyy').format(now);

    final overdueList = reminderProvider.reminders
        .where((r) => !r.isCompleted && r.effectiveDueDate.isBefore(now))
        .toList();

    final todayList = reminderProvider.reminders
        .where(
          (r) =>
              !r.isCompleted &&
              !r.effectiveDueDate.isBefore(now) &&
              r.effectiveDueDate.year == now.year &&
              r.effectiveDueDate.month == now.month &&
              r.effectiveDueDate.day == now.day,
        )
        .toList();

    final upcomingList = reminderProvider.reminders
        .where(
          (r) =>
              !r.isCompleted &&
              r.effectiveDueDate.isAfter(
                DateTime(now.year, now.month, now.day, 23, 59, 59),
              ),
        )
        .toList();

    final completedList = reminderProvider.reminders
        .where((r) => r.isCompleted || r.lastCompletedAt != null)
        .toList();

    final isEmptyAll =
        reminderProvider.reminders.isEmpty && !reminderProvider.isLoading;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Text(
                  _getGreeting(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(width: 7),
                Icon(
                  Icons.waving_hand_rounded,
                  size: 19,
                  color: theme.colorScheme.tertiary,
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              todayStr,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton.filledTonal(
              tooltip: 'Search reminders',
              onPressed: () => widget.onNavigateToTab?.call(2),
              icon: const Icon(Icons.search_rounded),
              style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => reminderProvider.loadReminders(),
        child: isEmptyAll
            ? EmptyStateWidget(
                icon: Icons.notifications_none,
                headline: 'Nothing scheduled yet.',
                body:
                    'Add your first reminder and stop relying on your memory.',
                actionLabel: 'Add reminder',
                onActionPressed: () => _openFullAddForm(context),
              )
            : ListView(
                padding: const EdgeInsets.only(bottom: 88),
                children: [
                  // Counts Row
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        _buildCountCard(
                          context,
                          label: 'Overdue',
                          count: reminderProvider.overdueCount,
                          color: reminderProvider.overdueCount > 0
                              ? theme.colorScheme.error
                              : theme.colorScheme.outline,
                          onTap: () {
                            reminderProvider.setFilter(ReminderFilter.overdue);
                            widget.onNavigateToTab?.call(
                              2,
                            ); // search/filter tab
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildCountCard(
                          context,
                          label: 'Today',
                          count: reminderProvider.todayCount,
                          color: theme.colorScheme.primary,
                          onTap: () {
                            reminderProvider.setFilter(ReminderFilter.today);
                            widget.onNavigateToTab?.call(2);
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildCountCard(
                          context,
                          label: 'Upcoming',
                          count: reminderProvider.upcomingCount,
                          color: theme.colorScheme.tertiary,
                          onTap: () {
                            reminderProvider.setFilter(ReminderFilter.upcoming);
                            widget.onNavigateToTab?.call(2);
                          },
                        ),
                      ],
                    ),
                  ),

                  // Overdue Section (First per §4.3)
                  if (overdueList.isNotEmpty) ...[
                    _buildSectionHeader(
                      context,
                      title: 'Overdue',
                      count: overdueList.length,
                      color: theme.colorScheme.error,
                    ),
                    ...overdueList.map(
                      (r) => ReminderTile(
                        reminder: r,
                        category:
                            categoryProvider.getCategoryById(r.categoryId) ??
                            Category.defaultCategory,
                        onCompleteChanged: (_) => _handleComplete(context, r),
                        onFavoriteToggle: () =>
                            reminderProvider.toggleFavorite(r.id),
                        onSnooze: () => _showSnoozeDialog(context, r),
                        onDelete: () => _handleDelete(context, r),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ReminderDetailScreen(reminderId: r.id),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  // Today Section
                  if (todayList.isNotEmpty) ...[
                    _buildSectionHeader(
                      context,
                      title: 'Today',
                      count: todayList.length,
                      color: theme.colorScheme.primary,
                    ),
                    ...todayList.map(
                      (r) => ReminderTile(
                        reminder: r,
                        category:
                            categoryProvider.getCategoryById(r.categoryId) ??
                            Category.defaultCategory,
                        onCompleteChanged: (_) => _handleComplete(context, r),
                        onFavoriteToggle: () =>
                            reminderProvider.toggleFavorite(r.id),
                        onSnooze: () => _showSnoozeDialog(context, r),
                        onDelete: () => _handleDelete(context, r),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ReminderDetailScreen(reminderId: r.id),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  // Upcoming Section
                  if (upcomingList.isNotEmpty) ...[
                    _buildSectionHeader(
                      context,
                      title: 'Upcoming',
                      count: upcomingList.length,
                      color: theme.colorScheme.tertiary,
                    ),
                    ...upcomingList.map(
                      (r) => ReminderTile(
                        reminder: r,
                        category:
                            categoryProvider.getCategoryById(r.categoryId) ??
                            Category.defaultCategory,
                        onCompleteChanged: (_) => _handleComplete(context, r),
                        onFavoriteToggle: () =>
                            reminderProvider.toggleFavorite(r.id),
                        onSnooze: () => _showSnoozeDialog(context, r),
                        onDelete: () => _handleDelete(context, r),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ReminderDetailScreen(reminderId: r.id),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  // Recently Completed (Collapsed by default per §4.3)
                  if (completedList.isNotEmpty) ...[
                    ExpansionTile(
                      key: const PageStorageKey('completed_section'),
                      initiallyExpanded: _recentlyCompletedExpanded,
                      onExpansionChanged: (exp) =>
                          setState(() => _recentlyCompletedExpanded = exp),
                      title: Text(
                        'Recently completed (${completedList.length})',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      children: completedList
                          .map(
                            (r) => ReminderTile(
                              reminder: r,
                              category:
                                  categoryProvider.getCategoryById(
                                    r.categoryId,
                                  ) ??
                                  Category.defaultCategory,
                              onCompleteChanged: (_) =>
                                  _handleComplete(context, r),
                              onFavoriteToggle: () =>
                                  reminderProvider.toggleFavorite(r.id),
                              onSnooze: () => _showSnoozeDialog(context, r),
                              onDelete: () => _handleDelete(context, r),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ReminderDetailScreen(reminderId: r.id),
                                  ),
                                );
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'templates_fab',
            tooltip: 'Start from a template',
            onPressed: () => _showTemplateSheet(context),
            child: const Icon(Icons.auto_awesome_outlined),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'quickadd_fab',
            onPressed: () => _showQuickAddBottomSheet(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Reminder'),
          ),
        ],
      ),
    );
  }

  Widget _buildCountCard(
    BuildContext context, {
    required String label,
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Material(
            color: theme.colorScheme.surfaceContainerHigh.withValues(
              alpha: 0.72,
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                constraints: const BoxConstraints(minHeight: 86),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.42,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      count.toString(),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color,
                        height: 1.05,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required int count,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
