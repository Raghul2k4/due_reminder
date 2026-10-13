import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/providers/reminder_provider.dart';
import '../../../shared/empty_state_widget.dart';

/// Trash: soft-deleted reminders restorable within ~30 days (§4.7).
class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trash')),
      body: FutureBuilder(
        future: context.read<ReminderProvider>().getTrash(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.delete_outline,
              headline: 'Trash is empty.',
              body: 'Deleted reminders stay here for 30 days.',
            );
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, i) {
              final r = items[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(
                    r.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: const Text('Deleted — restorable for 30 days'),
                  trailing: TextButton(
                    onPressed: () async {
                      await context
                          .read<ReminderProvider>()
                          .restoreReminder(r.id);
                      if (context.mounted) setState(() {});
                    },
                    child: const Text('Restore'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
