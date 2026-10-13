import 'package:flutter/material.dart';
import '../../core/services/notification_service.dart';
import '../../data/models/completion_record.dart';
import '../../data/models/reminder.dart';
import '../../data/models/reminder_enums.dart';
import '../../data/repositories/reminder_repository.dart';

class ReminderProvider extends ChangeNotifier {
  final ReminderRepository _repository;
  final NotificationService _notificationService;

  List<Reminder> _reminders = [];
  int _overdueCount = 0;
  int _todayCount = 0;
  int _upcomingCount = 0;
  int _totalCount = 0;

  String _searchQuery = '';
  ReminderFilter _activeFilter = ReminderFilter.all;
  String? _selectedCategoryId;
  Priority? _selectedPriority;
  ReminderSort _activeSort = ReminderSort.dueDate;

  bool _isLoading = false;
  String? _errorMessage;

  ReminderProvider({
    ReminderRepository? repository,
    NotificationService? notificationService,
  })  : _repository = repository ?? ReminderRepository(),
        _notificationService = notificationService ?? NotificationService();

  List<Reminder> get reminders => List.unmodifiable(_reminders);
  int get overdueCount => _overdueCount;
  int get todayCount => _todayCount;
  int get upcomingCount => _upcomingCount;
  int get totalCount => _totalCount;

  String get searchQuery => _searchQuery;
  ReminderFilter get activeFilter => _activeFilter;
  String? get selectedCategoryId => _selectedCategoryId;
  Priority? get selectedPriority => _selectedPriority;
  ReminderSort get activeSort => _activeSort;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadReminders({DateTime? now}) async {
    final currentNow = now ?? DateTime.now();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final counts = await _repository.getCounts(now: currentNow);
      _overdueCount = counts.overdue;
      _todayCount = counts.today;
      _upcomingCount = counts.upcoming;
      _totalCount = counts.total;

      _reminders = await _repository.getReminders(
        searchQuery: _searchQuery,
        filter: _activeFilter,
        categoryId: _selectedCategoryId,
        priority: _selectedPriority,
        sort: _activeSort,
        now: currentNow,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadReminders();
  }

  void setFilter(ReminderFilter filter) {
    _activeFilter = filter;
    loadReminders();
  }

  void setCategory(String? categoryId) {
    _selectedCategoryId = categoryId;
    loadReminders();
  }

  void setPriority(Priority? priority) {
    _selectedPriority = priority;
    loadReminders();
  }

  void setSort(ReminderSort sort) {
    _activeSort = sort;
    loadReminders();
  }

  void clearFilters() {
    _searchQuery = '';
    _activeFilter = ReminderFilter.all;
    _selectedCategoryId = null;
    _selectedPriority = null;
    _activeSort = ReminderSort.dueDate;
    loadReminders();
  }

  Future<Reminder> createReminder(Reminder reminder, {String categoryName = ''}) async {
    try {
      final created = await _repository.createReminder(reminder);
      await _notificationService.scheduleReminderNotification(created, categoryName: categoryName);
      await loadReminders();
      return created;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<Reminder> updateReminder(Reminder reminder, {String categoryName = ''}) async {
    try {
      final updated = await _repository.updateReminder(reminder);
      await _notificationService.scheduleReminderNotification(updated, categoryName: categoryName);
      await loadReminders();
      return updated;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Optimistic completion (§4.4, §9.4)
  Future<(Reminder, CompletionRecord)> completeReminder(
    String id, {
    String source = 'app',
    DateTime? now,
    String categoryName = '',
  }) async {
    final currentNow = now ?? DateTime.now();
    final index = _reminders.indexWhere((r) => r.id == id);
    Reminder? previous;
    if (index != -1) {
      previous = _reminders[index];
    }

    try {
      final (updated, record) = await _repository.completeReminder(id, now: currentNow, source: source);
      if (updated.isCompleted) {
        await _notificationService.cancelNotification(updated.notificationId);
      } else {
        await _notificationService.scheduleReminderNotification(updated, categoryName: categoryName);
      }
      await loadReminders(now: currentNow);
      return (updated, record);
    } catch (e) {
      if (previous != null && index != -1) {
        _reminders[index] = previous;
        notifyListeners();
      }
      _errorMessage = e.toString();
      rethrow;
    }
  }

  Future<void> undoCompletion(
    String reminderId,
    String completionRecordId,
    Reminder previousState, {
    String categoryName = '',
  }) async {
    try {
      await _repository.undoCompletion(reminderId, completionRecordId, previousState);
      await _notificationService.scheduleReminderNotification(previousState, categoryName: categoryName);
      await loadReminders();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> snoozeReminder(String id, DateTime snoozedUntil, {String categoryName = ''}) async {
    try {
      final updated = await _repository.snoozeReminder(id, snoozedUntil);
      await _notificationService.scheduleReminderNotification(updated, categoryName: categoryName);
      await loadReminders();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleFavorite(String id) async {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index != -1) {
      final item = _reminders[index];
      _reminders[index] = item.copyWith(isFavorite: !item.isFavorite);
      notifyListeners();
    }

    try {
      await _repository.toggleFavorite(id);
      await loadReminders();
    } catch (e) {
      _errorMessage = e.toString();
      await loadReminders();
    }
  }

  Future<void> deleteReminder(String id) async {
    final index = _reminders.indexWhere((r) => r.id == id);
    Reminder? deletedItem;
    if (index != -1) {
      deletedItem = _reminders[index];
      _reminders.removeAt(index);
      notifyListeners();
    }

    try {
      if (deletedItem != null) {
        await _notificationService.cancelNotification(deletedItem.notificationId);
      }
      await _repository.deleteReminder(id);
      await loadReminders();
    } catch (e) {
      _errorMessage = e.toString();
      await loadReminders();
      rethrow;
    }
  }

  Future<void> restoreReminder(String id, {String categoryName = ''}) async {
    try {
      await _repository.restoreReminder(id);
      final reminder = await _repository.getReminderById(id);
      if (reminder != null) {
        await _notificationService.scheduleReminderNotification(reminder, categoryName: categoryName);
      }
      await loadReminders();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<int> clearCompletedReminders() async {
    try {
      final count = await _repository.clearCompletedReminders();
      await loadReminders();
      return count;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteAllData() async {
    try {
      await _notificationService.cancelAllNotifications();
      await _repository.deleteAllData();
      await loadReminders();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<List<Reminder>> getTrash() async {
    try {
      return await _repository.getTrash();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> catchUpOnLaunch({DateTime? now}) async {
    final currentNow = now ?? DateTime.now();
    final count = await _repository.catchUpOverdueReminders(now: currentNow);
    if (count > 0) {
      await _notificationService.showOverdueSummaryNotification(count);
    }
    await loadReminders(now: currentNow);
  }
}
