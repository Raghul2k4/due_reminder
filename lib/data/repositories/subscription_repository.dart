import 'package:uuid/uuid.dart';
import '../../core/utils/subscription_recurrence.dart';
import '../database/app_database.dart';
import '../models/subscription.dart';
import '../models/subscription_enums.dart';

/// Data access for the Subscription Reminder Manager.
///
/// All dates cross the boundary as UTC epoch milliseconds (§7.5). The repository
/// never calls DateTime.now() itself; callers pass an injected [now].
class SubscriptionRepository {
  final AppDatabase _dbProvider;
  final Uuid _uuid = const Uuid();

  SubscriptionRepository([AppDatabase? dbProvider]) : _dbProvider = dbProvider ?? AppDatabase();

  Future<Subscription> createSubscription(Subscription subscription) async {
    final name = subscription.name.trim();
    if (name.isEmpty) {
      throw ArgumentError('Subscription name cannot be empty');
    }
    if (subscription.price < 0) {
      throw ArgumentError('Subscription price cannot be negative');
    }

    final db = await _dbProvider.database;
    final id = subscription.id.isEmpty ? _uuid.v4() : subscription.id;
    final notificationId = subscription.notificationId != 0
        ? subscription.notificationId
        : (id.hashCode & 0x7FFFFFFF);

    final created = subscription.copyWith(
      id: id,
      name: name,
      notificationId: notificationId,
    );

    await db.insert('subscriptions', created.toMap());
    return created;
  }

  Future<Subscription?> getSubscriptionById(String id) async {
    final db = await _dbProvider.database;
    final result = await db.query('subscriptions', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Subscription.fromMap(result.first);
  }

  Future<List<Subscription>> getAllSubscriptions({SubscriptionStatus? status}) async {
    final db = await _dbProvider.database;
    final result = status == null
        ? await db.query('subscriptions', orderBy: 'next_renewal_date ASC')
        : await db.query(
            'subscriptions',
            where: 'status = ?',
            whereArgs: [status.toName()],
            orderBy: 'next_renewal_date ASC',
          );
    return result.map((m) => Subscription.fromMap(m)).toList();
  }

  Future<Subscription> updateSubscription(Subscription subscription) async {
    final name = subscription.name.trim();
    if (name.isEmpty) {
      throw ArgumentError('Subscription name cannot be empty');
    }
    if (subscription.price < 0) {
      throw ArgumentError('Subscription price cannot be negative');
    }

    final db = await _dbProvider.database;
    final updated = subscription.copyWith(name: name);
    await db.update(
      'subscriptions',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [updated.id],
    );
    return updated;
  }

  /// Hard delete. Subscriptions are user-owned records with no dependent history,
  /// so a destructive delete is acceptable here (confirmed in the UI, §4.7).
  Future<void> deleteSubscription(String id) async {
    final db = await _dbProvider.database;
    await db.delete('subscriptions', where: 'id = ?', whereArgs: [id]);
  }

  Future<Subscription> setStatus(String id, SubscriptionStatus status) async {
    final subscription = await getSubscriptionById(id);
    if (subscription == null) {
      throw Exception('Subscription with id $id not found');
    }
    final updated = subscription.copyWith(status: status);
    await updateSubscription(updated);
    return updated;
  }

  /// Marks the current renewal as paid and rolls the next renewal forward one
  /// billing cycle, clamping month-end anchors safely (§6.4).
  Future<Subscription> markRenewed(String id, {required DateTime now}) async {
    final subscription = await getSubscriptionById(id);
    if (subscription == null) {
      throw Exception('Subscription with id $id not found');
    }

    final nextRenewal = computeNextRenewalDate(
      anchor: subscription.nextRenewalDate,
      from: now,
      cycle: subscription.billingCycle,
    );

    final updated = subscription.copyWith(nextRenewalDate: nextRenewal);
    await updateSubscription(updated);
    return updated;
  }

  /// Rolls overdue active renewals forward on launch/boot so notifications stay
  /// in the future without silently swallowing missed cycles (§9.6 analogue).
  Future<int> rollForwardOverdueRenewals({required DateTime now}) async {
    final db = await _dbProvider.database;
    final rows = await db.query(
      'subscriptions',
      where: 'status = ?',
      whereArgs: [SubscriptionStatus.active.toName()],
    );

    int count = 0;
    for (final map in rows) {
      final sub = Subscription.fromMap(map);
      if (sub.nextRenewalDate.isBefore(now)) {
        final nextRenewal = computeNextRenewalDate(
          anchor: sub.nextRenewalDate,
          from: now,
          cycle: sub.billingCycle,
        );
        if (nextRenewal != sub.nextRenewalDate) {
          await db.update(
            'subscriptions',
            {'next_renewal_date': nextRenewal.millisecondsSinceEpoch},
            where: 'id = ?',
            whereArgs: [sub.id],
          );
          count++;
        }
      }
    }
    return count;
  }

  Future<void> deleteAllSubscriptions() async {
    final db = await _dbProvider.database;
    await db.delete('subscriptions');
  }
}
