import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../categories/models/category.dart';
import '../../categories/services/category_service.dart';
import '../../goals/models/goal.dart';
import '../../goals/services/goal_service.dart';
import '../../liabilities/models/liability.dart';
import '../../liabilities/services/liability_service.dart';
import '../../accounts/models/account.dart';
import '../../accounts/services/account_service.dart';
import '../../records/models/record.dart';
import '../../records/services/record_service.dart';
import '../models/pending_transaction.dart';
import '../services/pending_transaction_service.dart';

class PendingTransactionsScreen extends StatefulWidget {
  const PendingTransactionsScreen({super.key});

  @override
  State<PendingTransactionsScreen> createState() =>
      _PendingTransactionsScreenState();
}

class _PendingTransactionsScreenState extends State<PendingTransactionsScreen> {
  List<PendingTransaction> _transactions = [];
  List<Category> _categories = [];
  List<FinancialGoal> _goals = [];
  List<Liability> _liabilities = [];
  List<Account> _accounts = [];
  bool _loading = true;
  bool _approving = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        PendingTransactionService.instance.getAll(),
        CategoryService().getCategories(),
        GoalService().getGoals(),
        LiabilityService().getLiabilities(),
        AccountService().getAccounts(),
      ]);
      if (mounted) {
        setState(() {
          _transactions = (results[0] as List<PendingTransaction>)
              .where((t) => t.status == PendingTransactionStatus.pending)
              .toList();
          _categories = results[1] as List<Category>;
          _goals = results[2] as List<FinancialGoal>;
          _liabilities = results[3] as List<Liability>;
          _accounts = results[4] as List<Account>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Approve ──────────────────────────────────────────────────────────────
  Future<void> _approve(PendingTransaction tx) async {
    // Validate required fields
    if (tx.categoryId == null || tx.accountId == null) {
      final filled = await _showEditSheet(tx, mustSave: true);
      if (filled == null) return; // user dismissed
      return _approve(filled);
    }

    setState(() => _approving = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final record = FinancialRecord(
        id: '',
        userId: userId,
        accountId: tx.accountId!,
        categoryId: tx.categoryId!,
        goalId: tx.goalId,
        liabilityId: tx.liabilityId,
        name: tx.merchant,
        amount: tx.amount,
        type: tx.type,
        timestamp: tx.timestamp,
        createdAt: DateTime.now(),
      );
      await RecordService().addRecord(record);
      await PendingTransactionService.instance.remove(tx.id);
      setState(() {
        _transactions.removeWhere((t) => t.id == tx.id);
        _approving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ ₹${tx.amount.toStringAsFixed(0)} recorded successfully',
            ),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      setState(() => _approving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── Reject ───────────────────────────────────────────────────────────────
  Future<void> _reject(PendingTransaction tx) async {
    await PendingTransactionService.instance.remove(tx.id);
    setState(() => _transactions.removeWhere((t) => t.id == tx.id));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Transaction dismissed')));
    }
  }

  // ── Edit sheet ───────────────────────────────────────────────────────────
  Future<PendingTransaction?> _showEditSheet(
    PendingTransaction tx, {
    bool mustSave = false,
  }) async {
    return showModalBottomSheet<PendingTransaction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditSheet(
        tx: tx,
        categories: _categories,
        goals: _goals,
        liabilities: _liabilities,
        accounts: _accounts,
        mustSave: mustSave,
        onSave: (updated) async {
          await PendingTransactionService.instance.update(updated);
          final idx = _transactions.indexWhere((t) => t.id == updated.id);
          if (idx != -1) setState(() => _transactions[idx] = updated);
        },
      ),
    );
  }

  // ── UI ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Transactions'),
        centerTitle: true,
        actions: [
          if (_transactions.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear all',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Clear All?'),
                    content: const Text(
                      'All pending transactions will be dismissed.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Clear',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await PendingTransactionService.instance.clearAll();
                  setState(() => _transactions.clear());
                }
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
          ? _buildEmptyState(theme)
          : Stack(
              children: [
                RefreshIndicator(
                  onRefresh: _loadAll,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _transactions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) =>
                        _buildCard(_transactions[i], cs, theme),
                  ),
                ),
                if (_approving)
                  Container(
                    color: Colors.black26,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mark_email_read_outlined,
            size: 72,
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'All clear!',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No pending transactions to review.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          if (Platform.isAndroid)
            Text(
              'Bank SMS messages will appear here automatically.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCard(PendingTransaction tx, ColorScheme cs, ThemeData theme) {
    final isDebit = tx.type == 'debit';
    final typeColor = isDebit ? Colors.red.shade400 : Colors.green.shade400;
    final typeIcon = isDebit ? Icons.arrow_downward : Icons.arrow_upward;
    final category = _categories
        .where((c) => c.id == tx.categoryId)
        .firstOrNull;
    final goal = _goals.where((g) => g.id == tx.goalId).firstOrNull;
    final liability = _liabilities
        .where((l) => l.id == tx.liabilityId)
        .firstOrNull;
    final account = _accounts.where((a) => a.id == tx.accountId).firstOrNull;

    return Slidable(
      key: ValueKey(tx.id),
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) => _reject(tx),
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
            icon: Icons.close,
            label: 'Reject',
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) => _approve(tx),
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            icon: Icons.check,
            label: 'Approve',
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Row ──────────────────────────────────────────────────
              Row(
                children: [
                  // Amount + type
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(typeIcon, color: typeColor, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '₹${tx.amount.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: typeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Bank sender
                  Text(
                    tx.sender,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: () => _showEditSheet(tx),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // ── Merchant ────────────────────────────────────────────────────
              Row(
                children: [
                  Icon(
                    Icons.store_outlined,
                    size: 16,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      tx.merchant,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (account != null || tx.accountEndsWith != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_outlined,
                      size: 14,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      account != null
                          ? '${account.bankName} ••••${account.endsWith}'
                          : '••••${tx.accountEndsWith}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
              // ── Chips row ───────────────────────────────────────────────────
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (category != null)
                    _chip(
                      context,
                      category.name,
                      Icons.label_outline,
                      cs.primaryContainer,
                      cs.onPrimaryContainer,
                    )
                  else
                    _chip(
                      context,
                      'No category',
                      Icons.label_off_outlined,
                      cs.errorContainer,
                      cs.onErrorContainer,
                    ),
                  if (goal != null)
                    _chip(
                      context,
                      goal.name,
                      Icons.flag_outlined,
                      Colors.blue.shade100,
                      Colors.blue.shade800,
                    ),
                  if (liability != null)
                    _chip(
                      context,
                      liability.name,
                      Icons.credit_card_outlined,
                      Colors.orange.shade100,
                      Colors.orange.shade800,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // ── Date + action buttons ───────────────────────────────────────
              Row(
                children: [
                  Icon(Icons.schedule, size: 12, color: cs.outline),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(tx.timestamp),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.outline,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _reject(tx),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade400,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton.icon(
                    onPressed: () => _approve(tx),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(
    BuildContext context,
    String label,
    IconData icon,
    Color bg,
    Color fg,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year} • ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ── Edit Bottom Sheet ──────────────────────────────────────────────────────────

class _EditSheet extends StatefulWidget {
  final PendingTransaction tx;
  final List<Category> categories;
  final List<FinancialGoal> goals;
  final List<Liability> liabilities;
  final List<Account> accounts;
  final bool mustSave;
  final Future<void> Function(PendingTransaction) onSave;

  const _EditSheet({
    required this.tx,
    required this.categories,
    required this.goals,
    required this.liabilities,
    required this.accounts,
    required this.mustSave,
    required this.onSave,
  });

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late String? _categoryId;
  late String? _goalId;
  late String? _liabilityId;
  late String? _accountId;
  late TextEditingController _merchantCtrl;
  late TextEditingController _amountCtrl;
  late String _type;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.tx.categoryId;
    _goalId = widget.tx.goalId;
    _liabilityId = widget.tx.liabilityId;
    _accountId = widget.tx.accountId;
    _merchantCtrl = TextEditingController(text: widget.tx.merchant);
    _amountCtrl = TextEditingController(
      text: widget.tx.amount.toStringAsFixed(2),
    );
    _type = widget.tx.type;
  }

  @override
  void dispose() {
    _merchantCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  bool get _isExpense => _type == 'debit';

  List<Category> get _filteredCategories => widget.categories.where((c) {
    if (_isExpense) {
      return c.type == Category.fixedExpense ||
          c.type == Category.variableExpense;
    }
    return c.type == Category.fixedIncome || c.type == Category.variableIncome;
  }).toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Edit Transaction',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.all(20),
                children: [
                  // SMS Preview
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Original SMS',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.tx.rawSms,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Type
                  Text('Type', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 6),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'debit',
                        label: Text('Debit'),
                        icon: Icon(Icons.arrow_downward),
                      ),
                      ButtonSegment(
                        value: 'credit',
                        label: Text('Credit'),
                        icon: Icon(Icons.arrow_upward),
                      ),
                    ],
                    selected: {_type},
                    onSelectionChanged: (v) => setState(() => _type = v.first),
                  ),
                  const SizedBox(height: 16),

                  // Merchant
                  Text(
                    'Merchant / Description',
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _merchantCtrl,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Swiggy, Salary...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Amount
                  Text('Amount (₹)', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Account
                  _buildDropdown<Account>(
                    label: 'Account',
                    hint: 'Select account',
                    items: widget.accounts,
                    value: widget.accounts
                        .where((a) => a.id == _accountId)
                        .firstOrNull,
                    displayText: (a) => '${a.bankName} ••••${a.endsWith}',
                    onChanged: (a) => setState(() => _accountId = a?.id),
                    required: widget.mustSave,
                  ),
                  const SizedBox(height: 16),

                  // Category
                  _buildDropdown<Category>(
                    label: 'Category',
                    hint: 'Select category',
                    items: _filteredCategories,
                    value: _filteredCategories
                        .where((c) => c.id == _categoryId)
                        .firstOrNull,
                    displayText: (c) => c.name,
                    onChanged: (c) => setState(() {
                      _categoryId = c?.id;
                      // Reset goal/liability when category changes
                      _goalId = null;
                      _liabilityId = null;
                    }),
                    required: widget.mustSave,
                  ),
                  const SizedBox(height: 16),

                  // Goal
                  _buildDropdown<FinancialGoal>(
                    label: 'Link to Goal (optional)',
                    hint: 'None',
                    items: widget.goals,
                    value: widget.goals
                        .where((g) => g.id == _goalId)
                        .firstOrNull,
                    displayText: (g) => g.name,
                    onChanged: (g) => setState(() => _goalId = g?.id),
                  ),
                  const SizedBox(height: 16),

                  // Liability
                  _buildDropdown<Liability>(
                    label: 'Link to Debt (optional)',
                    hint: 'None',
                    items: widget.liabilities,
                    value: widget.liabilities
                        .where((l) => l.id == _liabilityId)
                        .firstOrNull,
                    displayText: (l) => l.name,
                    onChanged: (l) => setState(() => _liabilityId = l?.id),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            // Save button
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save Changes'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required String hint,
    required List<T> items,
    required T? value,
    required String Function(T) displayText,
    required void Function(T?) onChanged,
    bool required = false,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: theme.textTheme.labelLarge),
            if (required)
              Text(
                ' *',
                style: theme.textTheme.labelLarge?.copyWith(color: Colors.red),
              ),
          ],
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          initialValue: value,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
            errorText: required && value == null ? 'Required' : null,
          ),
          items: [
            if (!required)
              const DropdownMenuItem(value: null, child: Text('None')),
            ...items.map(
              (item) => DropdownMenuItem(
                value: item,
                child: Text(displayText(item), overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }
    if (widget.mustSave && (_categoryId == null || _accountId == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select account and category')),
      );
      return;
    }

    final updated = widget.tx.copyWith(
      merchant: _merchantCtrl.text.trim(),
      amount: amount,
      type: _type,
      categoryId: _categoryId,
      goalId: _goalId,
      liabilityId: _liabilityId,
      accountId: _accountId,
    );
    await widget.onSave(updated);
    if (mounted) Navigator.pop(context, updated);
  }
}
