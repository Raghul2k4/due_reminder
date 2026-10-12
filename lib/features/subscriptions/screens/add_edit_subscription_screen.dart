import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../app/providers/subscription_provider.dart';
import '../../../core/utils/subscription_recurrence.dart';
import '../../../data/models/subscription.dart';
import '../../../data/models/subscription_enums.dart';
import '../models/subscription_brand.dart';
import '../widgets/brand_logo.dart';
import '../widgets/subscription_picker_sheet.dart';

/// Full-screen form to create or edit a subscription (§1, §5).
class AddEditSubscriptionScreen extends StatefulWidget {
  final Subscription? subscription;

  const AddEditSubscriptionScreen({super.key, this.subscription});

  @override
  State<AddEditSubscriptionScreen> createState() => _AddEditSubscriptionScreenState();
}

class _AddEditSubscriptionScreenState extends State<AddEditSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  static const List<String> _currencies = ['USD', 'EUR', 'GBP', 'INR', 'JPY', 'AUD', 'CAD'];

  // Selected predefined service, or null when a custom ("Other") name is used.
  SubscriptionBrand? _selectedBrand;

  late String _currency;
  late BillingCycle _billingCycle;
  late DateTime _nextRenewalDate;
  late bool _reminderEnabled;
  late SubscriptionReminderLead _reminderLead;
  late SubscriptionStatus _status;
  bool _isDirty = false;

  bool get _isEdit => widget.subscription != null;

  @override
  void initState() {
    super.initState();
    final s = widget.subscription;
    if (s != null) {
      _nameController.text = s.name;
      _priceController.text = s.price.toStringAsFixed(2);
      _notesController.text = s.notes ?? '';
      _currency = s.currency;
      _billingCycle = s.billingCycle;
      _nextRenewalDate = s.nextRenewalDate;
      _reminderEnabled = s.reminderEnabled;
      _reminderLead = s.reminderLead;
      _status = s.status;
      // Match an existing name to a predefined service so its logo shows on edit.
      _selectedBrand = SubscriptionBrand.byName(s.name);
    } else {
      _currency = 'USD';
      _billingCycle = BillingCycle.monthly;
      final now = DateTime.now();
      _nextRenewalDate = DateTime(now.year, now.month, now.day).add(const Duration(days: 30));
      _reminderEnabled = true;
      _reminderLead = SubscriptionReminderLead.oneDay;
      _status = SubscriptionStatus.active;
    }

    _nameController.addListener(_markDirty);
    _priceController.addListener(_markDirty);
    _notesController.addListener(_markDirty);
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double? get _parsedPrice => double.tryParse(_priceController.text.trim());

  Future<bool> _onWillPop() async {
    if (!_isDirty) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard unsaved changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextRenewalDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _nextRenewalDate = DateTime(picked.year, picked.month, picked.day);
        _markDirty();
      });
    }
  }

  /// Opens the branded service picker (§1). Selecting a service fills the name;
  /// choosing "Other" switches to the custom-name path.
  Future<void> _openPicker() async {
    final result = await SubscriptionPickerSheet.show(context);
    if (result == null || !mounted) return;

    setState(() {
      if (result.brand != null) {
        _selectedBrand = result.brand;
        _nameController.text = result.brand!.name;
      } else {
        // Custom name: reveal manual entry, seed with any typed text.
        _selectedBrand = null;
        _nameController.text = result.customName ?? _nameController.text;
      }
    });
    _markDirty();
  }

  /// Called when the custom name field changes. Typing keeps us on the custom
  /// path so the manually entered name is preserved while editing other fields.
  /// The controller already holds the new text, so only the brand selection
  /// needs clearing — writing back to the controller here would reset the
  /// cursor on every keystroke.
  void _onCustomNameChanged(String value) {
    if (_selectedBrand != null) {
      // User started editing a predefined name manually: treat as custom.
      setState(() => _selectedBrand = null);
    }
    _markDirty();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final nameValid = name.isNotEmpty;

    if (!nameValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose or enter a subscription name.')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final price = _parsedPrice ?? 0;
    final notes = _notesController.text.trim();
    final provider = context.read<SubscriptionProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final base = _isEdit
        ? widget.subscription!
        : Subscription(
            id: '',
            name: name,
            price: price,
            currency: _currency,
            billingCycle: _billingCycle,
            nextRenewalDate: _nextRenewalDate,
            status: _status,
            reminderEnabled: _reminderEnabled,
            reminderLead: _reminderLead,
            createdAt: DateTime.now(),
            notificationId: 0,
          );

    final subscription = base.copyWith(
      name: name,
      price: price,
      currency: _currency,
      billingCycle: _billingCycle,
      nextRenewalDate: _nextRenewalDate,
      status: _status,
      reminderEnabled: _reminderEnabled,
      reminderLead: _reminderLead,
      notes: notes,
      clearNotes: notes.isEmpty,
    );

    try {
      if (_isEdit) {
        await provider.updateSubscription(subscription);
      } else {
        await provider.createSubscription(subscription);
      }
      if (mounted) navigator.pop();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Couldn\'t save — ${e.toString()}')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final previews = upcomingRenewals(
      anchor: _nextRenewalDate,
      from: _nextRenewalDate.add(const Duration(seconds: -1)),
      cycle: _billingCycle,
      count: 3,
    );

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final allow = await _onWillPop();
        if (allow && mounted) navigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEdit ? 'Edit subscription' : 'New subscription'),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              // ---- Service picker / custom name ----
              _buildServiceSelector(theme),
              const SizedBox(height: 20),

              // ---- Price + currency ----
              _buildPriceRow(theme),
              const SizedBox(height: 20),

              // ---- Billing cycle ----
              _buildBillingCycle(theme),
              const SizedBox(height: 20),

              // ---- Next renewal date ----
              _buildRenewalDate(theme, previews),
              const SizedBox(height: 16),
              const Divider(),

              // ---- Reminder ----
              _buildReminderSection(theme),
              const Divider(),

              // ---- Status ----
              _buildStatusSection(theme),
              const SizedBox(height: 16),

              // ---- Notes ----
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'e.g. family plan, card ending 1234',
                ),
                maxLines: 3,
                maxLength: 500,
              ),
              const SizedBox(height: 16),

              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: Text(_isEdit ? 'Save changes' : 'Add subscription'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              ),
            ],
          ),
        ),
      ),
    );
  }


  /// Service picker field. When a predefined service is selected it shows its
  /// logo and name (read-only, tap to change). On the custom path it reveals an
  /// animated manual text input (§1, §5).
  Widget _buildServiceSelector(ThemeData theme) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Service', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeOutCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation,
                alignment: Alignment.topCenter,
                child: child,
              ),
            );
          },
          child: _selectedBrand != null
              // Selected predefined service (read-only display + change button)
              ? InkWell(
                  key: const ValueKey('selected'),
                  borderRadius: BorderRadius.circular(14),
                  onTap: _openPicker,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        BrandLogo(brand: _selectedBrand!, size: 44),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_selectedBrand!.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(_selectedBrand!.category,
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        TextButton(onPressed: _openPicker, child: const Text('Change')),
                      ],
                    ),
                  ),
                )
              // Custom name entry
              : TextFormField(
                  key: const ValueKey('custom'),
                  controller: _nameController,
                  autofocus: !_isEdit,
                  decoration: InputDecoration(
                    labelText: 'Subscription name *',
                    hintText: 'e.g. Netflix, gym membership',
                    prefixIcon: const Icon(Icons.subscriptions_outlined),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.apps_outlined),
                      tooltip: 'Pick from list',
                      onPressed: _openPicker,
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  maxLength: 100,
                  textInputAction: TextInputAction.next,
                  onChanged: _onCustomNameChanged,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Name is required';
                    }
                    if (val.trim().toLowerCase() == 'other') {
                      return 'Please enter a real name';
                    }
                    return null;
                  },
                ),
        ),

        // Helper row to switch between list and manual entry.
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _openPicker,
            icon: const Icon(Icons.search, size: 18),
            label: Text(_selectedBrand != null ? 'Choose a different service' : 'Pick a known service'),
          ),
        ),
      ],
    );
  }


  /// Price + currency, aligned to equal heights with consistent radii (§3).
  Widget _buildPriceRow(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 56,
            child: TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price *',
                hintText: '0.00',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              validator: (val) {
                final text = val?.trim() ?? '';
                if (text.isEmpty) return 'Price is required';
                final value = double.tryParse(text);
                if (value == null) return 'Enter a valid number';
                if (value < 0) return 'Price cannot be negative';
                return null;
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 56,
            child: DropdownButtonFormField<String>(
              initialValue: _currency,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Currency'),
              items: _currencies.map((c) {
                return DropdownMenuItem(value: c, child: Text(c));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _currency = val;
                    _markDirty();
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Billing cycle as four evenly distributed, single-line chips (§3).
  ///
  /// A hand-built row of [Expanded] chips guarantees each label stays on one
  /// line and the four options share the width equally, avoiding the clipping
  /// and wrapping a default [SegmentedButton] can hit on narrow screens.
  Widget _buildBillingCycle(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Billing cycle', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: BillingCycle.values.map((cycle) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: cycle == BillingCycle.values.last ? 0 : 6,
                ),
                child: _BillingCycleChip(
                  cycle: cycle,
                  selected: cycle == _billingCycle,
                  onTap: () {
                    setState(() {
                      _billingCycle = cycle;
                      _markDirty();
                    });
                  },
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Renewal date row + live preview of the next renewals (§3).
  Widget _buildRenewalDate(ThemeData theme, List<DateTime> previews) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Next renewal date', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _pickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.event, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    DateFormat('EEEE, d MMM yyyy').format(_nextRenewalDate),
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.preview, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Next renewals',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                previews.map((d) => DateFormat('d MMM yyyy').format(d)).join('  ·  '),
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildReminderSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reminder', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Remind me before renewal'),
          subtitle: const Text('Get a local notification ahead of the charge'),
          value: _reminderEnabled,
          onChanged: (val) {
            setState(() {
              _reminderEnabled = val;
              _markDirty();
            });
          },
        ),
        AnimatedSize(
          duration: MediaQuery.of(context).disableAnimations ? Duration.zero : const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _reminderEnabled
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: DropdownButtonFormField<SubscriptionReminderLead>(
                    initialValue: _reminderLead,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Reminder lead time',
                      prefixIcon: Icon(Icons.schedule),
                    ),
                    items: SubscriptionReminderLead.values.map((lead) {
                      return DropdownMenuItem(
                        value: lead,
                        child: Text(lead.displayName, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _reminderLead = val;
                          _markDirty();
                        });
                      }
                    },
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  Widget _buildStatusSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Status', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: SubscriptionStatus.values.map((status) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: status == SubscriptionStatus.values.last ? 0 : 8),
                child: _StatusChip(
                  status: status,
                  selected: status == _status,
                  onTap: () {
                    setState(() {
                      _status = status;
                      _markDirty();
                    });
                  },
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}


/// A single-line billing-cycle chip with an animated selected state (§3, §5).
class _BillingCycleChip extends StatelessWidget {
  final BillingCycle cycle;
  final bool selected;
  final VoidCallback onTap;

  const _BillingCycleChip({required this.cycle, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: 48,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              cycle.displayName,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                color: selected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A single-line status chip with an animated selected state (§3, §5).
class _StatusChip extends StatelessWidget {
  final SubscriptionStatus status;
  final bool selected;
  final VoidCallback onTap;

  const _StatusChip({required this.status, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: 48,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              status.displayName,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                color: selected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

