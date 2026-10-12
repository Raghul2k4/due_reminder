class CompletionRecord {
  final String id;
  final String reminderId;
  final DateTime completedAt;
  final DateTime dueDateSnapshot;
  final bool wasLate;
  final String source; // 'app', 'notification', 'quick_add'

  const CompletionRecord({
    required this.id,
    required this.reminderId,
    required this.completedAt,
    required this.dueDateSnapshot,
    required this.wasLate,
    required this.source,
  });

  CompletionRecord copyWith({
    String? id,
    String? reminderId,
    DateTime? completedAt,
    DateTime? dueDateSnapshot,
    bool? wasLate,
    String? source,
  }) {
    return CompletionRecord(
      id: id ?? this.id,
      reminderId: reminderId ?? this.reminderId,
      completedAt: completedAt ?? this.completedAt,
      dueDateSnapshot: dueDateSnapshot ?? this.dueDateSnapshot,
      wasLate: wasLate ?? this.wasLate,
      source: source ?? this.source,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reminder_id': reminderId,
      'completed_at': completedAt.millisecondsSinceEpoch,
      'due_date_snapshot': dueDateSnapshot.millisecondsSinceEpoch,
      'was_late': wasLate ? 1 : 0,
      'source': source,
    };
  }

  factory CompletionRecord.fromMap(Map<String, dynamic> map) {
    return CompletionRecord(
      id: map['id'] as String,
      reminderId: map['reminder_id'] as String,
      completedAt: DateTime.fromMillisecondsSinceEpoch(map['completed_at'] as int),
      dueDateSnapshot: DateTime.fromMillisecondsSinceEpoch(map['due_date_snapshot'] as int),
      wasLate: (map['was_late'] as int) == 1,
      source: map['source'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'reminderId': reminderId,
        'completedAt': completedAt.toIso8601String(),
        'dueDateSnapshot': dueDateSnapshot.toIso8601String(),
        'wasLate': wasLate,
        'source': source,
      };

  factory CompletionRecord.fromJson(Map<String, dynamic> json) => CompletionRecord(
        id: json['id'] as String,
        reminderId: json['reminderId'] as String? ?? json['reminder_id'] as String,
        completedAt: DateTime.parse(json['completedAt'] as String? ?? json['completed_at'] as String),
        dueDateSnapshot: DateTime.parse(json['dueDateSnapshot'] as String? ?? json['due_date_snapshot'] as String),
        wasLate: json['wasLate'] as bool? ?? (json['was_late'] == 1),
        source: json['source'] as String? ?? 'app',
      );
}
