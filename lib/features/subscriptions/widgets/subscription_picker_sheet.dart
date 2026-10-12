import 'package:flutter/material.dart';
import '../models/subscription_brand.dart';
import 'brand_logo.dart';

/// Result returned from the picker.
///
/// Either a predefined [brand] or a custom name via [customName] (Other).
class SubscriptionPickerResult {
  final SubscriptionBrand? brand;
  final String? customName;

  const SubscriptionPickerResult.predefined(this.brand) : customName = null;
  const SubscriptionPickerResult.custom(this.customName) : brand = null;
}

/// A searchable, animated bottom sheet for choosing a subscription service (§1).
///
/// Shows recognizable brand logos with a live search filter, plus an "Other"
/// entry that reveals an inline custom-name field.
class SubscriptionPickerSheet extends StatefulWidget {
  const SubscriptionPickerSheet({super.key});

  /// Opens the picker and returns the user's selection, or null if dismissed.
  static Future<SubscriptionPickerResult?> show(BuildContext context) {
    return showModalBottomSheet<SubscriptionPickerResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SubscriptionPickerSheet(),
    );
  }

  @override
  State<SubscriptionPickerSheet> createState() => _SubscriptionPickerSheetState();
}

class _SubscriptionPickerSheetState extends State<SubscriptionPickerSheet> {
  final _searchController = TextEditingController();
  final _customController = TextEditingController();
  String _query = '';
  bool _showCustom = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customController.dispose();
    super.dispose();
  }

  List<SubscriptionBrand> get _filtered {
    if (_query.isEmpty) return SubscriptionBrand.catalog;
    return SubscriptionBrand.catalog
        .where((b) => b.name.toLowerCase().contains(_query) || b.category.toLowerCase().contains(_query))
        .toList();
  }

  void _selectBrand(SubscriptionBrand brand) {
    Navigator.pop(context, SubscriptionPickerResult.predefined(brand));
  }

  void _submitCustom() {
    final name = _customController.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(context, SubscriptionPickerResult.custom(name));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final duration = reduceMotion ? Duration.zero : const Duration(milliseconds: 200);
    final filtered = _filtered;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Choose a service',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search services',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // "Other" option
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_showCustom ? Icons.expand_less : Icons.more_horiz, color: theme.colorScheme.primary),
                ),
                title: const Text('Other'),
                subtitle: const Text('Enter a custom name'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => setState(() => _showCustom = !_showCustom),
              ),
            ),

            // Inline custom name field (animated reveal)
            AnimatedSize(
              duration: duration,
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _showCustom
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _customController,
                              autofocus: true,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _submitCustom(),
                              decoration: InputDecoration(
                                hintText: 'Subscription name',
                                labelText: 'Custom name',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: _submitCustom,
                            style: FilledButton.styleFrom(minimumSize: const Size(56, 56)),
                            child: const Icon(Icons.check),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),

            const Divider(height: 1),


            // Results list
            Flexible(
              child: filtered.isEmpty ? _buildEmptyResults(theme) : _buildResults(filtered),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(List<SubscriptionBrand> filtered) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final brand = filtered[index];
        return _BrandRow(brand: brand, onTap: () => _selectBrand(brand));
      },
    );
  }

  Widget _buildEmptyResults(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 40, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text('No services match "$_query".',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text('Use "Other" to add it manually.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _BrandRow extends StatefulWidget {
  final SubscriptionBrand brand;
  final VoidCallback onTap;

  const _BrandRow({required this.brand, required this.onTap});

  @override
  State<_BrandRow> createState() => _BrandRowState();
}

class _BrandRowState extends State<_BrandRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: widget.onTap,
      onHighlightChanged: (v) => setState(() => _pressed = v),
      child: AnimatedContainer(
        duration: MediaQuery.of(context).disableAnimations ? Duration.zero : const Duration(milliseconds: 150),
        color: _pressed ? theme.colorScheme.primary.withValues(alpha: 0.08) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            BrandLogo(brand: widget.brand, size: 44),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.brand.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.brand.category,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

