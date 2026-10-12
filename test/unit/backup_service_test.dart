import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_reminder/core/services/backup_service.dart';

void main() {
  late BackupService backupService;

  setUp(() {
    backupService = BackupService();
  });

  group('BackupService Validation Unit Tests', () {
    test('Valid backup json returns isValid true', () async {
      final validJson = jsonEncode({
        'app': 'life_reminder',
        'schemaVersion': 1,
        'exportedAt': '2026-10-09T10:30:00.000Z',
        'counts': {'reminders': 1, 'categories': 12, 'completions': 1},
        'categories': [
          {'id': 'cat_home', 'name': 'Home', 'iconKey': 'home', 'colorValue': 4283215696, 'isCustom': false, 'sortOrder': 0, 'isArchived': false}
        ],
        'reminders': [
          {
            'id': 'rem_1',
            'title': 'Test',
            'categoryId': 'cat_home',
            'priority': 'medium',
            'createdAt': '2026-10-09T10:00:00.000Z',
            'startDate': '2026-10-09T10:00:00.000Z',
            'dueDate': '2026-10-09T10:00:00.000Z',
            'isCompleted': false,
            'isFavorite': false,
            'repeatType': 'none',
            'repeatInterval': 1,
            'repeatUnit': 'days',
            'notificationEnabled': true,
            'notificationId': 1,
            'nextDueDate': '2026-10-09T10:00:00.000Z',
            'isDeleted': false
          }
        ],
        'completionRecords': []
      });

      final result = await backupService.validateBackupContent(validJson);
      expect(result.isValid, isTrue);
      expect(result.reminderCount, equals(1));
    });

    test('Invalid JSON returns isValid false', () async {
      final result = await backupService.validateBackupContent('not a json');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('That file didn\'t work'));
    });

    test('Wrong app field rejects backup', () async {
      final invalidJson = jsonEncode({'app': 'other_app', 'schemaVersion': 1, 'categories': [], 'reminders': [], 'completionRecords': []});
      final result = await backupService.validateBackupContent(invalidJson);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('This isn\'t a Life Reminder backup'));
    });

    test('Future schema version rejects backup', () async {
      final invalidJson = jsonEncode({'app': 'life_reminder', 'schemaVersion': 99, 'categories': [], 'reminders': [], 'completionRecords': []});
      final result = await backupService.validateBackupContent(invalidJson);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('newer version'));
    });

    test('Missing categories array rejects backup', () async {
      final invalidJson = jsonEncode({'app': 'life_reminder', 'schemaVersion': 1, 'reminders': [], 'completionRecords': []});
      final result = await backupService.validateBackupContent(invalidJson);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Missing required sections'));
    });

    test('v2 backup with subscriptions counts subscriptions', () async {
      final validJson = jsonEncode({
        'app': 'life_reminder',
        'schemaVersion': 2,
        'exportedAt': '2026-10-09T10:30:00.000Z',
        'counts': {'reminders': 0, 'categories': 1, 'completions': 0, 'subscriptions': 2},
        'categories': [
          {'id': 'cat_other', 'name': 'Other', 'iconKey': 'other', 'colorValue': 4283215696, 'isCustom': false, 'sortOrder': 11, 'isArchived': false}
        ],
        'reminders': [],
        'completionRecords': [],
        'subscriptions': [
          {
            'id': 'sub_1',
            'name': 'Netflix',
            'notes': null,
            'price': 15.99,
            'currency': 'USD',
            'billingCycle': 'monthly',
            'nextRenewalDate': '2026-11-01T00:00:00.000',
            'status': 'active',
            'reminderEnabled': true,
            'reminderLead': '1d',
            'createdAt': '2026-10-09T10:00:00.000',
            'notificationId': 1
          },
          {
            'id': 'sub_2',
            'name': 'Gym',
            'notes': null,
            'price': 50,
            'currency': 'USD',
            'billingCycle': 'monthly',
            'nextRenewalDate': '2026-11-05T00:00:00.000',
            'status': 'paused',
            'reminderEnabled': false,
            'reminderLead': '3d',
            'createdAt': '2026-10-09T10:00:00.000',
            'notificationId': 2
          }
        ]
      });

      final result = await backupService.validateBackupContent(validJson);
      expect(result.isValid, isTrue);
      expect(result.subscriptionCount, equals(2));
    });

    test('v1 backup without subscriptions still validates with zero subscriptions', () async {
      final validJson = jsonEncode({
        'app': 'life_reminder',
        'schemaVersion': 1,
        'exportedAt': '2026-10-09T10:30:00.000Z',
        'counts': {'reminders': 0, 'categories': 1, 'completions': 0},
        'categories': [
          {'id': 'cat_other', 'name': 'Other', 'iconKey': 'other', 'colorValue': 4283215696, 'isCustom': false, 'sortOrder': 11, 'isArchived': false}
        ],
        'reminders': [],
        'completionRecords': []
      });

      final result = await backupService.validateBackupContent(validJson);
      expect(result.isValid, isTrue);
      expect(result.subscriptionCount, equals(0));
    });

    test('Future schema version (v3) rejects backup', () async {
      final invalidJson = jsonEncode({'app': 'life_reminder', 'schemaVersion': 3, 'categories': [], 'reminders': [], 'completionRecords': []});
      final result = await backupService.validateBackupContent(invalidJson);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('newer version'));
    });
  });
}
