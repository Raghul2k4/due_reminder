import '../../../data/models/reminder_enums.dart';

/// One-tap starter for the canonical §2.3 scenarios.
///
/// Pure local constants — no schema change, no network. Each template maps
/// to a fully prefilled Add form so any life-maintenance task is creatable
/// in under 15 seconds.
class ReminderTemplate {
  final String title;
  final String categoryId;
  final RepeatType repeatType;
  final int repeatInterval;
  final RepeatUnit repeatUnit;
  final String hint;

  const ReminderTemplate({
    required this.title,
    required this.categoryId,
    required this.repeatType,
    this.repeatInterval = 1,
    this.repeatUnit = RepeatUnit.days,
    required this.hint,
  });
}

const List<ReminderTemplate> reminderTemplates = [
  ReminderTemplate(
    title: 'Bike service',
    categoryId: 'cat_vehicle',
    repeatType: RepeatType.custom,
    repeatInterval: 3,
    repeatUnit: RepeatUnit.months,
    hint: 'Every 3 months',
  ),
  ReminderTemplate(
    title: 'Insurance renewal',
    categoryId: 'cat_finance',
    repeatType: RepeatType.yearly,
    hint: 'Every year',
  ),
  ReminderTemplate(
    title: 'Rent',
    categoryId: 'cat_finance',
    repeatType: RepeatType.monthly,
    hint: 'Every month',
  ),
  ReminderTemplate(
    title: 'Electricity bill',
    categoryId: 'cat_finance',
    repeatType: RepeatType.monthly,
    hint: 'Every month',
  ),
  ReminderTemplate(
    title: 'Water filter replacement',
    categoryId: 'cat_home',
    repeatType: RepeatType.custom,
    repeatInterval: 6,
    repeatUnit: RepeatUnit.months,
    hint: 'Every 6 months',
  ),
  ReminderTemplate(
    title: 'Vehicle pollution (PUC) certificate',
    categoryId: 'cat_vehicle',
    repeatType: RepeatType.yearly,
    hint: 'Every year',
  ),
  ReminderTemplate(
    title: 'Dentist checkup',
    categoryId: 'cat_health',
    repeatType: RepeatType.custom,
    repeatInterval: 6,
    repeatUnit: RepeatUnit.months,
    hint: 'Every 6 months',
  ),
  ReminderTemplate(
    title: 'Water the plants',
    categoryId: 'cat_home',
    repeatType: RepeatType.custom,
    repeatInterval: 2,
    repeatUnit: RepeatUnit.days,
    hint: 'Every 2 days',
  ),
  ReminderTemplate(
    title: 'Family birthday',
    categoryId: 'cat_family',
    repeatType: RepeatType.yearly,
    hint: 'Every year',
  ),
  ReminderTemplate(
    title: 'Doctor appointment',
    categoryId: 'cat_health',
    repeatType: RepeatType.none,
    hint: 'One-off',
  ),
];
