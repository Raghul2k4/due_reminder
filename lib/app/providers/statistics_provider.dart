import 'package:flutter/material.dart';
import '../../data/database/app_database.dart';
import '../../data/models/category.dart';

enum StatsTimeRange {
  thisMonth,
  thisYear,
  allTime,
}

class StatisticsData {
  final int completedThisMonth;
  final int overdueCount;
  final int upcomingCount;
  final double completionRate;
  final int currentStreak;
  final Category? mostUsedCategory;
  final Map<String, int> categoryCounts;
  final List<({DateTime date, int count})> weeklyCompletionHistory;

  const StatisticsData({
    required this.completedThisMonth,
    required this.overdueCount,
    required this.upcomingCount,
    required this.completionRate,
    required this.currentStreak,
    this.mostUsedCategory,
    required this.categoryCounts,
    required this.weeklyCompletionHistory,
  });
}

class StatisticsProvider extends ChangeNotifier {
  final AppDatabase _dbProvider;

  StatisticsData? _data;
  StatsTimeRange _timeRange = StatsTimeRange.thisMonth;
  bool _isLoading = false;

  StatisticsProvider([AppDatabase? dbProvider]) : _dbProvider = dbProvider ?? AppDatabase();

  StatisticsData? get data => _data;
  StatsTimeRange get timeRange => _timeRange;
  bool get isLoading => _isLoading;

  void setTimeRange(StatsTimeRange range, {DateTime? now}) {
    _timeRange = range;
    loadStatistics(now: now);
  }

  Future<void> loadStatistics({DateTime? now}) async {
    _isLoading = true;
    notifyListeners();

    final currentNow = now ?? DateTime.now();
    final db = await _dbProvider.database;

    // 1. Completed this month
    final startOfMonth = DateTime(currentNow.year, currentNow.month, 1).millisecondsSinceEpoch;
    final endOfMonth = DateTime(currentNow.year, currentNow.month + 1, 0, 23, 59, 59).millisecondsSinceEpoch;

    final completedThisMonthRes = await db.rawQuery('''
      SELECT COUNT(*) as count FROM completion_records
      WHERE completed_at BETWEEN ? AND ?
    ''', [startOfMonth, endOfMonth]);
    final completedThisMonth = (completedThisMonthRes.first['count'] as int?) ?? 0;

    // 2. Overdue & Upcoming
    final nowMs = currentNow.millisecondsSinceEpoch;
    final todayEndMs = DateTime(currentNow.year, currentNow.month, currentNow.day, 23, 59, 59).millisecondsSinceEpoch;

    final overdueRes = await db.rawQuery('''
      SELECT COUNT(*) as count FROM reminders
      WHERE is_deleted = 0 AND is_completed = 0 AND COALESCE(snoozed_until, next_due_date) < ?
    ''', [nowMs]);
    final overdueCount = (overdueRes.first['count'] as int?) ?? 0;

    final upcomingRes = await db.rawQuery('''
      SELECT COUNT(*) as count FROM reminders
      WHERE is_deleted = 0 AND is_completed = 0 AND COALESCE(snoozed_until, next_due_date) > ?
    ''', [todayEndMs]);
    final upcomingCount = (upcomingRes.first['count'] as int?) ?? 0;

    // 3. Completion Rate
    int timeFilterStart = 0;
    if (_timeRange == StatsTimeRange.thisMonth) {
      timeFilterStart = startOfMonth;
    } else if (_timeRange == StatsTimeRange.thisYear) {
      timeFilterStart = DateTime(currentNow.year, 1, 1).millisecondsSinceEpoch;
    }

    final totalCompletedRes = await db.rawQuery('''
      SELECT COUNT(*) as count FROM completion_records
      WHERE completed_at >= ?
    ''', [timeFilterStart]);
    final totalCompleted = (totalCompletedRes.first['count'] as int?) ?? 0;

    final totalDueRes = await db.rawQuery('''
      SELECT COUNT(*) as count FROM reminders
      WHERE is_deleted = 0 AND created_at >= ?
    ''', [timeFilterStart]);
    final totalDue = (totalDueRes.first['count'] as int?) ?? 0;

    final completionRate = (totalCompleted + totalDue) > 0
        ? (totalCompleted / (totalCompleted + overdueCount)).clamp(0.0, 1.0) * 100
        : 100.0;

    // 4. Streak Calculation
    final completionsDistinctDays = await db.rawQuery('''
      SELECT DISTINCT DATE(completed_at / 1000, 'unixepoch', 'localtime') as comp_date
      FROM completion_records
      ORDER BY comp_date DESC
    ''');

    int streak = 0;
    if (completionsDistinctDays.isNotEmpty) {
      final todayStr = '${currentNow.year}-${currentNow.month.toString().padLeft(2, '0')}-${currentNow.day.toString().padLeft(2, '0')}';
      final yesterday = currentNow.subtract(const Duration(days: 1));
      final yesterdayStr = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

      String checkStr = todayStr;
      final datesSet = completionsDistinctDays.map((r) => r['comp_date'] as String).toSet();

      if (!datesSet.contains(todayStr) && datesSet.contains(yesterdayStr)) {
        checkStr = yesterdayStr;
      }

      DateTime checkDate = checkStr == todayStr ? currentNow : yesterday;
      while (true) {
        final dateFormatted = '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
        if (datesSet.contains(dateFormatted)) {
          streak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
    }

    // 5. Category Counts & Most Used Category
    final categoryRes = await db.rawQuery('''
      SELECT r.category_id, COUNT(*) as count 
      FROM completion_records cr
      JOIN reminders r ON cr.reminder_id = r.id
      WHERE cr.completed_at >= ?
      GROUP BY r.category_id
      ORDER BY count DESC
    ''', [timeFilterStart]);

    final Map<String, int> catCounts = {};
    Category? mostUsed;
    for (final row in categoryRes) {
      final catId = row['category_id'] as String;
      final count = row['count'] as int;
      catCounts[catId] = count;
    }

    if (categoryRes.isNotEmpty) {
      final topCatId = categoryRes.first['category_id'] as String;
      final catQuery = await db.query('categories', where: 'id = ?', whereArgs: [topCatId]);
      if (catQuery.isNotEmpty) {
        mostUsed = Category.fromMap(catQuery.first);
      }
    }

    // 6. 12-Week Completion Bar Chart Data
    final List<({DateTime date, int count})> weeklyHistory = [];
    for (int i = 11; i >= 0; i--) {
      final weekStart = currentNow.subtract(Duration(days: i * 7 + (currentNow.weekday - 1)));
      final weekStartDt = DateTime(weekStart.year, weekStart.month, weekStart.day);
      final weekEndDt = weekStartDt.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

      final weekRes = await db.rawQuery('''
        SELECT COUNT(*) as count FROM completion_records
        WHERE completed_at BETWEEN ? AND ?
      ''', [weekStartDt.millisecondsSinceEpoch, weekEndDt.millisecondsSinceEpoch]);

      final count = (weekRes.first['count'] as int?) ?? 0;
      weeklyHistory.add((date: weekStartDt, count: count));
    }

    _data = StatisticsData(
      completedThisMonth: completedThisMonth,
      overdueCount: overdueCount,
      upcomingCount: upcomingCount,
      completionRate: completionRate,
      currentStreak: streak,
      mostUsedCategory: mostUsed,
      categoryCounts: catCounts,
      weeklyCompletionHistory: weeklyHistory,
    );

    _isLoading = false;
    notifyListeners();
  }
}
