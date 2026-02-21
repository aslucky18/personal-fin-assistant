import 'package:flutter/material.dart';

import 'package:finanalyzer/core/utils/responsive.dart';
import 'package:finanalyzer/features/accounts/services/account_service.dart';
import 'package:finanalyzer/features/accounts/models/account.dart';

class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _bankNameController = TextEditingController();
  final _endsWithController = TextEditingController();
  final _accountService = AccountService();
  String _selectedType = 'Savings';
  bool _isLoading = false;

  final List<String> _accountTypes = [
    'Savings',
    'Salary',
    'Current',
    'CreditCard',
  ];

  @override
  void dispose() {
    _bankNameController.dispose();
    _endsWithController.dispose();
    super.dispose();
  }

  Future<void> _saveAccount() async {
    final bankName = _bankNameController.text.trim();
    final endsWith = _endsWithController.text.trim();

    if (bankName.isEmpty || endsWith.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final account = Account(
        id: '',
        userId: '',
        bankName: bankName,
        type: _selectedType,
        endsWith: endsWith,
        createdAt: DateTime.now(),
      );

      await _accountService.addAccount(account);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ResponsiveBuilder(
        mobile: _buildForm(context, isDesktop: false),
        desktop: _buildForm(context, isDesktop: true),
      ),
    );
  }

  Widget _buildForm(BuildContext context, {required bool isDesktop}) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 64 : 24,
          vertical: 24,
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(20),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(40),
                blurRadius: 40,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.account_balance_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              const Text(
                'Link a new Account',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Add your bank details so you can track records associated with it.',
                style: TextStyle(
                  color:
                      Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withAlpha(180) ??
                      Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Bank Name Field
              TextField(
                controller: _bankNameController,
                decoration: const InputDecoration(
                  labelText: 'Bank Name',
                  hintText: 'e.g. Axis Bank, Chase, HDFC',
                  prefixIcon: Icon(Icons.comment_bank_rounded),
                ),
              ),
              const SizedBox(height: 24),

              // Last 4 digits Field
              TextField(
                controller: _endsWithController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(
                  labelText: 'Last 4 Digits',
                  hintText: 'e.g. 1234',
                  prefixIcon: Icon(Icons.numbers_rounded),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 24),

              // Account Type segmented button or dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Account Type',
                  prefixIcon: Icon(Icons.account_tree_rounded),
                ),
                dropdownColor: Theme.of(context).colorScheme.surface,
                items: _accountTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedType = val);
                  }
                },
              ),

              const SizedBox(height: 48),

              ElevatedButton(
                onPressed: _isLoading ? null : _saveAccount,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      )
                    : const Text('Save Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
