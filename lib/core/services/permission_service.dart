import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PermissionService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<bool> requestNotificationPermission() async {
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final granted = await androidImplementation.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  Future<bool> requestExactAlarmPermission() async {
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final granted = await androidImplementation.requestExactAlarmsPermission();
      return granted ?? false;
    }
    return true;
  }
}
