import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'main_navigation_screen.dart';
import 'providers/category_provider.dart';
import 'providers/reminder_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/statistics_provider.dart';
import 'theme/app_theme.dart';

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
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Life Reminder',
            debugShowCheckedModeBanner: false,
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
