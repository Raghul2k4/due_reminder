import 'dart:async';
import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/services/notification_service.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('Uncaught Flutter Error: ${details.exceptionAsString()}');
    };

    // Initialize notification service & timezone before runApp.
    final notifications = NotificationService();
    await notifications.initialize(
      onSelectNotification: handleNotificationTap,
      onSelectNotificationAction: handleNotificationAction,
    );

    runApp(const LifeReminderApp());
  }, (error, stackTrace) {
    debugPrint('Uncaught Async Error: $error\n$stackTrace');
  });
}
