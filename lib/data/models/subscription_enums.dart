/// Billing cycle for a subscription (§1).
enum BillingCycle {
  weekly,
  monthly,
  quarterly,
  yearly,
}

extension BillingCycleExtension on BillingCycle {
  String toName() => name;

  static BillingCycle fromString(String value) {
    return BillingCycle.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => BillingCycle.monthly,
    );
  }

  String get displayName {
    switch (this) {
      case BillingCycle.weekly:
        return 'Weekly';
      case BillingCycle.monthly:
        return 'Monthly';
      case BillingCycle.quarterly:
        return 'Quarterly';
      case BillingCycle.yearly:
        return 'Yearly';
    }
  }

  /// Short label used in compact list rows.
  String get shortName {
    switch (this) {
      case BillingCycle.weekly:
        return '/wk';
      case BillingCycle.monthly:
        return '/mo';
      case BillingCycle.quarterly:
        return '/qtr';
      case BillingCycle.yearly:
        return '/yr';
    }
  }
}

/// Lifecycle status of a subscription (§1).
enum SubscriptionStatus {
  active,
  paused,
  cancelled,
}

extension SubscriptionStatusExtension on SubscriptionStatus {
  String toName() => name;

  static SubscriptionStatus fromString(String value) {
    return SubscriptionStatus.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => SubscriptionStatus.active,
    );
  }

  String get displayName {
    switch (this) {
      case SubscriptionStatus.active:
        return 'Active';
      case SubscriptionStatus.paused:
        return 'Paused';
      case SubscriptionStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// How far ahead of the renewal date the user wants to be reminded (§1).
enum SubscriptionReminderLead {
  onRenewalDate,
  oneDay,
  threeDays,
  oneWeek,
}

extension SubscriptionReminderLeadExtension on SubscriptionReminderLead {
  /// Stable serialised form, never an index.
  String toName() {
    switch (this) {
      case SubscriptionReminderLead.onRenewalDate:
        return 'on_date';
      case SubscriptionReminderLead.oneDay:
        return '1d';
      case SubscriptionReminderLead.threeDays:
        return '3d';
      case SubscriptionReminderLead.oneWeek:
        return '1w';
    }
  }

  static SubscriptionReminderLead fromString(String value) {
    switch (value) {
      case '1d':
        return SubscriptionReminderLead.oneDay;
      case '3d':
        return SubscriptionReminderLead.threeDays;
      case '1w':
        return SubscriptionReminderLead.oneWeek;
      case 'on_date':
      default:
        return SubscriptionReminderLead.onRenewalDate;
    }
  }

  String get displayName {
    switch (this) {
      case SubscriptionReminderLead.onRenewalDate:
        return 'On renewal date';
      case SubscriptionReminderLead.oneDay:
        return '1 day before';
      case SubscriptionReminderLead.threeDays:
        return '3 days before';
      case SubscriptionReminderLead.oneWeek:
        return '1 week before';
    }
  }

  /// Number of days to subtract from the renewal date to get the notify date.
  int get leadDays {
    switch (this) {
      case SubscriptionReminderLead.onRenewalDate:
        return 0;
      case SubscriptionReminderLead.oneDay:
        return 1;
      case SubscriptionReminderLead.threeDays:
        return 3;
      case SubscriptionReminderLead.oneWeek:
        return 7;
    }
  }
}
