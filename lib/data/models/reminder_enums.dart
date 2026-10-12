enum RepeatType {
  none,
  daily,
  weekly,
  monthly,
  yearly,
  custom,
}

extension RepeatTypeExtension on RepeatType {
  String toName() => name;

  static RepeatType fromString(String value) {
    return RepeatType.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => RepeatType.none,
    );
  }

  String get displayName {
    switch (this) {
      case RepeatType.none:
        return 'Never';
      case RepeatType.daily:
        return 'Daily';
      case RepeatType.weekly:
        return 'Weekly';
      case RepeatType.monthly:
        return 'Monthly';
      case RepeatType.yearly:
        return 'Yearly';
      case RepeatType.custom:
        return 'Custom';
    }
  }
}

enum RepeatUnit {
  days,
  weeks,
  months,
  years,
}

extension RepeatUnitExtension on RepeatUnit {
  String toName() => name;

  static RepeatUnit fromString(String value) {
    return RepeatUnit.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => RepeatUnit.days,
    );
  }

  String get displayName {
    switch (this) {
      case RepeatUnit.days:
        return 'Days';
      case RepeatUnit.weeks:
        return 'Weeks';
      case RepeatUnit.months:
        return 'Months';
      case RepeatUnit.years:
        return 'Years';
    }
  }
}

enum Priority {
  low,
  medium,
  high,
}

extension PriorityExtension on Priority {
  String toName() => name;

  static Priority fromString(String value) {
    return Priority.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => Priority.medium,
    );
  }

  String get displayName {
    switch (this) {
      case Priority.low:
        return 'Low';
      case Priority.medium:
        return 'Medium';
      case Priority.high:
        return 'High';
    }
  }
}

enum ThemeModePreference {
  light,
  dark,
  system,
}

extension ThemeModePreferenceExtension on ThemeModePreference {
  String toName() => name;

  static ThemeModePreference fromString(String value) {
    return ThemeModePreference.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => ThemeModePreference.system,
    );
  }
}

enum AdvanceNotificationOffset {
  atTime,
  oneDay,
  threeDays,
  oneWeek,
}

extension AdvanceNotificationOffsetExtension on AdvanceNotificationOffset {
  String toName() {
    switch (this) {
      case AdvanceNotificationOffset.atTime:
        return 'at_time';
      case AdvanceNotificationOffset.oneDay:
        return '1d';
      case AdvanceNotificationOffset.threeDays:
        return '3d';
      case AdvanceNotificationOffset.oneWeek:
        return '1w';
    }
  }

  static AdvanceNotificationOffset fromString(String value) {
    switch (value) {
      case '1d':
        return AdvanceNotificationOffset.oneDay;
      case '3d':
        return AdvanceNotificationOffset.threeDays;
      case '1w':
        return AdvanceNotificationOffset.oneWeek;
      case 'at_time':
      default:
        return AdvanceNotificationOffset.atTime;
    }
  }

  String get displayName {
    switch (this) {
      case AdvanceNotificationOffset.atTime:
        return 'At time of due';
      case AdvanceNotificationOffset.oneDay:
        return '1 day before';
      case AdvanceNotificationOffset.threeDays:
        return '3 days before';
      case AdvanceNotificationOffset.oneWeek:
        return '1 week before';
    }
  }
}
