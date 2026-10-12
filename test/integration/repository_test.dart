import 'package:flutter_test/flutter_test.dart';
import 'package:life_reminder/data/database/app_database.dart';
import 'package:life_reminder/data/models/category.dart';
import 'package:life_reminder/data/models/reminder.dart';
import 'package:life_reminder/data/models/reminder_enums.dart';
import 'package:life_reminder/data/repositories/category_repository.dart';
import 'package:life_reminder/data/repositories/reminder_repository.dart';
import 'package:life_reminder/data/repositories/settings_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late AppDatabase appDb;
  late ReminderRepository reminderRepo;
  late CategoryRepository categoryRepo;
  late SettingsRepository settingsRepo;

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON;');
        },
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE categories (
              id            TEXT PRIMARY KEY,
              name          TEXT NOT NULL,
              icon_key      TEXT NOT NULL,
              color_value   INTEGER NOT NULL,
              is_custom     INTEGER NOT NULL DEFAULT 0,
              sort_order    INTEGER NOT NULL DEFAULT 0,
              is_archived   INTEGER NOT NULL DEFAULT 0
            );
          ''');
          await db.execute('CREATE UNIQUE INDEX idx_categories_name ON categories(lower(name));');
          await db.execute('''
            CREATE TABLE reminders (
              id                  TEXT PRIMARY KEY,
              title               TEXT NOT NULL,
              description         TEXT,
              category_id         TEXT NOT NULL REFERENCES categories(id),
              priority            TEXT NOT NULL,
              created_at          INTEGER NOT NULL,
              start_date          INTEGER NOT NULL,
              due_date            INTEGER NOT NULL,
              due_time            INTEGER,
              is_completed        INTEGER NOT NULL DEFAULT 0,
              is_favorite         INTEGER NOT NULL DEFAULT 0,
              repeat_type         TEXT NOT NULL,
              repeat_interval     INTEGER NOT NULL DEFAULT 1,
              repeat_unit         TEXT,
              notification_enabled INTEGER NOT NULL DEFAULT 1,
              notification_time   INTEGER,
              notification_id     INTEGER NOT NULL,
              completed_at        INTEGER,
              last_completed_at   INTEGER,
              next_due_date       INTEGER NOT NULL,
              snoozed_until       INTEGER,
              is_deleted          INTEGER NOT NULL DEFAULT 0
            );
          ''');
          await db.execute('''
            CREATE TABLE completion_records (
              id                TEXT PRIMARY KEY,
              reminder_id       TEXT NOT NULL REFERENCES reminders(id) ON DELETE CASCADE,
              completed_at      INTEGER NOT NULL,
              due_date_snapshot INTEGER NOT NULL,
              was_late          INTEGER NOT NULL DEFAULT 0,
              source            TEXT NOT NULL
            );
          ''');
          await db.execute('CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL);');
          for (final cat in Category.builtInCategories) {
            await db.insert('categories', cat.toMap());
          }
        },
      ),
    );

    appDb = AppDatabase.withDatabase(db);
    reminderRepo = ReminderRepository(appDb);
    categoryRepo = CategoryRepository(appDb);
    settingsRepo = SettingsRepository(appDb);
  });

  tearDown(() async {
    await db.close();
  });

  group('CategoryRepository Integration', () {
    test('Reads built-in categories', () async {
      final categories = await categoryRepo.getAllCategories();
      expect(categories.length, equals(12));
    });

    test('Creates custom category and enforces unique case-insensitive name', () async {
      final created = await categoryRepo.createCategory(
        name: 'Pets',
        iconKey: 'pets',
        colorValue: 0xFF123456,
      );
      expect(created.name, equals('Pets'));

      expect(
        () => categoryRepo.createCategory(
          name: 'pets',
          iconKey: 'pets',
          colorValue: 0xFF654321,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('ReminderRepository Integration', () {
    test('Create and Read reminder', () async {
      final now = DateTime(2026, 10, 9, 10, 0);
      final reminder = Reminder(
        id: 'rem_1',
        title: 'Bike Service',
        categoryId: 'cat_vehicle',
        priority: Priority.high,
        createdAt: now,
        startDate: now,
        dueDate: now,
        repeatType: RepeatType.custom,
        repeatInterval: 3,
        repeatUnit: RepeatUnit.months,
        notificationId: 100,
        nextDueDate: DateTime(2027, 1, 9, 10, 0),
      );

      final created = await reminderRepo.createReminder(reminder);
      expect(created.title, equals('Bike Service'));

      final retrieved = await reminderRepo.getReminderById('rem_1');
      expect(retrieved, isNotNull);
      expect(retrieved!.priority, equals(Priority.high));
      expect(retrieved.repeatInterval, equals(3));
    });

    test('Complete recurring reminder rolls forward nextDueDate without killing reminder', () async {
      final now = DateTime(2026, 10, 9, 10, 0);
      final reminder = Reminder(
        id: 'rem_2',
        title: 'Water plants',
        categoryId: 'cat_home',
        createdAt: now,
        startDate: now,
        dueDate: now,
        repeatType: RepeatType.custom,
        repeatInterval: 2,
        repeatUnit: RepeatUnit.days,
        notificationId: 101,
        nextDueDate: now,
      );

      await reminderRepo.createReminder(reminder);

      final (updated, record) = await reminderRepo.completeReminder('rem_2', now: now);

      expect(updated.isCompleted, isFalse);
      expect(updated.lastCompletedAt, equals(now));
      expect(updated.nextDueDate, equals(DateTime(2026, 10, 11, 10, 0)));
      expect(record.reminderId, equals('rem_2'));

      final history = await reminderRepo.getCompletionRecordsForReminder('rem_2');
      expect(history.length, equals(1));
    });

    test('Snooze updates snoozedUntil only without altering nextDueDate', () async {
      final now = DateTime(2026, 10, 9, 10, 0);
      final reminder = Reminder(
        id: 'rem_3',
        title: 'Insurance',
        categoryId: 'cat_finance',
        createdAt: now,
        startDate: now,
        dueDate: now,
        repeatType: RepeatType.yearly,
        notificationId: 102,
        nextDueDate: DateTime(2027, 10, 9, 10, 0),
      );

      await reminderRepo.createReminder(reminder);

      final snoozeTime = DateTime(2026, 10, 9, 14, 0);
      final snoozed = await reminderRepo.snoozeReminder('rem_3', snoozeTime);

      expect(snoozed.snoozedUntil, equals(snoozeTime));
      expect(snoozed.nextDueDate, equals(DateTime(2026, 10, 9, 10, 0)));
    });
  });

  group('SettingsRepository Integration', () {
    test('Reads and writes settings with defaults', () async {
      expect(await settingsRepo.getThemeMode(), equals(ThemeModePreference.system));
      await settingsRepo.setThemeMode(ThemeModePreference.dark);
      expect(await settingsRepo.getThemeMode(), equals(ThemeModePreference.dark));

      expect(await settingsRepo.getDefaultNotificationTime(), equals('09:00'));
      await settingsRepo.setDefaultNotificationTime('08:30');
      expect(await settingsRepo.getDefaultNotificationTime(), equals('08:30'));
    });
  });
}
