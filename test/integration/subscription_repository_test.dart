import 'package:flutter_test/flutter_test.dart';
import 'package:life_reminder/data/database/app_database.dart';
import 'package:life_reminder/data/models/subscription.dart';
import 'package:life_reminder/data/models/subscription_enums.dart';
import 'package:life_reminder/data/repositories/subscription_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late AppDatabase appDb;
  late SubscriptionRepository repo;

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 2,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON;');
        },
        onCreate: (db, version) async {
          // Mirror the real schema's subscriptions table.
          await db.execute('''
            CREATE TABLE subscriptions (
              id                TEXT PRIMARY KEY,
              name              TEXT NOT NULL,
              notes             TEXT,
              price             REAL NOT NULL,
              currency          TEXT NOT NULL DEFAULT 'USD',
              billing_cycle     TEXT NOT NULL,
              next_renewal_date INTEGER NOT NULL,
              status            TEXT NOT NULL DEFAULT 'active',
              reminder_enabled  INTEGER NOT NULL DEFAULT 0,
              reminder_lead     TEXT NOT NULL DEFAULT '1d',
              created_at        INTEGER NOT NULL,
              notification_id   INTEGER NOT NULL
            );
          ''');
        },
      ),
    );
    appDb = AppDatabase.withDatabase(db);
    repo = SubscriptionRepository(appDb);
  });

  tearDown(() async {
    await db.close();
  });

  Subscription sample({
    String id = 'sub_1',
    String name = 'Netflix',
    double price = 15.99,
    BillingCycle cycle = BillingCycle.monthly,
    DateTime? renewal,
    SubscriptionStatus status = SubscriptionStatus.active,
  }) {
    return Subscription(
      id: id,
      name: name,
      price: price,
      currency: 'USD',
      billingCycle: cycle,
      nextRenewalDate: renewal ?? DateTime(2026, 11, 1),
      status: status,
      reminderEnabled: true,
      reminderLead: SubscriptionReminderLead.oneDay,
      createdAt: DateTime(2026, 10, 9),
      notificationId: 0,
    );
  }

  group('SubscriptionRepository Integration', () {
    test('Create and read subscription', () async {
      final created = await repo.createSubscription(sample());
      expect(created.name, 'Netflix');
      expect(created.notificationId, isNot(0));

      final retrieved = await repo.getSubscriptionById('sub_1');
      expect(retrieved, isNotNull);
      expect(retrieved!.price, 15.99);
      expect(retrieved.billingCycle, BillingCycle.monthly);
    });

    test('Empty name is rejected', () async {
      expect(() => repo.createSubscription(sample(name: '   ')), throwsA(isA<ArgumentError>()));
    });

    test('Negative price is rejected', () async {
      expect(() => repo.createSubscription(sample(price: -1)), throwsA(isA<ArgumentError>()));
    });

    test('Update subscription persists changes', () async {
      await repo.createSubscription(sample());
      final updated = await repo.updateSubscription(sample(price: 22.99, name: 'Spotify'));
      expect(updated.price, 22.99);
      final retrieved = await repo.getSubscriptionById('sub_1');
      expect(retrieved!.name, 'Spotify');
    });

    test('setStatus toggles paused and cancelled', () async {
      await repo.createSubscription(sample());
      final paused = await repo.setStatus('sub_1', SubscriptionStatus.paused);
      expect(paused.status, SubscriptionStatus.paused);
      final cancelled = await repo.setStatus('sub_1', SubscriptionStatus.cancelled);
      expect(cancelled.status, SubscriptionStatus.cancelled);
    });

    test('markRenewed rolls forward one cycle with clamping', () async {
      await repo.createSubscription(sample(renewal: DateTime(2026, 1, 31)));
      final now = DateTime(2026, 2, 1);
      final renewed = await repo.markRenewed('sub_1', now: now);
      expect(renewed.nextRenewalDate, DateTime(2026, 2, 28));
    });

    test('markRenewed catches up past multiple missed cycles', () async {
      await repo.createSubscription(sample(renewal: DateTime(2026, 1, 15)));
      final now = DateTime(2026, 4, 20);
      final renewed = await repo.markRenewed('sub_1', now: now);
      expect(renewed.nextRenewalDate, DateTime(2026, 5, 15));
    });

    test('getAllSubscriptions filters by status and orders by renewal', () async {
      await repo.createSubscription(sample(id: 'a', renewal: DateTime(2026, 12, 1)));
      await repo.createSubscription(sample(id: 'b', renewal: DateTime(2026, 11, 1)));
      await repo.createSubscription(sample(id: 'c', renewal: DateTime(2026, 10, 1), status: SubscriptionStatus.paused));

      final all = await repo.getAllSubscriptions();
      expect(all.length, 3);
      expect(all.first.id, 'c');

      final active = await repo.getAllSubscriptions(status: SubscriptionStatus.active);
      expect(active.length, 2);
      expect(active.every((s) => s.isActive), isTrue);
    });

    test('rollForwardOverdueRenewals advances only overdue active subscriptions', () async {
      await repo.createSubscription(sample(id: 'overdue', renewal: DateTime(2026, 1, 10)));
      await repo.createSubscription(sample(id: 'future', renewal: DateTime(2026, 12, 10)));
      await repo.createSubscription(sample(id: 'paused', renewal: DateTime(2026, 1, 10), status: SubscriptionStatus.paused));

      final now = DateTime(2026, 6, 15);
      final count = await repo.rollForwardOverdueRenewals(now: now);
      expect(count, 1);

      final overdue = await repo.getSubscriptionById('overdue');
      expect(overdue!.nextRenewalDate.isAfter(now), isTrue);

      final paused = await repo.getSubscriptionById('paused');
      expect(paused!.nextRenewalDate, DateTime(2026, 1, 10));
    });

    test('deleteSubscription removes the record', () async {
      await repo.createSubscription(sample());
      await repo.deleteSubscription('sub_1');
      final retrieved = await repo.getSubscriptionById('sub_1');
      expect(retrieved, isNull);
    });

    test('deleteAllSubscriptions clears the table', () async {
      await repo.createSubscription(sample(id: 'a'));
      await repo.createSubscription(sample(id: 'b'));
      await repo.deleteAllSubscriptions();
      final all = await repo.getAllSubscriptions();
      expect(all, isEmpty);
    });
  });
}

