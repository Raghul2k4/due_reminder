import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../app/providers/subscription_provider.dart';
import '../../../core/utils/subscription_recurrence.dart';
import '../../../data/models/subscription.dart';
import '../../../data/models/subscription_enums.dart';

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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
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
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  hintText: 'e.g. Netflix, Spotify, gym membership',
                  prefixIcon: Icon(Icons.subscriptions_outlined),
                ),
                maxLength: 100,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Price + currency
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _currency,
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
                ],
              ),
              const SizedBox(height: 16),

              // Billing cycle
              Text('Billing cycle', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<BillingCycle>(
                segments: const [
                  ButtonSegment(value: BillingCycle.weekly, label: Text('Weekly')),
                  ButtonSegment(value: BillingCycle.monthly, label: Text('Monthly')),
                  ButtonSegment(value: BillingCycle.quarterly, label: Text('Quarterly')),
                  ButtonSegment(value: BillingCycle.yearly, label: Text('Yearly')),
                ],
                selected: {_billingCycle},
                onSelectionChanged: (set) {
                  setState(() {
                    _billingCycle = set.first;
                    _markDirty();
                  });
                },
              ),
              const SizedBox(height: 16),


              // Next renewal date
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: const Text('Next renewal date'),
                subtitle: Text(DateFormat('EEEE, d MMM yyyy').format(_nextRenewalDate)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickDate,
              ),

              // Live preview of next renewals
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
              const SizedBox(height: 16),

              const Divider(),
              Text('Reminder', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
              if (_reminderEnabled)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: DropdownButtonFormField<SubscriptionReminderLead>(
                    initialValue: _reminderLead,
                    decoration: const InputDecoration(
                      labelText: 'Reminder lead time',
                      prefixIcon: Icon(Icons.schedule),
                    ),
                    items: SubscriptionReminderLead.values.map((lead) {
                      return DropdownMenuItem(value: lead, child: Text(lead.displayName));
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
                ),
              const Divider(),

              // Status
              Text('Status', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<SubscriptionStatus>(
                segments: const [
                  ButtonSegment(value: SubscriptionStatus.active, label: Text('Active')),
                  ButtonSegment(value: SubscriptionStatus.paused, label: Text('Paused')),
                  ButtonSegment(value: SubscriptionStatus.cancelled, label: Text('Cancelled')),
                ],
                selected: {_status},
                onSelectionChanged: (set) {
                  setState(() {
                    _status = set.first;
                    _markDirty();
                  });
                },
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'e.g. family plan, card ending 1234',
                ),
                maxLines: 3,
                maxLength: 500,
              ),
              const SizedBox(height: 12),

              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: Text(_isEdit ? 'Save changes' : 'Add subscription'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

