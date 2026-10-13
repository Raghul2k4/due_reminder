import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../data/models/reminder.dart';
import '../../data/models/subscription.dart';
import '../../data/models/subscription_enums.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize({
    Function(String? payload)? onSelectNotification,
    Function(String? payload, String? actionId)? onSelectNotificationAction,
  }) async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    // DateTime.now().timeZoneName returns an abbreviation (IST/EST) on
    // Android, not an IANA name. Try common IANA guesses first, then fall
    // back to UTC rather than crashing scheduling.
    try {
      const candidates = [
        'Asia/Kolkata',
        'Asia/Dubai',
        'America/New_York',
        'America/Chicago',
        'America/Los_Angeles',
        'Europe/London',
        'Europe/Paris',
        'Australia/Sydney',
      ];
      final offset = DateTime.now().timeZoneOffset;
      tz.Location? match;
      for (final name in candidates) {
        try {
          final loc = tz.getLocation(name);
          final probe = tz.TZDateTime.now(loc);
          if (probe.timeZoneOffset == offset) {
            match = loc;
            break;
          }
        } catch (_) {
          continue;
        }
      }
      tz.setLocalLocation(match ?? tz.getLocation('UTC'));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.actionId != null && response.actionId!.isNotEmpty) {
          if (onSelectNotificationAction != null) {
            onSelectNotificationAction(response.payload, response.actionId);
          }
          return;
        }
        if (onSelectNotification != null) {
          onSelectNotification(response.payload);
        }
      },
    );

    await _createNotificationChannels();
    _isInitialized = true;
  }

  Future<void> _createNotificationChannels() async {
    const remindersChannel = AndroidNotificationChannel(
      'reminders_channel',
      'Reminders',
      description: 'Notifications for due life reminders',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    const overdueChannel = AndroidNotificationChannel(
      'overdue_channel',
      'Overdue Summary',
      description: 'Summary notification for overdue reminders',
      importance: Importance.low,
      playSound: false,
    );

    const subscriptionsChannel = AndroidNotificationChannel(
      'subscriptions_channel',
      'Subscriptions',
      description: 'Reminders for upcoming subscription renewals',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(remindersChannel);
      await androidImplementation.createNotificationChannel(overdueChannel);
      await androidImplementation.createNotificationChannel(subscriptionsChannel);
    }
  }

  Future<void> scheduleReminderNotification(Reminder reminder, {String categoryName = ''}) async {
    if (!reminder.notificationEnabled || reminder.isCompleted || reminder.isDeleted) {
      await cancelNotification(reminder.notificationId);
      return;
    }

    final scheduledDate = reminder.snoozedUntil ?? reminder.notificationTime ?? reminder.nextDueDate;
    if (scheduledDate.isBefore(DateTime.now())) {
      return;
    }

    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'reminders_channel',
      'Reminders',
      channelDescription: 'Notifications for due life reminders',
      importance: Importance.high,
      priority: Priority.high,
      actions: [
        AndroidNotificationAction('action_done', 'Done', inputs: []),
        AndroidNotificationAction('action_snooze', 'Snooze', inputs: []),
      ],
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        id: reminder.notificationId,
        title: reminder.title,
        body: categoryName.isNotEmpty ? categoryName : 'Life Reminder',
        scheduledDate: tzScheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'reminder:${reminder.id}',
      );
    } catch (e) {
      try {
        await _notificationsPlugin.zonedSchedule(
          id: reminder.notificationId,
          title: reminder.title,
          body: categoryName.isNotEmpty ? categoryName : 'Life Reminder',
          scheduledDate: tzScheduledDate,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexact,
          payload: 'reminder:${reminder.id}',
        );
      } catch (err) {
        debugPrint('Failed to schedule notification: $err');
      }
    }
  }

  /// Schedules (or cancels) the renewal reminder for [subscription].
  ///
  /// The notification fires [Subscription.reminderLead] days before the next
  /// renewal. Paused/cancelled subscriptions, or reminders turned off, cancel
  /// any pending notification instead. Duplicate prevention relies on the stable
  /// per-subscription notification id: re-scheduling the same id replaces the
  /// previous one (§3).
  Future<void> scheduleSubscriptionNotification(Subscription subscription) async {
    if (!subscription.reminderEnabled || !subscription.isActive) {
      await cancelNotification(subscription.notificationId);
      return;
    }

    // Reminder fires lead days before the renewal, at 09:00 local.
    final renewalDay = DateTime(
      subscription.nextRenewalDate.year,
      subscription.nextRenewalDate.month,
      subscription.nextRenewalDate.day,
      9,
    );
    final scheduledDate =
        renewalDay.subtract(Duration(days: subscription.reminderLead.leadDays));

    if (scheduledDate.isBefore(DateTime.now())) {
      // A stale reminder time would never fire; drop it rather than pile up.
      await cancelNotification(subscription.notificationId);
      return;
    }

    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);
    final body = '${subscription.billingCycle.displayName} renewal'
        '${subscription.reminderLead == SubscriptionReminderLead.onRenewalDate ? ' today' : ' coming up'}'
        ' · ${subscription.currency} ${subscription.price.toStringAsFixed(2)}';

    const androidDetails = AndroidNotificationDetails(
      'subscriptions_channel',
      'Subscriptions',
      channelDescription: 'Reminders for upcoming subscription renewals',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        id: subscription.notificationId,
        title: '${subscription.name} renews soon',
        body: body,
        scheduledDate: tzScheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'subscription:${subscription.id}',
      );
    } catch (e) {
      try {
        await _notificationsPlugin.zonedSchedule(
          id: subscription.notificationId,
          title: '${subscription.name} renews soon',
          body: body,
          scheduledDate: tzScheduledDate,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexact,
          payload: 'subscription:${subscription.id}',
        );
      } catch (err) {
        debugPrint('Failed to schedule subscription notification: $err');
      }
    }
  }

  Future<void> showOverdueSummaryNotification(int overdueCount) async {
    if (overdueCount <= 0) return;

    const androidDetails = AndroidNotificationDetails(
      'overdue_channel',
      'Overdue Summary',
      channelDescription: 'Summary notification for overdue reminders',
      importance: Importance.low,
      priority: Priority.low,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      id: 999999,
      title: '$overdueCount reminders are running late',
      body: 'Tap to review overdue reminders.',
      notificationDetails: details,
    );
  }

  Future<void> cancelNotification(int notificationId) async {
    await _notificationsPlugin.cancel(id: notificationId);
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
