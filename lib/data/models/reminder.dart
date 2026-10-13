import 'reminder_enums.dart';

class Reminder {
  final String id;
  final String title;
  final String? description;
  final String categoryId;
  final Priority priority;
  final DateTime createdAt;
  final DateTime startDate;
  final DateTime dueDate;
  final DateTime? dueTime;
  final bool isCompleted;
  final bool isFavorite;
  final RepeatType repeatType;
  final int repeatInterval;
  final RepeatUnit repeatUnit;
  final bool notificationEnabled;
  final DateTime? notificationTime;
  final int notificationId;
  final DateTime? completedAt;
  final DateTime? lastCompletedAt;
  final DateTime nextDueDate;
  final DateTime? snoozedUntil;
  final bool isDeleted;

  const Reminder({
    required this.id,
    required this.title,
    this.description,
    required this.categoryId,
    this.priority = Priority.medium,
    required this.createdAt,
    required this.startDate,
    required this.dueDate,
    this.dueTime,
    this.isCompleted = false,
    this.isFavorite = false,
    this.repeatType = RepeatType.none,
    this.repeatInterval = 1,
    this.repeatUnit = RepeatUnit.days,
    this.notificationEnabled = true,
    this.notificationTime,
    required this.notificationId,
    this.completedAt,
    this.lastCompletedAt,
    required this.nextDueDate,
    this.snoozedUntil,
    this.isDeleted = false,
  });

  bool get isRecurring => repeatType != RepeatType.none;

  DateTime get effectiveDueDate => snoozedUntil ?? nextDueDate;

  Reminder copyWith({
    String? id,
    String? title,
    String? description,
    String? categoryId,
    Priority? priority,
    DateTime? createdAt,
    DateTime? startDate,
    DateTime? dueDate,
    DateTime? dueTime,
    bool? isCompleted,
    bool? isFavorite,
    RepeatType? repeatType,
    int? repeatInterval,
    RepeatUnit? repeatUnit,
    bool? notificationEnabled,
    DateTime? notificationTime,
    int? notificationId,
    DateTime? completedAt,
    DateTime? lastCompletedAt,
    DateTime? nextDueDate,
    DateTime? snoozedUntil,
    bool? isDeleted,
    bool clearDescription = false,
    bool clearDueTime = false,
    bool clearNotificationTime = false,
    bool clearCompletedAt = false,
    bool clearLastCompletedAt = false,
    bool clearSnoozedUntil = false,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      categoryId: categoryId ?? this.categoryId,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      dueTime: clearDueTime ? null : (dueTime ?? this.dueTime),
      isCompleted: isCompleted ?? this.isCompleted,
      isFavorite: isFavorite ?? this.isFavorite,
      repeatType: repeatType ?? this.repeatType,
      repeatInterval: repeatInterval ?? this.repeatInterval,
      repeatUnit: repeatUnit ?? this.repeatUnit,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      notificationTime: clearNotificationTime ? null : (notificationTime ?? this.notificationTime),
      notificationId: notificationId ?? this.notificationId,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      lastCompletedAt: clearLastCompletedAt ? null : (lastCompletedAt ?? this.lastCompletedAt),
      nextDueDate: nextDueDate ?? this.nextDueDate,
      snoozedUntil: clearSnoozedUntil ? null : (snoozedUntil ?? this.snoozedUntil),
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category_id': categoryId,
      'priority': priority.toName(),
      'created_at': createdAt.millisecondsSinceEpoch,
      'start_date': startDate.millisecondsSinceEpoch,
      'due_date': dueDate.millisecondsSinceEpoch,
      'due_time': dueTime?.millisecondsSinceEpoch,
      'is_completed': isCompleted ? 1 : 0,
      'is_favorite': isFavorite ? 1 : 0,
      'repeat_type': repeatType.toName(),
      'repeat_interval': repeatInterval,
      'repeat_unit': repeatUnit.toName(),
      'notification_enabled': notificationEnabled ? 1 : 0,
      'notification_time': notificationTime?.millisecondsSinceEpoch,
      'notification_id': notificationId,
      'completed_at': completedAt?.millisecondsSinceEpoch,
      'last_completed_at': lastCompletedAt?.millisecondsSinceEpoch,
      'next_due_date': nextDueDate.millisecondsSinceEpoch,
      'snoozed_until': snoozedUntil?.millisecondsSinceEpoch,
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      categoryId: map['category_id'] as String,
      priority: PriorityExtension.fromString(map['priority'] as String? ?? 'medium'),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      startDate: DateTime.fromMillisecondsSinceEpoch(map['start_date'] as int),
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['due_date'] as int),
      dueTime: map['due_time'] != null ? DateTime.fromMillisecondsSinceEpoch(map['due_time'] as int) : null,
      isCompleted: (map['is_completed'] as int) == 1,
      isFavorite: (map['is_favorite'] as int) == 1,
      repeatType: RepeatTypeExtension.fromString(map['repeat_type'] as String? ?? 'none'),
      repeatInterval: (map['repeat_interval'] as int?) ?? 1,
      repeatUnit: RepeatUnitExtension.fromString(map['repeat_unit'] as String? ?? 'days'),
      notificationEnabled: (map['notification_enabled'] as int) == 1,
      notificationTime: map['notification_time'] != null ? DateTime.fromMillisecondsSinceEpoch(map['notification_time'] as int) : null,
      notificationId: map['notification_id'] as int,
      completedAt: map['completed_at'] != null ? DateTime.fromMillisecondsSinceEpoch(map['completed_at'] as int) : null,
      lastCompletedAt: map['last_completed_at'] != null ? DateTime.fromMillisecondsSinceEpoch(map['last_completed_at'] as int) : null,
      nextDueDate: DateTime.fromMillisecondsSinceEpoch(map['next_due_date'] as int),
      snoozedUntil: map['snoozed_until'] != null ? DateTime.fromMillisecondsSinceEpoch(map['snoozed_until'] as int) : null,
      isDeleted: (map['is_deleted'] as int) == 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
'categoryId': categoryId,
      'priority': priority.toName(),
      'createdAt': createdAt.toIso8601String(),
        'startDate': startDate.toIso8601String(),
        'dueDate': dueDate.toIso8601String(),
        'dueTime': dueTime?.toIso8601String(),
        'isCompleted': isCompleted,
        'isFavorite': isFavorite,
        'repeatType': repeatType.toName(),
        'repeatInterval': repeatInterval,
        'repeatUnit': repeatUnit.toName(),
        'notificationEnabled': notificationEnabled,
        'notificationTime': notificationTime?.toIso8601String(),
        'notificationId': notificationId,
        'completedAt': completedAt?.toIso8601String(),
        'lastCompletedAt': lastCompletedAt?.toIso8601String(),
        'nextDueDate': nextDueDate.toIso8601String(),
        'snoozedUntil': snoozedUntil?.toIso8601String(),
        'isDeleted': isDeleted,
      };

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        categoryId: json['categoryId'] as String? ?? json['category_id'] as String,
priority: PriorityExtension.fromString(json['priority'] as String? ?? 'medium'),
      createdAt: DateTime.parse(json['createdAt'] as String? ?? json['created_at'] as String),
        startDate: DateTime.parse(json['startDate'] as String? ?? json['start_date'] as String),
        dueDate: DateTime.parse(json['dueDate'] as String? ?? json['due_date'] as String),
        dueTime: json['dueTime'] != null ? DateTime.parse(json['dueTime'] as String) : (json['due_time'] != null ? DateTime.fromMillisecondsSinceEpoch(json['due_time'] as int) : null),
        isCompleted: json['isCompleted'] as bool? ?? (json['is_completed'] == 1),
        isFavorite: json['isFavorite'] as bool? ?? (json['is_favorite'] == 1),
        repeatType: RepeatTypeExtension.fromString(json['repeatType'] as String? ?? json['repeat_type'] as String? ?? 'none'),
        repeatInterval: json['repeatInterval'] as int? ?? json['repeat_interval'] as int? ?? 1,
        repeatUnit: RepeatUnitExtension.fromString(json['repeatUnit'] as String? ?? json['repeat_unit'] as String? ?? 'days'),
        notificationEnabled: json['notificationEnabled'] as bool? ?? (json['notification_enabled'] == 1),
        notificationTime: json['notificationTime'] != null ? DateTime.parse(json['notificationTime'] as String) : null,
        notificationId: json['notificationId'] as int? ?? json['notification_id'] as int? ?? 0,
        completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
        lastCompletedAt: json['lastCompletedAt'] != null ? DateTime.parse(json['lastCompletedAt'] as String) : null,
        nextDueDate: DateTime.parse(json['nextDueDate'] as String? ?? json['next_due_date'] as String),
        snoozedUntil: json['snoozedUntil'] != null ? DateTime.parse(json['snoozedUntil'] as String) : null,
        isDeleted: json['isDeleted'] as bool? ?? (json['is_deleted'] == 1),
      );
}
