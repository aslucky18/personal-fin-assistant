import 'package:flutter/material.dart';
import 'package:finanalyzer/core/theme/app_theme.dart';
import 'package:finanalyzer/core/utils/responsive.dart';
import 'package:finanalyzer/features/records/services/record_service.dart';
import 'package:finanalyzer/features/records/models/record.dart';
import 'package:finanalyzer/features/accounts/services/account_service.dart';
import 'package:finanalyzer/features/accounts/models/account.dart';
import 'package:finanalyzer/features/categories/services/category_service.dart';
import 'package:finanalyzer/features/categories/models/category.dart';

class AddRecordScreen extends StatefulWidget {
  const AddRecordScreen({super.key});

  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  String _selectedType = 'expense';
  final _recordService = RecordService();
  final _accountService = AccountService();
  final _categoryService = CategoryService();

  List<Account> _accounts = [];
  List<Category> _categories = [];

  String? _selectedAccountId;
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  bool _isLoadingData = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final accounts = await _accountService.getAccounts();
      final categories = await _categoryService.getCategories();
      if (mounted) {
        setState(() {
          _accounts = accounts;
          _categories = categories;
          if (_accounts.isNotEmpty) _selectedAccountId = _accounts.first.id;
          if (_categories.isNotEmpty) {
            _selectedCategoryId = _categories.first.id;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load data: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _saveRecord() async {
    if (_amountController.text.isEmpty || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount and title.')),
      );
      return;
    }
    if (_selectedAccountId == null || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select account and category.')),
      );
      return;
    }

    final amountStr = _amountController.text.replaceAll(',', '');
    final amount = double.tryParse(amountStr);
    if (amount == null) return;

    setState(() => _isSaving = true);

    try {
      final record = FinancialRecord(
        id: '',
        userId: '',
        accountId: _selectedAccountId!,
        categoryId: _selectedCategoryId!,
        name: _titleController.text.trim(),
        amount: amount,
        type: _selectedType == 'expense' ? 'debit' : 'credit',
        timestamp: _selectedDate,
        createdAt: DateTime.now(),
      );

      await _recordService.addRecord(record);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save record: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primary,
              surface: AppTheme.surface,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Record'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : ResponsiveBuilder(
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
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withAlpha(20), width: 1),
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
              // Type Switch
              Row(
                children: [
                  Expanded(
                    child: _buildTypeButton(
                      'Expense',
                      'expense',
                      AppTheme.error,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTypeButton(
                      'Income',
                      'income',
                      AppTheme.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Amount Field (Large)
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '0.00',
                  hintStyle: TextStyle(
                    fontSize: 48,
                    color: AppTheme.textSecondary.withAlpha(100),
                  ),
                  prefixText: '\$ ',
                  prefixStyle: const TextStyle(
                    fontSize: 48,
                    color: AppTheme.textSecondary,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title / Description',
                  hintText: 'e.g. Starbucks Coffee',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 24),

              // Category & Account
              if (isDesktop)
                Row(
                  children: [
                    Expanded(child: _buildCategoryDropdown()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildAccountDropdown()),
                  ],
                )
              else
                Column(
                  children: [
                    _buildCategoryDropdown(),
                    const SizedBox(height: 24),
                    _buildAccountDropdown(),
                  ],
                ),
              const SizedBox(height: 24),

              // Date Picker
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_rounded,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),

              ElevatedButton(
                onPressed: _isSaving ? null : _saveRecord,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save Record'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(String label, String value, Color color) {
    final isSelected = _selectedType == value;
    return InkWell(
      onTap: () {
        setState(() => _selectedType = value);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(40) : AppTheme.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.white.withAlpha(20),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? color : AppTheme.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCategoryId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Category',
        prefixIcon: Icon(Icons.category_rounded),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      ),
      dropdownColor: AppTheme.surface,
      items: _categories
          .map(
            (c) => DropdownMenuItem(
              value: c.id,
              child: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (val) {
        if (val != null) setState(() => _selectedCategoryId = val);
      },
    );
  }

  Widget _buildAccountDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedAccountId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Account',
        prefixIcon: Icon(Icons.account_balance_wallet_rounded),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      ),
      dropdownColor: AppTheme.surface,
      items: _accounts
          .map(
            (a) => DropdownMenuItem(
              value: a.id,
              child: Text(
                '${a.bankName} (...${a.endsWith})',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (val) {
        if (val != null) setState(() => _selectedAccountId = val);
      },
    );
  }
}
