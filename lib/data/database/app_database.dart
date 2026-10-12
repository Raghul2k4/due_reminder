import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/category.dart';

class AppDatabase {
  static const String _dbName = 'life_reminder.db';
  static const int _dbVersion = 1;

  static AppDatabase? _instance;
  Database? _db;

  AppDatabase._internal();

  factory AppDatabase() {
    _instance ??= AppDatabase._internal();
    return _instance!;
  }

  /// For unit testing with mock or in-memory DB (e.g. sqflite_common_ffi)
  static AppDatabase withDatabase(Database db) {
    final instance = AppDatabase._internal();
    instance._db = db;
    return instance;
  }

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = p.join(documentsDirectory.path, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
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

    await db.execute('''
      CREATE UNIQUE INDEX idx_categories_name ON categories(lower(name));
    ''');

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
      CREATE INDEX idx_reminders_next_due ON reminders(next_due_date);
    ''');
    await db.execute('''
      CREATE INDEX idx_reminders_category ON reminders(category_id);
    ''');
    await db.execute('''
      CREATE INDEX idx_reminders_deleted ON reminders(is_deleted);
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

    await db.execute('''
      CREATE INDEX idx_completions_reminder ON completion_records(reminder_id);
    ''');
    await db.execute('''
      CREATE INDEX idx_completions_date ON completion_records(completed_at);
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      );
    ''');

    // Seed built-in categories
    final batch = db.batch();
    for (final cat in Category.builtInCategories) {
      batch.insert('categories', cat.toMap());
    }
    await batch.commit();
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migration logic for future versions
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }
}
