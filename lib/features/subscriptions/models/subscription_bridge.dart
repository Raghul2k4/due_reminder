import 'package:flutter/material.dart';

import '../../../data/models/subscription.dart';

/// One-tap conversion from a paid subscription into a life reminder.
///
/// Keeps the subscription system untouched; produces a prefilled yearly or
/// monthly reminder so renewals also appear on Home, Calendar and Search.
class SubscriptionReminderBridge {
  static String suggestedTitle(Subscription s) => '${s.name} renewal';

  static String suggestedCategoryId(Subscription s) {
    final name = s.name.toLowerCase();
    if (name.contains('netflix') ||
        name.contains('spotify') ||
        name.contains('prime') ||
        name.contains('disney') ||
        name.contains('music')) {
      return 'cat_subscriptions';
    }
    return 'cat_finance';
  }
}

/// Trash entry with its deletion timestamp for the 30-day purge rule.
class TrashEntry {
  final String id;
  final String title;
  final DateTime deletedAt;

  const TrashEntry({
    required this.id,
    required this.title,
    required this.deletedAt,
  });
}

/// Resolves a subscription-linked icon for shared tiles.
IconData subscriptionIconFor(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('music') || lower.contains('spotify')) {
    return Icons.music_note;
  }
  if (lower.contains('video') ||
      lower.contains('netflix') ||
      lower.contains('youtube')) {
    return Icons.movie;
  }
  if (lower.contains('gym') || lower.contains('fitness')) {
    return Icons.fitness_center;
  }
  return Icons.autorenew;
}
