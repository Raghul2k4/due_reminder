import 'package:flutter/material.dart';

import '../models/reminder_templates.dart';

/// One-tap template picker shown from Home before the full Add form.
///
/// Every §2.3 canonical scenario maps to a prefilled schedule so capture
/// stays under 15 seconds. Tapping a template returns it for the caller to
/// open the Add form prefilled; the structured form always remains available.
class ReminderTemplateSheet extends StatelessWidget {
  const ReminderTemplateSheet({super.key});

  static Future<ReminderTemplate?> show(BuildContext context) {
    return showModalBottomSheet<ReminderTemplate>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const ReminderTemplateSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Start from a template',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pick what repeats — edit anything before saving.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: reminderTemplates.length,
                itemBuilder: (ctx, i) {
                  final t = reminderTemplates[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      minVerticalPadding: 12,
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(
                          _iconFor(t.categoryId),
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      title: Text(
                        t.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(t.hint),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pop(context, t),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String categoryId) {
    switch (categoryId) {
      case 'cat_vehicle':
        return Icons.directions_bike;
      case 'cat_finance':
        return Icons.account_balance_wallet_outlined;
      case 'cat_health':
        return Icons.favorite_outline;
      case 'cat_home':
        return Icons.home_outlined;
      case 'cat_family':
        return Icons.cake_outlined;
      default:
        return Icons.repeat;
    }
  }
}
