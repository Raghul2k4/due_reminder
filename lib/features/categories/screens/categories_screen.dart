import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/providers/category_provider.dart';
import '../../../data/models/category.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  void _showAddEditCategoryDialog(BuildContext context, {Category? category}) {
    final nameController = TextEditingController(text: category?.name ?? '');
    String selectedIconKey = category?.iconKey ?? 'home';
    int selectedColorValue = category?.colorValue ?? 0xFF00796B;

    final isEdit = category != null;

    final availableIcons = [
      'home',
      'directions_car',
      'attach_money',
      'work',
      'local_hospital',
      'description',
      'shopping_cart',
      'school',
      'people',
      'build',
      'subscriptions',
      'pets',
      'fitness_center',
      'flight',
      'restaurant',
      'checkroom',
      'devices',
      'other',
    ];

    final availableColors = [
      0xFF4CAF50,
      0xFF2196F3,
      0xFFFF9800,
      0xFF9C27B0,
      0xFFE91E63,
      0xFF607D8B,
      0xFF00BCD4,
      0xFF3F51B5,
      0xFFFF5722,
      0xFF795548,
      0xFF673AB7,
      0xFF00796B,
    ];

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(isEdit ? 'Edit Category' : 'New Category'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Category Name *',
                        hintText: 'e.g. Garden',
                      ),
                      maxLength: 50,
                    ),
                    const SizedBox(height: 12),
                    Text('Choose Icon', style: Theme.of(ctx).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableIcons.map((iconKey) {
                        final isSelected = iconKey == selectedIconKey;
                        return InkWell(
                          onTap: () => setDialogState(() => selectedIconKey = iconKey),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected ? Theme.of(ctx).colorScheme.primaryContainer : null,
                              border: isSelected ? Border.all(color: Theme.of(ctx).colorScheme.primary, width: 2) : null,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Category.getIconData(iconKey), size: 24),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text('Choose Color', style: Theme.of(ctx).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableColors.map((colorVal) {
                        final isSelected = colorVal == selectedColorValue;
                        return InkWell(
                          onTap: () => setDialogState(() => selectedColorValue = colorVal),
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Color(colorVal),
                              shape: BoxShape.circle,
                              border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    final categoryProvider = context.read<CategoryProvider>();
                    try {
                      if (isEdit) {
                        final updated = category.copyWith(
                          name: name,
                          iconKey: selectedIconKey,
                          colorValue: selectedColorValue,
                        );
                        await categoryProvider.updateCategory(updated);
                      } else {
                        await categoryProvider.createCategory(
                          name,
                          selectedIconKey,
                          selectedColorValue,
                        );
                      }
                      if (context.mounted) Navigator.pop(dialogCtx);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _handleDeleteCategory(BuildContext context, Category category) {
    final count = context.read<CategoryProvider>().categoryCounts[category.id] ?? 0;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Delete "${category.name}"?'),
        content: Text(count > 0
            ? 'This category has $count active reminders. Deleting it will reassign these reminders to "Other".'
            : 'Are you sure you want to delete this category?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                await context.read<CategoryProvider>().deleteCategory(category.id, reassignToOther: true);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryProvider = context.watch<CategoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
      ),
      body: categoryProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: categoryProvider.categories.length,
              itemBuilder: (context, index) {
                final cat = categoryProvider.categories[index];
                final count = categoryProvider.categoryCounts[cat.id] ?? 0;

                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Color(cat.colorValue).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Category.getIconData(cat.iconKey),
                      color: Color(cat.colorValue),
                    ),
                  ),
                  title: Text(
                    cat.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    cat.isCustom ? 'Custom category' : 'Built-in category',
                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$count',
                          style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (cat.isCustom) ...[
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Edit category',
                          onPressed: () => _showAddEditCategoryDialog(context, category: cat),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          tooltip: 'Delete category',
                          onPressed: () => _handleDeleteCategory(context, cat),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditCategoryDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Category'),
      ),
    );
  }
}
