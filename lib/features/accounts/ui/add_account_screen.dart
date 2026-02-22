import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/bank_branding.dart';
import '../services/account_service.dart';
import '../models/account.dart';

class AddAccountScreen extends StatefulWidget {
  final Account? account;

  const AddAccountScreen({super.key, this.account});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _bankNameController = TextEditingController();
  final _endsWithController = TextEditingController();
  final _accountService = AccountService();
  String _selectedType = 'Savings';
  bool _isLoading = false;

  Color _brandColor = const Color(0xFF6366F1);
  IconData _brandIcon = Icons.account_balance_rounded;

  final List<String> _accountTypes = [
    'Savings',
    'Salary',
    'Current',
    'Credit card',
  ];

  @override
  void initState() {
    super.initState();
    _bankNameController.text = widget.account?.bankName ?? '';
    _endsWithController.text = widget.account?.endsWith ?? '';
    // Convert DB value back to display label when editing
    _selectedType = BankBranding.fromDbType(widget.account?.type ?? 'Savings');
    if (_bankNameController.text.isNotEmpty) {
      _updateBranding(_bankNameController.text);
    }
    _bankNameController.addListener(() {
      _updateBranding(_bankNameController.text);
    });
  }

  void _updateBranding(String bankName) {
    setState(() {
      _brandColor = BankBranding.colorFor(bankName);
      _brandIcon = BankBranding.iconFor(bankName);
    });
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _endsWithController.dispose();
    super.dispose();
  }

  Future<void> _saveAccount() async {
    final bankName = _bankNameController.text.trim();
    final endsWith = _endsWithController.text.trim();

    if (bankName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a bank name')));
      return;
    }
    if (endsWith.isEmpty || endsWith.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter exactly 4 digits')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final account = Account(
        id: widget.account?.id ?? '',
        userId: widget.account?.userId ?? '',
        bankName: bankName,
        type: BankBranding.toDbType(
          _selectedType,
        ), // 'Credit card' → 'CreditCard'
        endsWith: endsWith,
        createdAt: widget.account?.createdAt ?? DateTime.now(),
      );

      if (widget.account == null) {
        await _accountService.addAccount(account);
      } else {
        await _accountService.updateAccount(account);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAccount() async {
    if (widget.account == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete this account? Any transactions linked to this account might be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _accountService.deleteAccount(widget.account!.id);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.account != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Account' : 'New Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              onPressed: _isLoading ? null : _deleteAccount,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: ResponsiveBuilder(
        mobile: _buildForm(context, isDesktop: false, isEditing: isEditing),
        desktop: _buildForm(context, isDesktop: true, isEditing: isEditing),
      ),
    );
  }

  Widget _buildForm(
    BuildContext context, {
    required bool isDesktop,
    required bool isEditing,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 64 : 20,
          vertical: 24,
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dynamic Bank Card Preview
              _buildBankCardPreview(isEditing),
              const SizedBox(height: 32),

              // Form Card
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(15),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Bank Name Field
                    TextField(
                      controller: _bankNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Bank Name',
                        hintText: 'e.g. HDFC, Chase, SBI',
                        prefixIcon: Icon(
                          Icons.comment_bank_rounded,
                          color: _brandColor,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: _brandColor, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Last 4 Digits Field — strictly 4 numeric digits
                    TextField(
                      controller: _endsWithController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Last 4 Digits',
                        hintText: '* * * *',
                        prefixIcon: Icon(
                          Icons.numbers_rounded,
                          color: _brandColor,
                        ),
                        counterText:
                            '${_endsWithController.text.length}/4 digits',
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: _brandColor, width: 2),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 20),

                    // Account Type Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _accountTypes.contains(_selectedType)
                          ? _selectedType
                          : _accountTypes.first,
                      decoration: InputDecoration(
                        labelText: 'Account Type',
                        prefixIcon: Icon(
                          Icons.account_tree_rounded,
                          color: _brandColor,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: _brandColor, width: 2),
                        ),
                      ),
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      items: _accountTypes.map((type) {
                        IconData typeIcon;
                        switch (type) {
                          case 'Credit card':
                            typeIcon = Icons.credit_card_rounded;
                            break;
                          case 'Salary':
                            typeIcon = Icons.payments_rounded;
                            break;
                          case 'Current':
                            typeIcon = Icons.business_center_rounded;
                            break;
                          default:
                            typeIcon = Icons.savings_rounded;
                        }
                        return DropdownMenuItem(
                          value: type,
                          child: Row(
                            children: [
                              Icon(typeIcon, size: 18, color: _brandColor),
                              const SizedBox(width: 12),
                              Text(type),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedType = val);
                        }
                      },
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveAccount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _brandColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(isEditing ? 'Update Account' : 'Link Account'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBankCardPreview(bool isEditing) {
    final bankName = _bankNameController.text.trim();
    final lastDigits = _endsWithController.text.trim();
    final displayName = bankName.isEmpty ? 'Your Bank' : bankName;
    final displayDigits = lastDigits.isEmpty ? '••••' : '•••• $lastDigits';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_brandColor, _brandColor.withAlpha(180)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _brandColor.withAlpha(100),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Icon(_brandIcon, color: Colors.white, size: 32),
              ],
            ),
            const Spacer(),
            Text(
              displayDigits,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedType.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    letterSpacing: 2,
                  ),
                ),
                Icon(
                  _selectedType == 'Credit card'
                      ? Icons.credit_card_rounded
                      : Icons.account_balance_rounded,
                  color: Colors.white70,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
