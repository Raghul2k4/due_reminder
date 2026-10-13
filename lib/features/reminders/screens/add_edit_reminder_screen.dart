import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../app/providers/category_provider.dart';
import '../../../app/providers/reminder_provider.dart';
import '../../../app/providers/settings_provider.dart';
import '../../../core/utils/recurrence.dart';
import '../../../data/models/category.dart';
import '../../../data/models/reminder.dart';
import '../../../data/models/reminder_enums.dart';
import '../models/reminder_templates.dart';

class AddEditReminderScreen extends StatefulWidget {
  final Reminder? reminder;
  final String initialTitle;
  final DateTime? initialDate;
  final ReminderTemplate? template;

  const AddEditReminderScreen({
    super.key,
    this.reminder,
    this.initialTitle = '',
    this.initialDate,
    this.template,
  });

  @override
  State<AddEditReminderScreen> createState() => _AddEditReminderScreenState();
}

class _AddEditReminderScreenState extends State<AddEditReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController =/controllers/textInput();

  late String _categoryId;
  late Priority _priority;
  late DateTime _startDate;
  late DateTime _dueDate;
  DateTime? _dueTime;
  bool _isAllDay = true;

  late RepeatType _repeatType;
  int _repeatInterval = 1;
  RepeatUnit _repeatUnit = RepeatUnit.days;

  bool _notificationEnabled = true;
  DateTime? _notificationTime;

  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();

    if (widget.reminder != null) {
      final r = widget.reminder!;
      _titleController.text = r.title;
      _descriptionController.text = r.description ?? '';
      _categoryId = r.categoryId;
      _priority = r.priority;
      _amountController.text = r.amount?.toString() ?? '';
      _currency = r.currency ?? 'USD';
      _startDate = r.startDate;
      _dueDate = r.dueDate;
      _dueTime = r.dueTime;
      _isAllDay = r.dueTime == null;
      _repeatType = r.repeatType;
      _repeatInterval = r.repeatInterval;
      _repeatUnit = r.repeatUnit;
      _notificationEnabled = r.notificationEnabled;
      _notificationTime = r.notificationTime;
    } else {
      _titleController.text = widget.template?.title ?? widget.initialTitle;
      _categoryId = widget.template?.categoryId ?? settings.defaultCategoryId;
      _priority = settings.defaultPriority;
      final now = widget.initialDate ?? DateTime.now();
      _startDate = DateTime(now.year, now.month, now.day);
      _dueDate = _startDate;
      _repeatType =
          widget.template?.repeatType ?? RepeatType.none;
      _repeatInterval = widget.template?.repeatInterval ?? 1;
      _repeatUnit = widget.template?.repeatUnit ?? RepeatUnit.days;
      _notificationEnabled = settings.notificationsEnabled;
    }

    _titleController.addListener(_markDirty);
    _descriptionController.addListener(_markDirty);
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  List<DateTime> _calculateNextOccurrencesPreview() {
    return computeUpcomingOccurrences(
      anchor: _dueDate,
      from: _dueDate.add(const Duration(seconds: -1)),
      type: _repeatType,
      interval: _repeatInterval,
      unit: _repeatUnit,
      count: 3,
    );
  }

  Future<bool> _onWillPop() async {
    if (!_isDirty) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard unsaved changes?'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim();

    final categoryProvider = context.read<CategoryProvider>();
    final category =
        categoryProvider.getCategoryById(_categoryId) ??
        Category.defaultCategory;
    final reminderProvider = context.read<ReminderProvider>();

    final now = DateTime.now();
    final effectiveDueTime = _isAllDay ? null : _dueTime;

    final newNotificationTime = _notificationEnabled
        ? (_notificationTime ??
              effectiveDueTime ??
              DateTime(_dueDate.year, _dueDate.month, _dueDate.day, 9, 0))
        : null;

    if (widget.reminder != null) {
      final updated = widget.reminder!.copyWith(
        title: title,
        description: description,
        clearDescription: description == null,
        categoryId: _categoryId,
        priority: _priority,
        startDate: _startDate,
        dueDate: _dueDate,
        dueTime: effectiveDueTime,
        clearDueTime: effectiveDueTime == null,
        repeatType: _repeatType,
        repeatInterval: _repeatInterval,
        repeatUnit: _repeatUnit,
        notificationEnabled: _notificationEnabled,
        notificationTime: newNotificationTime,
        clearNotificationTime: newNotificationTime == null,
        nextDueDate: computeNextDueDate(
          anchor: _dueDate,
          from: now,
          type: _repeatType,
          interval: _repeatInterval,
          unit: _repeatUnit,
        ),
      );
      await reminderProvider.updateReminder(
        updated,
        categoryName: category.name,
      );
    } else {
      final newReminder = Reminder(
        id: '',
        title: title,
        description: description,
        categoryId: _categoryId,
        priority: _priority,
        createdAt: now,
        startDate: _startDate,
        dueDate: _dueDate,
        dueTime: effectiveDueTime,
        repeatType: _repeatType,
        repeatInterval: _repeatInterval,
        repeatUnit: _repeatUnit,
        notificationEnabled: _notificationEnabled,
        notificationTime: newNotificationTime,
        notificationId: 0,
        nextDueDate: computeNextDueDate(
          anchor: _dueDate,
          from: _startDate.isBefore(_dueDate)
              ? _startDate.add(const Duration(seconds: -1))
              : _dueDate.add(const Duration(seconds: -1)),
          type: _repeatType,
          interval: _repeatInterval,
          unit: _repeatUnit,
        ),
      );
      await reminderProvider.createReminder(
        newReminder,
        categoryName: category.name,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryProvider = context.watch<CategoryProvider>();

    final isEdit = widget.reminder != null;

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEdit ? 'Edit Reminder' : 'New Reminder'),
          actions: [
            FilledButton(onPressed: _save, child: const Text('Save')),
            const SizedBox(width: 16),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  hintText: 'e.g. Water filter replacement',
                ),
                maxLength: 200,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Add notes or details',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Category Picker
              DropdownButtonFormField<String>(
                initialValue:
                    categoryProvider.getCategoryById(_categoryId) != null
                    ? _categoryId
                    : 'cat_other',
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  prefixIcon: Icon(Icons.category),
                ),
                items: categoryProvider.categories.map((c) {
                  return DropdownMenuItem(
                    value: c.id,
                    child: Row(
                      children: [
                        Icon(
                          Category.getIconData(c.iconKey),
                          color: Color(c.colorValue),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(c.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _categoryId = val;
                      _markDirty();
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Priority Selector
              Text('Priority', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<Priority>(
                segments: const [
                  ButtonSegment(
                    value: Priority.low,
                    label: Text('Low'),
                    icon: Icon(Icons.circle_outlined, size: 12),
                  ),
                  ButtonSegment(
                    value: Priority.medium,
                    label: Text('Medium'),
                    icon: Icon(Icons.circle, size: 12),
                  ),
                  ButtonSegment(
                    value: Priority.high,
                    label: Text('High'),
                    icon: Icon(Icons.error, size: 12),
                  ),
                ],
                selected: {_priority},
                onSelectionChanged: (set) {
                  setState(() {
                    _priority = set.first;
                    _markDirty();
                  });
                },
              ),
              const SizedBox(height: 24),

              // Schedule Section Header
              Text(
                'Schedule',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(),

              // Date Picker ListTile
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Due Date'),
                subtitle: Text(
                  DateFormat('EEEE, d MMMM yyyy').format(_dueDate),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dueDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) {
                    setState(() {
                      _dueDate = picked;
                      _startDate = picked;
                      _markDirty();
                    });
                  }
                },
              ),

              // All-day & Time Picker
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('All day'),
                value: _isAllDay,
                onChanged: (val) {
                  setState(() {
                    _isAllDay = val;
                    if (!val && _dueTime == null) {
                      _dueTime = DateTime(
                        _dueDate.year,
                        _dueDate.month,
                        _dueDate.day,
                        9,
                        0,
                      );
                    }
                    _markDirty();
                  });
                },
              ),
              if (!_isAllDay)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time),
                  title: const Text('Due Time'),
                  subtitle: Text(
                    _dueTime != null
                        ? DateFormat('h:mm a').format(_dueTime!)
                        : '9:00 AM',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _dueTime != null
                          ? TimeOfDay.fromDateTime(_dueTime!)
                          : const TimeOfDay(hour: 9, minute: 0),
                    );
                    if (picked != null) {
                      setState(() {
                        _dueTime = DateTime(
                          _dueDate.year,
                          _dueDate.month,
                          _dueDate.day,
                          picked.hour,
                          picked.minute,
                        );
                        _markDirty();
                      });
                    }
                  },
                ),

              // Repeat Picker
              DropdownButtonFormField<RepeatType>(
                initialValue: _repeatType,
                decoration: const InputDecoration(
                  labelText: 'Repeat Schedule',
                  prefixIcon: Icon(Icons.repeat),
                ),
                items: RepeatType.values.map((t) {
                  return DropdownMenuItem(value: t, child: Text(t.displayName));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _repeatType = val;
                      _markDirty();
                    });
                  }
                },
              ),
              const SizedBox(height: 12),

              // Custom Recurrence Interval Stepper & Unit
              if (_repeatType == RepeatType.custom) ...[
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          const Text('Every '),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: _repeatInterval > 1
                                ? () {
                                    setState(() {
                                      _repeatInterval--;
                                      _markDirty();
                                    });
                                  }
                                : null,
                          ),
                          Text(
                            '$_repeatInterval',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () {
                              setState(() {
                                _repeatInterval++;
                                _markDirty();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<RepeatUnit>(
                        initialValue: _repeatUnit,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        items: RepeatUnit.values.map((u) {
                          return DropdownMenuItem(
                            value: u,
                            child: Text(u.displayName),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _repeatUnit = val;
                              _markDirty();
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // LIVE PREVIEW OF NEXT 3 OCCURRENCES (§8.2 mandatory)
              if (_repeatType != RepeatType.none) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.preview,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Next 3 Occurrences Preview:',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _calculateNextOccurrencesPreview()
                            .map((d) => DateFormat('d MMM yyyy').format(d))
                            .join('  ·  '),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Notification Section Header
              Text(
                'Notifications',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enable Reminders'),
                subtitle: const Text('Receive local notification when due'),
                value: _notificationEnabled,
                onChanged: (val) {
                  setState(() {
                    _notificationEnabled = val;
                    _markDirty();
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
