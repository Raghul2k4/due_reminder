import 'package:intl/intl.dart';

extension DateTimeExtensions on DateTime {
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  String toRelativeString({DateTime? reference}) {
    final ref = reference ?? DateTime.now();
    final today = DateTime(ref.year, ref.month, ref.day);
    final target = DateTime(year, month, day);

    final differenceInDays = target.difference(today).inDays;

    if (differenceInDays == 0) {
      return 'Today';
    } else if (differenceInDays == 1) {
      return 'Tomorrow';
    } else if (differenceInDays == -1) {
      return 'Yesterday';
    } else if (differenceInDays > 1 && differenceInDays <= 7) {
      return 'in $differenceInDays days';
    } else if (differenceInDays < -1 && differenceInDays >= -7) {
      return '${differenceInDays.abs()} days ago';
    } else {
      return DateFormat('d MMM yyyy').format(this);
    }
  }

  String toTimeString() {
    return DateFormat('h:mm a').format(this);
  }

  String toFullDateTimeString() {
    return DateFormat('d MMM yyyy · h:mm a').format(this);
  }
}
