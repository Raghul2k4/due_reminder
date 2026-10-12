import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../models/category.dart';

class CategoryRepository {
  final AppDatabase _dbProvider;
  final Uuid _uuid = const Uuid();

  CategoryRepository([AppDatabase? dbProvider]) : _dbProvider = dbProvider ?? AppDatabase();

  Future<List<Category>> getAllCategories({bool includeArchived = false}) async {
    final db = await _dbProvider.database;
    final where = includeArchived ? null : 'is_archived = 0';
    final result = await db.query(
      'categories',
      where: where,
      orderBy: 'sort_order ASC, name ASC',
    );
    return result.map((m) => Category.fromMap(m)).toList();
  }

  Future<Category?> getCategoryById(String id) async {
    final db = await _dbProvider.database;
    final result = await db.query('categories', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Category.fromMap(result.first);
  }

  Future<bool> categoryNameExists(String name, {String? excludeId}) async {
    final db = await _dbProvider.database;
    String where = 'lower(name) = ?';
    List<dynamic> args = [name.toLowerCase().trim()];
    if (excludeId != null) {
      where += ' AND id != ?';
      args.add(excludeId);
    }
    final result = await db.query('categories', where: where, whereArgs: args);
    return result.isNotEmpty;
  }

  Future<Category> createCategory({
    required String name,
    required String iconKey,
    required int colorValue,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Category name cannot be empty');
    }
    if (await categoryNameExists(trimmed)) {
      throw Exception('You already have a category with that name');
    }

    final db = await _dbProvider.database;
    final countResult = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM categories')) ?? 0;

    final category = Category(
      id: _uuid.v4(),
      name: trimmed,
      iconKey: iconKey,
      colorValue: colorValue,
      isCustom: true,
      sortOrder: countResult,
      isArchived: false,
    );

    await db.insert('categories', category.toMap());
    return category;
  }

  Future<Category> updateCategory(Category category) async {
    final trimmed = category.name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Category name cannot be empty');
    }
    if (await categoryNameExists(trimmed, excludeId: category.id)) {
      throw Exception('You already have a category with that name');
    }

    final db = await _dbProvider.database;
    final updated = category.copyWith(name: trimmed);
    await db.update(
      'categories',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
    return updated;
  }

  Future<void> archiveCategory(String id) async {
    final db = await _dbProvider.database;
    await db.update(
      'categories',
      {'is_archived': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deletes custom category. If [reassignToOther] is true, moves existing reminders to 'cat_other'.
  Future<void> deleteCategory(String id, {bool reassignToOther = true}) async {
    final category = await getCategoryById(id);
    if (category == null) return;
    if (!category.isCustom) {
      throw Exception('Built-in categories cannot be deleted');
    }

    final db = await _dbProvider.database;
    final reminderCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM reminders WHERE category_id = ? AND is_deleted = 0', [id]),
    ) ?? 0;

    if (reminderCount > 0 && !reassignToOther) {
      throw Exception('Cannot delete category with active reminders without reassignment');
    }

    await db.transaction((txn) async {
      if (reminderCount > 0) {
        await txn.update(
          'reminders',
          {'category_id': 'cat_other'},
          where: 'category_id = ?',
          whereArgs: [id],
        );
      }
      await txn.delete('categories', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<Map<String, int>> getCategoryReminderCounts() async {
    final db = await _dbProvider.database;
    final result = await db.rawQuery('''
      SELECT category_id, COUNT(*) as count 
      FROM reminders 
      WHERE is_deleted = 0 
      GROUP BY category_id
    ''');

    final map = <String, int>{};
    for (final row in result) {
      map[row['category_id'] as String] = row['count'] as int;
    }
    return map;
  }
}
