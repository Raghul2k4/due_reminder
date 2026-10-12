import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/providers/category_provider.dart';
import '../../../app/providers/reminder_provider.dart';
import '../../../data/models/category.dart';
import '../../../data/models/reminder_enums.dart';
import '../../../data/repositories/reminder_repository.dart';
import '../../../shared/empty_state_widget.dart';
import '../../reminders/screens/reminder_detail_screen.dart';
import '../../reminders/widgets/reminder_tile.dart';

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
            child: reminderProvider.reminders.isEmpty
                ? EmptyStateWidget(
                    icon: Icons.search_off,
                    headline: 'Nothing found.',
                    body: 'Try a different word, or check your filters.',
                    actionLabel: 'Clear search',
                    onActionPressed: () {
                      _searchController.clear();
                      reminderProvider.clearFilters();
                    },
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: reminderProvider.reminders.length,
                    itemBuilder: (context, index) {
                      final r = reminderProvider.reminders[index];
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
                    },
                  ),
          ),
        ],
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
