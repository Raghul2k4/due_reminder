import 'package:flutter/material.dart';
import '../../core/services/notification_service.dart';
import '../../core/utils/subscription_recurrence.dart';
import '../../data/models/subscription.dart';
import '../../data/models/subscription_enums.dart';
import '../../data/repositories/subscription_repository.dart';

/// State holder over [SubscriptionRepository] and [NotificationService].
/// No business logic beyond orchestration (§6.2).
class SubscriptionProvider extends ChangeNotifier {
  final SubscriptionRepository _repository;
  final NotificationService _notificationService;

  List<Subscription> _subscriptions = [];
  bool _isLoading = false;
  String? _errorMessage;

  SubscriptionProvider({
    SubscriptionRepository? repository,
    NotificationService? notificationService,
  })  : _repository = repository ?? SubscriptionRepository(),
        _notificationService = notificationService ?? NotificationService();

  List<Subscription> get subscriptions => List.unmodifiable(_subscriptions);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Subscription> get activeSubscriptions =>
      _subscriptions.where((s) => s.isActive).toList();

  /// Upcoming renewals: active subscriptions whose renewal date is today or
  /// later, soonest first (§2).
  List<Subscription> get upcomingRenewals {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final list = _subscriptions
        .where((s) => s.isActive && !s.nextRenewalDate.isBefore(todayStart))
        .toList()
      ..sort((a, b) => a.nextRenewalDate.compareTo(b.nextRenewalDate));
    return list;
  }

  /// Total estimated monthly spending across active subscriptions only (§2).
  double get totalMonthlySpending => activeSubscriptions.fold(
        0,
        (sum, s) => sum + monthlyEquivalent(s.price, s.billingCycle),
      );

  /// Total estimated yearly spending across active subscriptions only (§2).
  double get totalYearlySpending => activeSubscriptions.fold(
        0,
        (sum, s) => sum + yearlyEquivalent(s.price, s.billingCycle),
      );

  Future<void> loadSubscriptions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _subscriptions = await _repository.getAllSubscriptions();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Subscription> createSubscription(Subscription subscription) async {
    try {
      final created = await _repository.createSubscription(subscription);
      await _notificationService.scheduleSubscriptionNotification(created);
      await loadSubscriptions();
      return created;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<Subscription> updateSubscription(Subscription subscription) async {
    try {
      final updated = await _repository.updateSubscription(subscription);
      await _notificationService.scheduleSubscriptionNotification(updated);
      await loadSubscriptions();
      return updated;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Pause or resume. Pausing/cancelling cancels the pending notification (§3).
  Future<void> setStatus(String id, SubscriptionStatus status) async {
    try {
      final updated = await _repository.setStatus(id, status);
      await _notificationService.scheduleSubscriptionNotification(updated);
      await loadSubscriptions();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteSubscription(String id) async {
    // Optimistic removal.
    final index = _subscriptions.indexWhere((s) => s.id == id);
    Subscription? removed;
    if (index != -1) {
      removed = _subscriptions[index];
      _subscriptions.removeAt(index);
      notifyListeners();
    }

    try {
      if (removed != null) {
        await _notificationService.cancelNotification(removed.notificationId);
      }
      await _repository.deleteSubscription(id);
      await loadSubscriptions();
    } catch (e) {
      _errorMessage = e.toString();
      await loadSubscriptions();
      rethrow;
    }
  }

  /// Marks a renewal paid and rolls the next renewal date forward one cycle.
  Future<Subscription> markRenewed(String id, {DateTime? now}) async {
    try {
      final updated = await _repository.markRenewed(id, now: now ?? DateTime.now());
      await _notificationService.scheduleSubscriptionNotification(updated);
      await loadSubscriptions();
      return updated;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteAllSubscriptions() async {
    try {
      for (final sub in _subscriptions) {
        await _notificationService.cancelNotification(sub.notificationId);
      }
      await _repository.deleteAllSubscriptions();
      await loadSubscriptions();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Rolls overdue renewals forward on launch/boot and re-registers notifications
  /// for all active subscriptions (§3, §9.6 analogue).
  Future<void> catchUpOnLaunch({DateTime? now}) async {
    final currentNow = now ?? DateTime.now();
    try {
      await _repository.rollForwardOverdueRenewals(now: currentNow);
      await loadSubscriptions();
      for (final sub in activeSubscriptions) {
        await _notificationService.scheduleSubscriptionNotification(sub);
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
