import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

import '../../data/database/app_database.dart';
import '../../data/models/category.dart';
import '../../data/models/completion_record.dart';
import '../../data/models/reminder.dart';
import '../../data/models/subscription.dart';

enum ImportStrategy { merge, replace }

class BackupValidationResult {
  final bool isValid;
  final String? errorMessage;
  final int reminderCount;
  final int categoryCount;
  final int completionCount;
  final int subscriptionCount;
  final Map<String, dynamic>? parsedJson;

  const BackupValidationResult({
    required this.isValid,
    this.errorMessage,
    this.reminderCount = 0,
    this.categoryCount = 0,
    this.completionCount = 0,
    this.subscriptionCount = 0,
    this.parsedJson,
  });
}

class BackupService {
  final AppDatabase _dbProvider;

  BackupService([AppDatabase? dbProvider])
    : _dbProvider = dbProvider ?? AppDatabase();

  Future<BackupValidationResult> validateBackupContent(
    String jsonString,
  ) async {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        return const BackupValidationResult(
          isValid: false,
          errorMessage:
              'That file didn\'t work. Root element is not a JSON object.',
        );
      }

      if (decoded['app'] != 'life_reminder') {
        return const BackupValidationResult(
          isValid: false,
          errorMessage: 'This isn\'t a Life Reminder backup.',
        );
      }

      final schemaVersion = decoded['schemaVersion'] as int?;
      if (schemaVersion == null || schemaVersion > 2) {
        return const BackupValidationResult(
          isValid: false,
          errorMessage: 'This backup is from a newer version of Life Reminder.',
        );
      }

      final categoriesJson = decoded['categories'] as List?;
      final remindersJson = decoded['reminders'] as List?;
      final completionRecordsJson = decoded['completionRecords'] as List?;

      if (categoriesJson == null ||
          remindersJson == null ||
          completionRecordsJson == null) {
        return const BackupValidationResult(
          isValid: false,
          errorMessage: 'Missing required sections in backup file.',
        );
      }

      // Subscriptions were introduced in schema v2; older backups omit them.
      final subscriptionsJson = (decoded['subscriptions'] as List?) ?? const [];

      return BackupValidationResult(
        isValid: true,
        reminderCount: remindersJson.length,
        categoryCount: categoriesJson.length,
        completionCount: completionRecordsJson.length,
        subscriptionCount: subscriptionsJson.length,
        parsedJson: decoded,
      );
    } catch (e) {
      return BackupValidationResult(
        isValid: false,
        errorMessage: 'That file didn\'t work. ${e.toString()}',
      );
    }
  }

  Future<String> exportBackup() async {
    final db = await _dbProvider.database;

    final categoriesRaw = await db.query('categories');
    final remindersRaw = await db.query('reminders');
    final completionsRaw = await db.query('completion_records');
    final subscriptionsRaw = await db.query('subscriptions');

    final categories = categoriesRaw
        .map((m) => Category.fromMap(m).toJson())
        .toList();
    final reminders = remindersRaw
        .map((m) => Reminder.fromMap(m).toJson())
        .toList();
    final completions = completionsRaw
        .map((m) => CompletionRecord.fromMap(m).toJson())
        .toList();
    final subscriptions = subscriptionsRaw
        .map((m) => Subscription.fromMap(m).toJson())
        .toList();

    final now = DateTime.now();
    final exportedAtStr = now.toUtc().toIso8601String();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final backupData = {
      'app': 'life_reminder',
      'schemaVersion': 2,
      'exportedAt': exportedAtStr,
      'counts': {
        'reminders': reminders.length,
        'categories': categories.length,
        'completions': completions.length,
        'subscriptions': subscriptions.length,
      },
      'categories': categories,
      'reminders': reminders,
      'completionRecords': completions,
      'subscriptions': subscriptions,
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

    final tempDir = await getTemporaryDirectory();
    final fileName = 'life_reminder_backup_$dateStr.json';
    final filePath = p.join(tempDir.path, fileName);
    final file = File(filePath);
    await file.writeAsString(jsonString);

    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          subject: 'Life Reminder Backup ($dateStr)',
        ),
      );
    } catch (_) {
      final docDir = await getApplicationDocumentsDirectory();
      final docPath = p.join(docDir.path, fileName);
      await File(docPath).writeAsString(jsonString);
      return docPath;
    }

    return filePath;
  }

  Future<void> importBackup(
    Map<String, dynamic> backupData, {
    required ImportStrategy strategy,
  }) async {
    final db = await _dbProvider.database;

    final categoriesJson = (backupData['categories'] as List)
        .cast<Map<String, dynamic>>();
    final remindersJson = (backupData['reminders'] as List)
        .cast<Map<String, dynamic>>();
    final completionsJson = (backupData['completionRecords'] as List)
        .cast<Map<String, dynamic>>();
    // Optional for v1 backups.
    final subscriptionsJson =
        ((backupData['subscriptions'] as List?) ?? const [])
            .cast<Map<String, dynamic>>();

    await db.transaction((txn) async {
      if (strategy == ImportStrategy.replace) {
        await txn.delete('completion_records');
        await txn.delete('reminders');
        await txn.delete('subscriptions');
        await txn.delete('categories', where: 'is_custom = 1');
      }

      final existingCategories = await txn.query('categories');
      final existingCatNamesMap = <String, String>{};
      for (final c in existingCategories) {
        existingCatNamesMap[(c['name'] as String).toLowerCase()] =
            c['id'] as String;
      }

      // Process imported categories
      for (final catMap in categoriesJson) {
        final cat = Category.fromJson(catMap);
        final lowerName = cat.name.trim().toLowerCase();

        if (existingCatNamesMap.containsKey(lowerName)) {
          // Category already exists
          continue;
        }

        await txn.insert(
          'categories',
          cat.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
        existingCatNamesMap[lowerName] = cat.id;
      }

      // Process imported reminders
      for (final remMap in remindersJson) {
        try {
          final rem = Reminder.fromJson(remMap);

          // Check if category exists
          final catRes = await txn.query(
            'categories',
            where: 'id = ?',
            whereArgs: [rem.categoryId],
          );
          String catId = rem.categoryId;
          if (catRes.isEmpty) {
            catId = 'cat_other'; // fallback to Other
          }

          final finalRem = rem.copyWith(categoryId: catId);
          await txn.insert(
            'reminders',
            finalRem.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        } catch (_) {
          // Skip invalid record per §12.2
        }
      }

      // Process imported completion records
      for (final compMap in completionsJson) {
        try {
          final comp = CompletionRecord.fromJson(compMap);
          // Check if parent reminder exists
          final remRes = await txn.query(
            'reminders',
            where: 'id = ?',
            whereArgs: [comp.reminderId],
          );
          if (remRes.isNotEmpty) {
            await txn.insert(
              'completion_records',
              comp.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        } catch (_) {
          // Skip invalid record
        }
      }

      // Process imported subscriptions
      for (final subMap in subscriptionsJson) {
        try {
          final sub = Subscription.fromJson(subMap);
          await txn.insert(
            'subscriptions',
            sub.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        } catch (_) {
          // Skip invalid record
        }
      }
    });
  }
}
