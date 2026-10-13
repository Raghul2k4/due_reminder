import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/recurrence.dart';
import '../database/app_database.dart';
import '../models/completion_record.dart';
import '../models/reminder.dart';
import '../models/reminder_enums.dart';

enum ReminderFilter {
  all,
  today,
  upcoming,
  overdue,
  completed,
  favorites,
}

enum ReminderSort {
  dueDate,
  priority,
  recentlyCreated,
  recentlyCompleted,
}

class ReminderRepository {
  final AppDatabase _dbProvider;
  final Uuid _uuid = const Uuid();

  ReminderRepository([AppDatabase? dbProvider]) : _dbProvider = dbProvider ?? AppDatabase();

  Future<Reminder> createReminder(Reminder reminder) async {
    final db = await _dbProvider.database;
    final trimmedTitle = reminder.title.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError('Reminder title cannot be empty');
    }

    final id = reminder.id.isEmpty ? _uuid.v4() : reminder.id;
    final notificationId = reminder.notificationId != 0
        ? reminder.notificationId
        : (id.hashCode & 0x7FFFFFFF);

    final nextDue = reminder.isRecurring
        ? computeNextDueDate(
            anchor: reminder.dueDate,
            from: reminder.startDate.isBefore(reminder.dueDate)
                ? reminder.startDate.add(const Duration(seconds: -1))
                : reminder.dueDate.add(const Duration(seconds: -1)),
            type: reminder.repeatType,
            interval: reminder.repeatInterval,
            unit: reminder.repeatUnit,
          )
        : reminder.dueDate;

    final created = reminder.copyWith(
      id: id,
      title: trimmedTitle,
      notificationId: notificationId,
      nextDueDate: nextDue,
    );

    await db.insert('reminders', created.toMap());
    return created;
  }

  Future<Reminder?> getReminderById(String id) async {
    final db = await _dbProvider.database;
    final result = await db.query('reminders', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Reminder.fromMap(result.first);
  }

  Future<Reminder> updateReminder(Reminder reminder) async {
    final trimmedTitle = reminder.title.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError('Reminder title cannot be empty');
    }

    final db = await _dbProvider.database;
    final updated = reminder.copyWith(title: trimmedTitle);

    await db.update(
      'reminders',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
    return updated;
  }

  /// Atomic completion flow (§9.4)
  Future<(Reminder, CompletionRecord)> completeReminder(
    String id, {
    required DateTime now,
    String source = 'app',
  }) async {
    final db = await _dbProvider.database;
    final reminder = await getReminderById(id);
    if (reminder == null) {
      throw Exception('Reminder with id $id not found');
    }

    final recordId = _uuid.v4();
    final effectiveDue = reminder.effectiveDueDate;
    final wasLate = now.isAfter(effectiveDue);

    final record = CompletionRecord(
      id: recordId,
      reminderId: reminder.id,
      completedAt: now,
      dueDateSnapshot: effectiveDue,
      wasLate: wasLate,
      source: source,
    );

    Reminder updated;
    if (!reminder.isRecurring) {
      updated = reminder.copyWith(
        isCompleted: true,
        completedAt: now,
        lastCompletedAt: now,
        clearSnoozedUntil: true,
      );
    } else {
      final nextDue = computeNextDueDate(
        anchor: reminder.dueDate,
        from: effectiveDue,
        type: reminder.repeatType,
        interval: reminder.repeatInterval,
        unit: reminder.repeatUnit,
      );

      updated = reminder.copyWith(
        isCompleted: false,
        lastCompletedAt: now,
        nextDueDate: nextDue,
        clearSnoozedUntil: true,
      );
    }

    await db.transaction((txn) async {
      await txn.insert('completion_records', record.toMap());
      await txn.update(
        'reminders',
        updated.toMap(),
        where: 'id = ?',
        whereArgs: [reminder.id],
      );
    });

    return (updated, record);
  }

  /// Undo completion flow
  Future<void> undoCompletion(
    String reminderId,
    String completionRecordId,
    Reminder previousState,
  ) async {
    final db = await _dbProvider.database;
    await db.transaction((txn) async {
      await txn.delete(
        'completion_records',
        where: 'id = ?',
        whereArgs: [completionRecordId],
      );
      await txn.update(
        'reminders',
        previousState.toMap(),
        where: 'id = ?',
        whereArgs: [reminderId],
      );
    });
  }

  /// Snooze reminder (§9.5)
  Future<Reminder> snoozeReminder(String id, DateTime snoozedUntil) async {
    final db = await _dbProvider.database;
    final reminder = await getReminderById(id);
    if (reminder == null) {
      throw Exception('Reminder with id $id not found');
    }

    final updated = reminder.copyWith(snoozedUntil: snoozedUntil);
    await db.update(
      'reminders',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
    return updated;
  }

  Future<Reminder> clearSnooze(String id) async {
    final db = await _dbProvider.database;
    final reminder = await getReminderById(id);
    if (reminder == null) {
      throw Exception('Reminder with id $id not found');
    }

    final updated = reminder.copyWith(clearSnoozedUntil: true);
    await db.update(
      'reminders',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
    return updated;
  }

  Future<Reminder> toggleFavorite(String id) async {
    final db = await _dbProvider.database;
    final reminder = await getReminderById(id);
    if (reminder == null) {
      throw Exception('Reminder with id $id not found');
    }

    final updated = reminder.copyWith(isFavorite: !reminder.isFavorite);
    await db.update(
      'reminders',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
    return updated;
  }

  Future<void> deleteReminder(String id) async {
    final db = await _dbProvider.database;
    await db.update(
      'reminders',
      {'is_deleted': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> restoreReminder(String id) async {
    final db = await _dbProvider.database;
    await db.update(
      'reminders',
      {'is_deleted': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> clearCompletedReminders() async {
    final db = await _dbProvider.database;
    return await db.delete(
      'reminders',
      where: 'is_completed = 1 AND repeat_type = ? AND is_deleted = 0',
      whereArgs: ['none'],
    );
  }

  Future<void> deleteAllData() async {
    final db = await _dbProvider.database;
    await db.transaction((txn) async {
      await txn.delete('completion_records');
      await txn.delete('reminders');
      await txn.delete('subscriptions');
      await txn.delete('categories', where: 'is_custom = 1');
      await txn.delete('settings');
    });
  }

  /// Catch-up on launch and boot (§9.6)
  Future<int> catchUpOverdueReminders({required DateTime now}) async {
    final db = await _dbProvider.database;
    final result = await db.query(
      'reminders',
      where: 'is_deleted = 0 AND repeat_type != ? AND is_completed = 0',
      whereArgs: ['none'],
    );

    int count = 0;
    for (final map in result) {
      final r = Reminder.fromMap(map);
      if (r.effectiveDueDate.isBefore(now)) {
        final newNextDue = computeNextDueDate(
          anchor: r.dueDate,
          from: now,
          type: r.repeatType,
          interval: r.repeatInterval,
          unit: r.repeatUnit,
        );
        if (newNextDue != r.nextDueDate) {
          final updated = r.copyWith(nextDueDate: newNextDue);
          await db.update('reminders', updated.toMap(), where: 'id = ?', whereArgs: [r.id]);
          count++;
        }
      }
    }
    return count;
  }

  Future<List<CompletionRecord>> getCompletionRecordsForReminder(String reminderId) async {
    final db = await _dbProvider.database;
    final result = await db.query(
      'completion_records',
      where: 'reminder_id = ?',
      whereArgs: [reminderId],
      orderBy: 'completed_at DESC',
    );
    return result.map((m) => CompletionRecord.fromMap(m)).toList();
  }

  /// Search, filter, and sort reminders
  Future<List<Reminder>> getReminders({
    String? searchQuery,
    ReminderFilter filter = ReminderFilter.all,
    String? categoryId,
    Priority? priority,
    ReminderSort sort = ReminderSort.dueDate,
    required DateTime now,
  }) async {
    final db = await _dbProvider.database;

    final todayStart = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999).millisecondsSinceEpoch;
    final nowMs = now.millisecondsSinceEpoch;

    List<String> whereClauses = ['r.is_deleted = 0'];
    List<dynamic> whereArgs = [];

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final term = '%${searchQuery.trim().toLowerCase()}%';
      whereClauses.add('(lower(r.title) LIKE ? OR lower(r.description) LIKE ? OR lower(c.name) LIKE ?)');
      whereArgs.addAll([term, term, term]);
    }

    if (categoryId != null && categoryId.isNotEmpty) {
      whereClauses.add('r.category_id = ?');
      whereArgs.add(categoryId);
    }

    if (priority != null) {
      whereClauses.add('r.priority = ?');
      whereArgs.add(priority.toName());
    }

    switch (filter) {
      case ReminderFilter.all:
        whereClauses.add('r.is_completed = 0');
        break;
      case ReminderFilter.today:
        whereClauses.add('r.is_completed = 0 AND (COALESCE(r.snoozed_until, r.next_due_date) BETWEEN ? AND ?)');
        whereArgs.addAll([todayStart, todayEnd]);
        break;
      case ReminderFilter.upcoming:
        whereClauses.add('r.is_completed = 0 AND COALESCE(r.snoozed_until, r.next_due_date) > ?');
        whereArgs.add(todayEnd);
        break;
      case ReminderFilter.overdue:
        whereClauses.add('r.is_completed = 0 AND COALESCE(r.snoozed_until, r.next_due_date) < ?');
        whereArgs.add(nowMs);
        break;
      case ReminderFilter.completed:
        whereClauses.add('(r.is_completed = 1 OR r.last_completed_at IS NOT NULL)');
        break;
      case ReminderFilter.favorites:
        whereClauses.add('r.is_completed = 0 AND r.is_favorite = 1');
        break;
    }

    String orderBy;
    switch (sort) {
      case ReminderSort.dueDate:
        orderBy = 'COALESCE(r.snoozed_until, r.next_due_date) ASC';
        break;
      case ReminderSort.priority:
        orderBy = "CASE r.priority WHEN 'high' THEN 1 WHEN 'medium' THEN 2 WHEN 'low' THEN 3 END, COALESCE(r.snoozed_until, r.next_due_date) ASC";
        break;
      case ReminderSort.recentlyCreated:
        orderBy = 'r.created_at DESC';
        break;
      case ReminderSort.recentlyCompleted:
        orderBy = 'r.last_completed_at DESC NULLS LAST, r.completed_at DESC NULLS LAST';
        break;
    }

    final sql = '''
      SELECT r.* 
      FROM reminders r
      JOIN categories c ON r.category_id = c.id
      WHERE ${whereClauses.join(' AND ')}
      ORDER BY $orderBy
    ''';

    final result = await db.rawQuery(sql, whereArgs);
    return result.map((m) => Reminder.fromMap(m)).toList();
  }

  Future<List<Reminder>> getTrash() async {
    final db = await _dbProvider.database;
    final result = await db.query(
      'reminders',
      where: 'is_deleted = 1',
      orderBy: 'next_due_date DESC',
      limit: 100,
    );
    return result.map((m) => Reminder.fromMap(m)).toList();
  }

  /// Counts for Home screen tabs
  Future<({int overdue, int today, int upcoming, int total})> getCounts({required DateTime now}) async {
    final db = await _dbProvider.database;
    final todayStart = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999).millisecondsSinceEpoch;
    final nowMs = now.millisecondsSinceEpoch;

    final overdueRes = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM reminders WHERE is_deleted = 0 AND is_completed = 0 AND COALESCE(snoozed_until, next_due_date) < ?',
      [nowMs],
    )) ?? 0;

    final todayRes = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM reminders WHERE is_deleted = 0 AND is_completed = 0 AND (COALESCE(snoozed_until, next_due_date) BETWEEN ? AND ?)',
      [todayStart, todayEnd],
    )) ?? 0;

    final upcomingRes = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM reminders WHERE is_deleted = 0 AND is_completed = 0 AND COALESCE(snoozed_until, next_due_date) > ?',
      [todayEnd],
    )) ?? 0;

    final totalRes = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM reminders WHERE is_deleted = 0 AND is_completed = 0',
    )) ?? 0;

    return (overdue: overdueRes, today: todayRes, upcoming: upcomingRes, total: totalRes);
  }
}
