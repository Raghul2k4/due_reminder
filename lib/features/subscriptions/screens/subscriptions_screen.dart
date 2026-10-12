import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/providers/subscription_provider.dart';
import '../../../core/extensions/date_extensions.dart';
import '../../../data/models/subscription.dart';
import '../../../data/models/subscription_enums.dart';
import '../../../shared/empty_state_widget.dart';
import 'add_edit_subscription_screen.dart';

/// Subscription dashboard (§2). Shows spending estimates and upcoming renewals.
class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  bool _showPausedAndCancelled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionProvider>().loadSubscriptions();
    });
  }

  Future<void> _handleDelete(BuildContext context, Subscription sub) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete subscription?'),
        content: Text('Remove "${sub.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    await context.read<SubscriptionProvider>().deleteSubscription(sub.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${sub.name} deleted')),
    );
  }

  Future<void> _togglePauseResume(BuildContext context, Subscription sub) async {
    final provider = context.read<SubscriptionProvider>();
    if (sub.status == SubscriptionStatus.active) {
      await provider.setStatus(sub.id, SubscriptionStatus.paused);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${sub.name} paused')),
        );
      }
    } else {
      await provider.setStatus(sub.id, SubscriptionStatus.active);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${sub.name} resumed')),
        );
      }
    }
  }

  Future<void> _markRenewed(BuildContext context, Subscription sub) async {
    await context.read<SubscriptionProvider>().markRenewed(sub.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${sub.name} marked as renewed')),
    );
  }

  String _formatMoney(double amount, String currency) {
    return NumberFormat.simpleCurrency(name: currency).format(amount);
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String label,
    required double amount,
    required String currency,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        color: theme.colorScheme.surfaceContainerHigh,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _formatMoney(amount, currency),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(BuildContext context, Subscription sub) {
    final statusColors = Theme.of(context).extension<AppStatusColors>() ?? AppStatusColors.light;
    if (sub.status == SubscriptionStatus.paused) return statusColors.snoozed;
    if (sub.status == SubscriptionStatus.cancelled) return statusColors.completed;

    final now = DateTime.now();
    final days = sub.nextRenewalDate
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    if (days < 0) return statusColors.overdue;
    if (days <= 7) return statusColors.today;
    return statusColors.upcoming;
  }


  Widget _buildSubscriptionCard(BuildContext context, Subscription sub) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(context, sub);
    final isActive = sub.isActive;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddEditSubscriptionScreen(subscription: sub),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 48,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sub.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        decoration: sub.status == SubscriptionStatus.cancelled
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_formatMoney(sub.price, sub.currency)} ${sub.billingCycle.shortName}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.event, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            isActive ? sub.nextRenewalDate.toRelativeString() : sub.status.displayName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!isActive) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              sub.status.displayName,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        if (isActive && sub.reminderEnabled) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.notifications_active, size: 14, color: theme.colorScheme.primary),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              _buildSubscriptionMenu(context, sub),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionMenu(BuildContext context, Subscription sub) {
    final isActive = sub.isActive;
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      tooltip: 'More options',
      onSelected: (value) async {
        switch (value) {
          case 'renew':
            await _markRenewed(context, sub);
            break;
          case 'pause':
            await _togglePauseResume(context, sub);
            break;
          case 'edit':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddEditSubscriptionScreen(subscription: sub),
              ),
            );
            break;
          case 'delete':
            await _handleDelete(context, sub);
            break;
        }
      },
      itemBuilder: (context) {
        return [
          if (isActive)
            const PopupMenuItem(
              value: 'renew',
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 20),
                  SizedBox(width: 12),
                  Text('Mark renewed'),
                ],
              ),
            ),
          PopupMenuItem(
            value: 'pause',
            child: Row(
              children: [
                Icon(
                  sub.status == SubscriptionStatus.active
                      ? Icons.pause_circle_outline
                      : Icons.play_circle_outline,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(sub.status == SubscriptionStatus.active ? 'Pause' : 'Resume'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_outlined, size: 20),
                SizedBox(width: 12),
                Text('Edit'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 20, color: Colors.red),
                SizedBox(width: 12),
                Text('Delete', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ];
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<SubscriptionProvider>();

    final all = provider.subscriptions;
    final activeCount = provider.activeSubscriptions.length;
    final upcoming = provider.upcomingRenewals;

    final activeList = all.where((s) => s.isActive).toList();
    final inactiveList = all.where((s) => !s.isActive).toList();

    final currency = activeList.isNotEmpty
        ? activeList.first.currency
        : (all.isNotEmpty ? all.first.currency : 'USD');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscriptions'),
        actions: [
          if (inactiveList.isNotEmpty)
            IconButton(
              icon: Icon(
                _showPausedAndCancelled
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              tooltip: _showPausedAndCancelled ? 'Hide inactive' : 'Show inactive',
              onPressed: () {
                setState(() => _showPausedAndCancelled = !_showPausedAndCancelled);
              },
            ),
        ],
      ),
      body: all.isEmpty
          ? EmptyStateWidget(
              icon: Icons.autorenew,
              headline: 'No subscriptions yet.',
              body: 'Track recurring expenses like streaming, gym, and bills, and get reminded before they renew.',
              actionLabel: 'Add subscription',
              onActionPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddEditSubscriptionScreen(),
                  ),
                );
              },
            )
          : RefreshIndicator(
                  onRefresh: provider.loadSubscriptions,
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 96),
                    children: [
                      // Spending summary (active only, §2)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                        child: Row(
                          children: [
                            _buildSummaryCard(
                              context,
                              label: 'Est. monthly',
                              amount: provider.totalMonthlySpending,
                              currency: currency,
                              icon: Icons.calendar_view_month,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            _buildSummaryCard(
                              context,
                              label: 'Est. yearly',
                              amount: provider.totalYearlySpending,
                              currency: currency,
                              icon: Icons.calendar_today,
                              color: theme.colorScheme.tertiary,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Text(
                          'Based on $activeCount active ${activeCount == 1 ? 'subscription' : 'subscriptions'} in $currency.',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),


                      // Upcoming renewals
                      if (upcoming.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                          child: Row(
                            children: [
                              Icon(Icons.upcoming, size: 18, color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Upcoming renewals',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...upcoming.map((s) => _buildSubscriptionCard(context, s)),
                      ] else ...[
                        const SizedBox(height: 16),
                        EmptyStateWidget(
                          icon: Icons.event_available,
                          headline: 'No upcoming renewals.',
                          body: 'Nothing is set to renew soon.',
                        ),
                      ],

                      // Inactive subscriptions
                      if (_showPausedAndCancelled && inactiveList.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                          child: Text(
                            'Paused & cancelled',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ...inactiveList.map((s) => _buildSubscriptionCard(context, s)),
                      ],
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddEditSubscriptionScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add subscription'),
      ),
    );
  }
}

