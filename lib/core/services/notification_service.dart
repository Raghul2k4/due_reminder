import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../data/models/reminder.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize({Function(String? payload)? onSelectNotification}) async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    final String timeZoneName = DateTime.now().timeZoneName;
    try {
      tz.setLocalLocation(tz.getLocation(timeZoneName));
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

    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(remindersChannel);
      await androidImplementation.createNotificationChannel(overdueChannel);
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
        payload: reminder.id,
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
          payload: reminder.id,
        );
      } catch (err) {
        debugPrint('Failed to schedule notification: $err');
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
