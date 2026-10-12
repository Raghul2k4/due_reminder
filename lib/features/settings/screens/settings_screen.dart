import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../../app/providers/category_provider.dart';
import '../../../app/providers/reminder_provider.dart';
import '../../../app/providers/settings_provider.dart';
import '../../../app/providers/subscription_provider.dart';
import '../../../core/services/backup_service.dart';
import '../../../data/models/reminder_enums.dart';
import '../../categories/screens/categories_screen.dart';
import '../../statistics/screens/statistics_screen.dart';
import '../../subscriptions/screens/subscriptions_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _packageInfo = info);
    } catch (e) {
      // Version info is a nicety, not a dependency: fall back to the build
      // defaults already rendered by the About section instead of crashing.
      debugPrint('Could not read package info: $e');
    }
  }

  Future<void> _handleExportBackup(BuildContext context) async {
    try {
      final backupService = BackupService();
      final settingsProvider = context.read<SettingsProvider>();
      final path = await backupService.exportBackup();
      final now = DateTime.now();
      await settingsProvider.setLastBackupAt(now);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup exported successfully: $path')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: ${e.toString()}')));
    }
  }

  Future<void> _handleImportBackup(BuildContext context) async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      // An empty list means the user cancelled the picker; treat it as a no-op.
      if (files.isEmpty) return;

      final file = files.first;
      final path = file.path;
      if (path == null) return;

      // Validate
      final backupService = BackupService();

      final fileObj = await File(path).readAsString();
      final valResult = await backupService.validateBackupContent(fileObj);

      if (!valResult.isValid) {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('That file didn\'t work.'),
              content: Text(valResult.errorMessage ?? 'Invalid backup file.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }

      if (!context.mounted) return;

      // Ask strategy
      final strategy = await showDialog<ImportStrategy>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Import Backup'),
          content: Text(
            'File contains ${valResult.reminderCount} reminders and ${valResult.categoryCount} categories.\n\nChoose import mode:',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, ImportStrategy.merge),
              child: const Text('Merge (Recommended)'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, ImportStrategy.replace),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Replace All Data'),
            ),
          ],
        ),
      );

      if (strategy != null && context.mounted) {
        final reminderProvider = context.read<ReminderProvider>();
        final categoryProvider = context.read<CategoryProvider>();
        await backupService.importBackup(
          valResult.parsedJson!,
          strategy: strategy,
        );
        if (!context.mounted) return;
        await reminderProvider.loadReminders();
        await categoryProvider.loadCategories();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup imported successfully!')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Import failed: ${e.toString()}')));
    }
  }

  Future<void> _handleClearCompleted(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear completed reminders?'),
        content: const Text(
          'This will permanently remove all completed non-recurring reminders.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final count = await context
          .read<ReminderProvider>()
          .clearCompletedReminders();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cleared $count completed reminders.')),
        );
      }
    }
  }

  Future<void> _handleDeleteAllData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete ALL data?'),
        content: const Text(
          'WARNING: This action is permanent and will wipe all reminders, categories, and settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Wipe Everything'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final subscriptionProvider = context.read<SubscriptionProvider>();
      await context.read<ReminderProvider>().deleteAllData();
      await subscriptionProvider.loadSubscriptions();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('All data deleted.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final categoryProvider = context.watch<CategoryProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Features Shortcuts Card Section
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('Manage Categories'),
            subtitle: const Text('Add, edit, or archive reminder categories'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CategoriesScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart_outlined),
            title: const Text('View Statistics'),
            subtitle: const Text('Track completion rates and habits'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StatisticsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.autorenew),
            title: const Text('Manage Subscriptions'),
            subtitle: const Text('Track renewals and recurring spending'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionsScreen()),
              );
            },
          ),
          const Divider(),

          // Appearance Section
          _buildHeader(context, 'Appearance'),
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Theme Mode'),
            trailing: DropdownButton<ThemeModePreference>(
              value: settings.themeMode,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(
                  value: ThemeModePreference.system,
                  child: Text('System'),
                ),
                DropdownMenuItem(
                  value: ThemeModePreference.light,
                  child: Text('Light'),
                ),
                DropdownMenuItem(
                  value: ThemeModePreference.dark,
                  child: Text('Dark'),
                ),
              ],
              onChanged: (mode) {
                if (mode != null) settings.setThemeMode(mode);
              },
            ),
          ),
          const Divider(),

          // Notifications Section
          _buildHeader(context, 'Notifications'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            subtitle: const Text('Master toggle for due reminders'),
            value: settings.notificationsEnabled,
            onChanged: (val) => settings.setNotificationsEnabled(val),
          ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Default Notification Time'),
            trailing: Text(settings.defaultNotificationTime),
            onTap: () async {
              final parts = settings.defaultNotificationTime.split(':');
              final initial = TimeOfDay(
                hour: int.parse(parts[0]),
                minute: int.parse(parts[1]),
              );
              final picked = await showTimePicker(
                context: context,
                initialTime: initial,
              );
              if (picked != null) {
                final formatted =
                    '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                settings.setDefaultNotificationTime(formatted);
              }
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.volume_up_outlined),
            title: const Text('Sound'),
            value: settings.notificationSound,
            onChanged: (val) => settings.setNotificationSound(val),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.vibration),
            title: const Text('Vibration'),
            value: settings.notificationVibration,
            onChanged: (val) => settings.setNotificationVibration(val),
          ),
          const Divider(),

          // General Section
          _buildHeader(context, 'General'),
          SwitchListTile(
            secondary: const Icon(Icons.calendar_view_week),
            title: const Text('Week Starts Monday'),
            subtitle: Text(settings.weekStartsMonday ? 'Monday' : 'Sunday'),
            value: settings.weekStartsMonday,
            onChanged: (val) => settings.setWeekStartsMonday(val),
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Default Category'),
            trailing: DropdownButton<String>(
              value:
                  categoryProvider.getCategoryById(
                        settings.defaultCategoryId,
                      ) !=
                      null
                  ? settings.defaultCategoryId
                  : 'cat_other',
              underline: const SizedBox.shrink(),
              items: categoryProvider.categories.map((c) {
                return DropdownMenuItem(value: c.id, child: Text(c.name));
              }).toList(),
              onChanged: (catId) {
                if (catId != null) settings.setDefaultCategoryId(catId);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: const Text('Default Priority'),
            trailing: DropdownButton<Priority>(
              value: settings.defaultPriority,
              underline: const SizedBox.shrink(),
              items: Priority.values.map((p) {
                return DropdownMenuItem(value: p, child: Text(p.displayName));
              }).toList(),
              onChanged: (p) {
                if (p != null) settings.setDefaultPriority(p);
              },
            ),
          ),
          const Divider(),

          // Data Management Section
          _buildHeader(context, 'Data & Backup'),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Export JSON Backup'),
            subtitle: Text(
              settings.lastBackupAt != null
                  ? 'Last backup: ${settings.lastBackupAt}'
                  : 'Save all reminders and categories',
            ),
            onTap: () => _handleExportBackup(context),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Import JSON Backup'),
            subtitle: const Text('Restore data with safe validation'),
            onTap: () => _handleImportBackup(context),
          ),
          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined),
            title: const Text('Clear Completed Reminders'),
            onTap: () => _handleClearCompleted(context),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              'Delete All Data',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => _handleDeleteAllData(context),
          ),
          const Divider(),

          // About Section (§8.8, §15)
          _buildHeader(context, 'About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Life Reminder'),
            subtitle: Text(
              'Version ${_packageInfo?.version ?? '1.0.0'} (Build ${_packageInfo?.buildNumber ?? '1'})\n"Remember the things that repeat."',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Privacy Statement'),
            subtitle: const Text(
              'All data stays on this device. Zero network calls, zero tracking, zero analytics.',
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
