import 'package:flutter/material.dart';
import '../../data/models/reminder_enums.dart';
import '../../data/repositories/settings_repository.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsRepository _repository;

  ThemeModePreference _themeMode = ThemeModePreference.system;
  bool _notificationsEnabled = true;
  String _defaultNotificationTime = '09:00';
  bool _notificationSound = true;
  bool _notificationVibration = true;
  AdvanceNotificationOffset _defaultAdvanceOffset = AdvanceNotificationOffset.atTime;
  bool _weekStartsMonday = true;
  String _defaultCategoryId = 'cat_other';
  Priority _defaultPriority = Priority.medium;
  String? _lastBackupAt;

  SettingsProvider([SettingsRepository? repository]) : _repository = repository ?? SettingsRepository();

  ThemeModePreference get themeMode => _themeMode;
  bool get notificationsEnabled => _notificationsEnabled;
  String get defaultNotificationTime => _defaultNotificationTime;
  bool get notificationSound => _notificationSound;
  bool get notificationVibration => _notificationVibration;
  AdvanceNotificationOffset get defaultAdvanceOffset => _defaultAdvanceOffset;
  bool get weekStartsMonday => _weekStartsMonday;
  String get defaultCategoryId => _defaultCategoryId;
  Priority get defaultPriority => _defaultPriority;
  String? get lastBackupAt => _lastBackupAt;

  ThemeMode get materialThemeMode {
    switch (_themeMode) {
      case ThemeModePreference.light:
        return ThemeMode.light;
      case ThemeModePreference.dark:
        return ThemeMode.dark;
      case ThemeModePreference.system:
        return ThemeMode.system;
    }
  }

  Future<void> loadSettings() async {
    _themeMode = await _repository.getThemeMode();
    _notificationsEnabled = await _repository.getNotificationsEnabled();
    _defaultNotificationTime = await _repository.getDefaultNotificationTime();
    _notificationSound = await _repository.getNotificationSound();
    _notificationVibration = await _repository.getNotificationVibration();
    _defaultAdvanceOffset = await _repository.getDefaultAdvanceOffset();
    _weekStartsMonday = await _repository.getWeekStartsMonday();
    _defaultCategoryId = await _repository.getDefaultCategoryId();
    _defaultPriority = await _repository.getDefaultPriority();
    _lastBackupAt = await _repository.getLastBackupAt();
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeModePreference mode) async {
    _themeMode = mode;
    notifyListeners();
    await _repository.setThemeMode(mode);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    notifyListeners();
    await _repository.setNotificationsEnabled(enabled);
  }

  Future<void> setDefaultNotificationTime(String timeStr) async {
    _defaultNotificationTime = timeStr;
    notifyListeners();
    await _repository.setDefaultNotificationTime(timeStr);
  }

  Future<void> setNotificationSound(bool value) async {
    _notificationSound = value;
    notifyListeners();
    await _repository.setNotificationSound(value);
  }

  Future<void> setNotificationVibration(bool value) async {
    _notificationVibration = value;
    notifyListeners();
    await _repository.setNotificationVibration(value);
  }

  Future<void> setDefaultAdvanceOffset(AdvanceNotificationOffset offset) async {
    _defaultAdvanceOffset = offset;
    notifyListeners();
    await _repository.setDefaultAdvanceOffset(offset);
  }

  Future<void> setWeekStartsMonday(bool value) async {
    _weekStartsMonday = value;
    notifyListeners();
    await _repository.setWeekStartsMonday(value);
  }

  Future<void> setDefaultCategoryId(String categoryId) async {
    _defaultCategoryId = categoryId;
    notifyListeners();
    await _repository.setDefaultCategoryId(categoryId);
  }

  Future<void> setDefaultPriority(Priority priority) async {
    _defaultPriority = priority;
    notifyListeners();
    await _repository.setDefaultPriority(priority);
  }

  Future<void> setLastBackupAt(DateTime time) async {
    _lastBackupAt = time.toIso8601String();
    notifyListeners();
    await _repository.setLastBackupAt(time);
  }
}
