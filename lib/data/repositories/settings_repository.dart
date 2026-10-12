import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/reminder_enums.dart';

class SettingsRepository {
  final AppDatabase _dbProvider;

  SettingsRepository([AppDatabase? dbProvider]) : _dbProvider = dbProvider ?? AppDatabase();

  Future<String?> _getString(String key) async {
    try {
      final db = await _dbProvider.database;
      final result = await db.query('settings', where: 'key = ?', whereArgs: [key]);
      if (result.isEmpty) return null;
      return result.first['value'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> _setString(String key, String value) async {
    final db = await _dbProvider.database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> _getBool(String key, bool defaultValue) async {
    final str = await _getString(key);
    if (str == null) return defaultValue;
    return str.toLowerCase() == 'true' || str == '1';
  }

  Future<void> _setBool(String key, bool value) async {
    await _setString(key, value ? 'true' : 'false');
  }

  // Theme Mode
  Future<ThemeModePreference> getThemeMode() async {
    final str = await _getString('theme_mode');
    if (str == null) return ThemeModePreference.system;
    return ThemeModePreferenceExtension.fromString(str);
  }

  Future<void> setThemeMode(ThemeModePreference mode) async {
    await _setString('theme_mode', mode.toName());
  }

  // Notifications enabled
  Future<bool> getNotificationsEnabled() async {
    return _getBool('notifications_enabled', true);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _setBool('notifications_enabled', enabled);
  }

  // Default notification time (HH:mm)
  Future<String> getDefaultNotificationTime() async {
    return (await _getString('default_notification_time')) ?? '09:00';
  }

  Future<void> setDefaultNotificationTime(String timeStr) async {
    await _setString('default_notification_time', timeStr);
  }

  // Notification Sound
  Future<bool> getNotificationSound() async {
    return _getBool('notification_sound', true);
  }

  Future<void> setNotificationSound(bool value) async {
    await _setBool('notification_sound', value);
  }

  // Notification Vibration
  Future<bool> getNotificationVibration() async {
    return _getBool('notification_vibration', true);
  }

  Future<void> setNotificationVibration(bool value) async {
    await _setBool('notification_vibration', value);
  }

  // Advance Offset
  Future<AdvanceNotificationOffset> getDefaultAdvanceOffset() async {
    final str = await _getString('default_advance_offset');
    if (str == null) return AdvanceNotificationOffset.atTime;
    return AdvanceNotificationOffsetExtension.fromString(str);
  }

  Future<void> setDefaultAdvanceOffset(AdvanceNotificationOffset offset) async {
    await _setString('default_advance_offset', offset.toName());
  }

  // Week Starts Monday
  Future<bool> getWeekStartsMonday() async {
    return _getBool('week_starts_monday', true);
  }

  Future<void> setWeekStartsMonday(bool value) async {
    await _setBool('week_starts_monday', value);
  }

  // Default Category ID
  Future<String> getDefaultCategoryId() async {
    return (await _getString('default_category_id')) ?? 'cat_other';
  }

  Future<void> setDefaultCategoryId(String categoryId) async {
    await _setString('default_category_id', categoryId);
  }

  // Default Priority
  Future<Priority> getDefaultPriority() async {
    final str = await _getString('default_priority');
    if (str == null) return Priority.medium;
    return PriorityExtension.fromString(str);
  }

  Future<void> setDefaultPriority(Priority priority) async {
    await _setString('default_priority', priority.toName());
  }

  // Last Backup At
  Future<String?> getLastBackupAt() async {
    return _getString('last_backup_at');
  }

  Future<void> setLastBackupAt(DateTime time) async {
    await _setString('last_backup_at', time.toIso8601String());
  }
}
