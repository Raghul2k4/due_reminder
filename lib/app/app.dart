import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/reminders/screens/reminder_detail_screen.dart';
import 'main_navigation_screen.dart';
import 'providers/category_provider.dart';
import 'providers/reminder_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/statistics_provider.dart';
import 'providers/subscription_provider.dart';
import 'theme/app_theme.dart';
import '../core/services/notification_service.dart';
import '../data/repositories/reminder_repository.dart';

/// Global navigator key so notification taps can deep-link even on cold start.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

Future<void> handleNotificationTap(String? payload) async {
  if (payload == null || payload.isEmpty) return;
  // Legacy payloads are bare reminder ids; new ones are prefixed.
  String? reminderId;
  String? subscriptionTab;
  if (payload.startsWith('reminder:')) {
    reminderId = payload.substring('reminder:'.length);
  } else if (payload.startsWith('subscription:')) {
    subscriptionTab = payload.substring('subscription:'.length);
  } else if (payload == 'overdue_summary') {
    subscriptionTab = null;
  } else {
    reminderId = payload;
  }
  final nav = appNavigatorKey.currentContext;
  if (nav == null) return;
  if (reminderId != null && reminderId.isNotEmpty) {
    Navigator.of(nav).push(
      MaterialPageRoute(
        builder: (_) => ReminderDetailScreen(reminderId: reminderId!),
      ),
    );
  } else if (subscriptionTab != null) {
    // Subscriptions live at tab index 3; fall back to home for summary.
    Navigator.of(nav).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const _NotificationLandingTab(index: 3),
      ),
      (_) => false,
    );
  }
}

/// Handles Done / Snooze actions tapped in the shade.
///
/// Runs the §9.4 completion flow (Done) or sets `snoozedUntil` only (Snooze)
/// so recurrence is never corrupted, then reschedules.
Future<void> handleNotificationAction(String? payload, String? actionId) async {
  if (payload == null || payload.isEmpty) return;
  final id = payload.startsWith('reminder:')
      ? payload.substring('reminder:'.length)
      : payload;
  if (id.isEmpty || id == 'overdue_summary' || payload.startsWith('subscription:')) {
    return;
  }
  try {
    final repo = ReminderRepository();
    if (actionId == 'action_done') {
      await repo.completeReminder(id, now: DateTime.now(), source: 'notification');
    } else if (actionId == 'action_snooze') {
      await repo.snoozeReminder(
        id,
        DateTime.now().add(const Duration(hours: 3)),
      );
    }
    final updated = await repo.getReminderById(id);
    if (updated != null) {
      await NotificationService().scheduleReminderNotification(updated);
    }
  } catch (_) {
    // Shade actions must never crash the app; the reminder stays as-is.
  }
}

class _NotificationLandingTab extends StatelessWidget {
  final int index;
  const _NotificationLandingTab({required this.index});

  @override
  Widget build(BuildContext context) {
    return MainNavigationScreen(initialIndex: index);
  }
}

class LifeReminderApp extends StatelessWidget {
  const LifeReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()..loadSettings()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()..loadCategories()),
        ChangeNotifierProvider(create: (_) => ReminderProvider()..catchUpOnLaunch()),
        ChangeNotifierProvider(create: (_) => StatisticsProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()..catchUpOnLaunch()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Life Reminder',
            debugShowCheckedModeBanner: false,
            navigatorKey: appNavigatorKey,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.materialThemeMode,
            home: const MainNavigationScreen(),
          );
        },
      ),
    );
  }
}
