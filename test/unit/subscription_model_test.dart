import 'package:flutter_test/flutter_test.dart';
import 'package:life_reminder/data/models/subscription.dart';
import 'package:life_reminder/data/models/subscription_enums.dart';

void main() {
  Subscription buildSample() => Subscription(
        id: 'sub_1',
        name: 'Netflix',
        notes: 'family plan',
        price: 15.99,
        currency: 'USD',
        billingCycle: BillingCycle.monthly,
        nextRenewalDate: DateTime(2026, 11, 1),
        status: SubscriptionStatus.active,
        reminderEnabled: true,
        reminderLead: SubscriptionReminderLead.threeDays,
        createdAt: DateTime(2026, 10, 9),
        notificationId: 42,
      );

  group('Subscription map round-trip', () {
    test('toMap/fromMap preserves all fields', () {
      final sub = buildSample();
      final restored = Subscription.fromMap(sub.toMap());

      expect(restored.id, sub.id);
      expect(restored.name, sub.name);
      expect(restored.notes, sub.notes);
      expect(restored.price, sub.price);
      expect(restored.currency, sub.currency);
      expect(restored.billingCycle, sub.billingCycle);
      expect(restored.nextRenewalDate, sub.nextRenewalDate);
      expect(restored.status, sub.status);
      expect(restored.reminderEnabled, sub.reminderEnabled);
      expect(restored.reminderLead, sub.reminderLead);
      expect(restored.createdAt, sub.createdAt);
      expect(restored.notificationId, sub.notificationId);
    });
  });

  group('Subscription json round-trip', () {
    test('toJson/fromJson preserves all fields', () {
      final sub = buildSample();
      final restored = Subscription.fromJson(sub.toJson());

      expect(restored.id, sub.id);
      expect(restored.name, sub.name);
      expect(restored.price, sub.price);
      expect(restored.billingCycle, sub.billingCycle);
      expect(restored.status, sub.status);
      expect(restored.reminderLead, sub.reminderLead);
      expect(restored.nextRenewalDate, sub.nextRenewalDate);
    });
  });

  group('copyWith clears notes', () {
    test('clearNotes removes notes', () {
      final sub = buildSample();
      final cleared = sub.copyWith(clearNotes: true);
      expect(cleared.notes, isNull);
    });
  });

  group('isActive only for active status', () {
    test('paused and cancelled are not active', () {
      expect(buildSample().copyWith(status: SubscriptionStatus.paused).isActive, isFalse);
      expect(buildSample().copyWith(status: SubscriptionStatus.cancelled).isActive, isFalse);
      expect(buildSample().isActive, isTrue);
    });
  });
}
