import 'subscription_enums.dart';

/// A recurring paid subscription the user wants to track (§1).
///
/// Immutable; use [copyWith]. All dates are stored as local DateTimes and
/// converted to UTC epoch milliseconds at the repository boundary.
class Subscription {
  final String id;
  final String name;
  final String? notes;
  final double price;
  final String currency;
  final BillingCycle billingCycle;
  final DateTime nextRenewalDate;
  final SubscriptionStatus status;
  final bool reminderEnabled;
  final SubscriptionReminderLead reminderLead;
  final DateTime createdAt;
  final int notificationId;

  const Subscription({
    required this.id,
    required this.name,
    this.notes,
    required this.price,
    this.currency = 'USD',
    this.billingCycle = BillingCycle.monthly,
    required this.nextRenewalDate,
    this.status = SubscriptionStatus.active,
    this.reminderEnabled = true,
    this.reminderLead = SubscriptionReminderLead.oneDay,
    required this.createdAt,
    required this.notificationId,
  });

  /// Only active subscriptions count toward spending totals (§2).
  bool get isActive => status == SubscriptionStatus.active;

  Subscription copyWith({
    String? id,
    String? name,
    String? notes,
    double? price,
    String? currency,
    BillingCycle? billingCycle,
    DateTime? nextRenewalDate,
    SubscriptionStatus? status,
    bool? reminderEnabled,
    SubscriptionReminderLead? reminderLead,
    DateTime? createdAt,
    int? notificationId,
    bool clearNotes = false,
  }) {
    return Subscription(
      id: id ?? this.id,
      name: name ?? this.name,
      notes: clearNotes ? null : (notes ?? this.notes),
      price: price ?? this.price,
      currency: currency ?? this.currency,
      billingCycle: billingCycle ?? this.billingCycle,
      nextRenewalDate: nextRenewalDate ?? this.nextRenewalDate,
      status: status ?? this.status,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderLead: reminderLead ?? this.reminderLead,
      createdAt: createdAt ?? this.createdAt,
      notificationId: notificationId ?? this.notificationId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'notes': notes,
      'price': price,
      'currency': currency,
      'billing_cycle': billingCycle.toName(),
      'next_renewal_date': nextRenewalDate.millisecondsSinceEpoch,
      'status': status.toName(),
      'reminder_enabled': reminderEnabled ? 1 : 0,
      'reminder_lead': reminderLead.toName(),
      'created_at': createdAt.millisecondsSinceEpoch,
      'notification_id': notificationId,
    };
  }

  factory Subscription.fromMap(Map<String, dynamic> map) {
    return Subscription(
      id: map['id'] as String,
      name: map['name'] as String,
      notes: map['notes'] as String?,
      price: (map['price'] as num).toDouble(),
      currency: map['currency'] as String? ?? 'USD',
      billingCycle: BillingCycleExtension.fromString(map['billing_cycle'] as String? ?? 'monthly'),
      nextRenewalDate: DateTime.fromMillisecondsSinceEpoch(map['next_renewal_date'] as int),
      status: SubscriptionStatusExtension.fromString(map['status'] as String? ?? 'active'),
      reminderEnabled: (map['reminder_enabled'] as int?) == 1,
      reminderLead: SubscriptionReminderLeadExtension.fromString(map['reminder_lead'] as String? ?? '1d'),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      notificationId: map['notification_id'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'notes': notes,
        'price': price,
        'currency': currency,
        'billingCycle': billingCycle.toName(),
        'nextRenewalDate': nextRenewalDate.toIso8601String(),
        'status': status.toName(),
        'reminderEnabled': reminderEnabled,
        'reminderLead': reminderLead.toName(),
        'createdAt': createdAt.toIso8601String(),
        'notificationId': notificationId,
      };

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
        id: json['id'] as String,
        name: json['name'] as String,
        notes: json['notes'] as String?,
        price: (json['price'] as num).toDouble(),
        currency: json['currency'] as String? ?? 'USD',
        billingCycle: BillingCycleExtension.fromString(json['billingCycle'] as String? ?? json['billing_cycle'] as String? ?? 'monthly'),
        nextRenewalDate: DateTime.parse(json['nextRenewalDate'] as String? ?? json['next_renewal_date'] as String),
        status: SubscriptionStatusExtension.fromString(json['status'] as String? ?? 'active'),
        reminderEnabled: json['reminderEnabled'] as bool? ?? (json['reminder_enabled'] == 1),
        reminderLead: SubscriptionReminderLeadExtension.fromString(json['reminderLead'] as String? ?? json['reminder_lead'] as String? ?? '1d'),
        createdAt: DateTime.parse(json['createdAt'] as String? ?? json['created_at'] as String),
        notificationId: json['notificationId'] as int? ?? json['notification_id'] as int? ?? 0,
      );
}
