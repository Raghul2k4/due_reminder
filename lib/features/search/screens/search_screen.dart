import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/providers/category_provider.dart';
import '../../../app/providers/reminder_provider.dart';
import '../../../app/providers/subscription_provider.dart';
import '../../../core/extensions/date_extensions.dart';
import '../../../data/models/category.dart';
import '../../../data/models/reminder_enums.dart';
import '../../../data/models/subscription.dart';
import '../../../data/models/subscription_enums.dart';
import '../../../data/repositories/reminder_repository.dart';
import '../../../shared/empty_state_widget.dart';
import '../../reminders/screens/reminder_detail_screen.dart';
import '../../reminders/widgets/reminder_tile.dart';
import '../../subscriptions/screens/add_edit_subscription_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionProvider>().loadSubscriptions();
    });
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        context.read<ReminderProvider>().setSearchQuery(_searchController.text);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reminderProvider = context.watch<ReminderProvider>();
    final categoryProvider = context.watch<CategoryProvider>();

    final activeFilter = reminderProvider.activeFilter;
    final selectedCategory = reminderProvider.selectedCategoryId;
    final selectedPriority = reminderProvider.selectedPriority;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search & Filters'),
      ),
      body: Column(
        children: [
          // Search Input Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search title, description, category...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          reminderProvider.setSearchQuery('');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Filter Chips Horizontal Scroll
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: [
                _buildFilterChip('All', ReminderFilter.all, activeFilter, reminderProvider),
                const SizedBox(width: 8),
                _buildFilterChip('Today', ReminderFilter.today, activeFilter, reminderProvider),
                const SizedBox(width: 8),
                _buildFilterChip('Upcoming', ReminderFilter.upcoming, activeFilter, reminderProvider),
                const SizedBox(width: 8),
                _buildFilterChip('Overdue', ReminderFilter.overdue, activeFilter, reminderProvider),
                const SizedBox(width: 8),
                _buildFilterChip('Completed', ReminderFilter.completed, activeFilter, reminderProvider),
                const SizedBox(width: 8),
                _buildFilterChip('Favorites', ReminderFilter.favorites, activeFilter, reminderProvider),
              ],
            ),
          ),

          // Secondary Filters (Category, Priority, Sort) Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: [
                // Category Filter
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    isExpanded: true,
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      hintText: 'All Categories',
                    ),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('All Categories')),
                      ...categoryProvider.categories.map(
                        (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                      ),
                    ],
                    onChanged: (val) => reminderProvider.setCategory(val),
                  ),
                ),
                const SizedBox(width: 8),

                // Priority Filter
                Expanded(
                  child: DropdownButtonFormField<Priority?>(
                    isExpanded: true,
                    initialValue: selectedPriority,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      hintText: 'All Priorities',
                    ),
                    items: const [
                      DropdownMenuItem<Priority?>(value: null, child: Text('All Priorities')),
                      DropdownMenuItem(value: Priority.high, child: Text('High')),
                      DropdownMenuItem(value: Priority.medium, child: Text('Medium')),
                      DropdownMenuItem(value: Priority.low, child: Text('Low')),
                    ],
                    onChanged: (val) => reminderProvider.setPriority(val),
                  ),
                ),
                const SizedBox(width: 8),

                // Sort Menu Icon Button
                PopupMenuButton<ReminderSort>(
                  icon: const Icon(Icons.sort),
                  tooltip: 'Sort by',
                  onSelected: (sort) => reminderProvider.setSort(sort),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: ReminderSort.dueDate, child: Text('Due Date')),
                    PopupMenuItem(value: ReminderSort.priority, child: Text('Priority')),
                    PopupMenuItem(value: ReminderSort.recentlyCreated, child: Text('Recently Created')),
                    PopupMenuItem(value: ReminderSort.recentlyCompleted, child: Text('Recently Completed')),
                  ],
                ),
              ],
            ),
          ),

          // Count & Clear All Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${reminderProvider.reminders.length} reminders found',
                  style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                if (_searchController.text.isNotEmpty ||
                    activeFilter != ReminderFilter.all ||
                    selectedCategory != null ||
                    selectedPriority != null)
                  TextButton(
                    onPressed: () {
                      _searchController.clear();
                      reminderProvider.clearFilters();
                    },
                    child: const Text('Clear filters'),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Results List / Empty State
          Expanded(
            child: Builder(
              builder: (context) {
                final subscriptionProvider = context.watch<SubscriptionProvider>();
                final query = reminderProvider.searchQuery.trim().toLowerCase();
                final matchingSubscriptions = query.isEmpty
                    ? <Subscription>[]
                    : subscriptionProvider.subscriptions.where((s) {
                        return s.name.toLowerCase().contains(query) ||
                            (s.notes?.toLowerCase().contains(query) ?? false);
                      }).toList();

                final reminders = reminderProvider.reminders;
                final hasNothing = reminders.isEmpty && matchingSubscriptions.isEmpty;

                if (hasNothing) {
                  return EmptyStateWidget(
                    icon: Icons.search_off,
                    headline: 'Nothing found.',
                    body: 'Try a different word, or check your filters.',
                    actionLabel: 'Clear search',
                    onActionPressed: () {
                      _searchController.clear();
                      reminderProvider.clearFilters();
                    },
                  );
                }

                return ListView(
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    if (matchingSubscriptions.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(
                          'Subscriptions',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      ...matchingSubscriptions.map((s) => _buildSubscriptionResultTile(context, s)),
                    ],
                    if (reminders.isNotEmpty) ...[
                      if (matchingSubscriptions.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Text(
                            'Reminders',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ...reminders.map((r) {
                        final category = categoryProvider.getCategoryById(r.categoryId) ?? Category.defaultCategory;
                        return ReminderTile(
                          reminder: r,
                          category: category,
                          onCompleteChanged: (_) {
                            context.read<ReminderProvider>().completeReminder(r.id, categoryName: category.name);
                          },
                          onFavoriteToggle: () => context.read<ReminderProvider>().toggleFavorite(r.id),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReminderDetailScreen(reminderId: r.id),
                              ),
                            );
                          },
                        );
                      }),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionResultTile(BuildContext context, Subscription sub) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.autorenew),
        title: Text(sub.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${sub.price.toStringAsFixed(2)} ${sub.currency} · ${sub.billingCycle.displayName}'),
        trailing: sub.isActive
            ? Text(
                sub.nextRenewalDate.toRelativeString(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              )
            : Text(sub.status.displayName),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddEditSubscriptionScreen(subscription: sub),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    ReminderFilter filter,
    ReminderFilter currentFilter,
    ReminderProvider provider,
  ) {
    final isSelected = filter == currentFilter;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => provider.setFilter(filter),
    );
  }
}
