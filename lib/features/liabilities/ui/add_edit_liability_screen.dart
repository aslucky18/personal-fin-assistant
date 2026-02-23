import 'package:flutter/material.dart';
import '../services/liability_service.dart';
import '../models/liability.dart';
import '../../categories/services/category_service.dart';
import '../../categories/models/category.dart';

class AddEditLiabilityScreen extends StatefulWidget {
  final Liability? liability;

  const AddEditLiabilityScreen({super.key, this.liability});

  @override
  State<AddEditLiabilityScreen> createState() => _AddEditLiabilityScreenState();
}

class _AddEditLiabilityScreenState extends State<AddEditLiabilityScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _monthlyPayableController;
  late final TextEditingController _noOfMonthsController;
  late final TextEditingController _paidMonthsController;
  late final TextEditingController _downPaymentController;
  String _selectedType = 'Loan';
  DateTime? _startDate;

  final _liabilityService = LiabilityService();
  final _categoryService = CategoryService();
  bool _isSaving = false;
  bool _isDeleting = false;
  List<Category> _categories = [];
  String? _selectedCategoryId;
  bool _isLoadingCategories = true;

  final List<String> _types = [
    'Loan',
    'Mortgage',
    'Gold Loan',
    'EMI',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.liability?.name ?? '');
    _monthlyPayableController = TextEditingController(
      text: widget.liability != null && widget.liability!.monthlyPayable > 0
          ? widget.liability!.monthlyPayable.toString()
          : '',
    );
    _noOfMonthsController = TextEditingController(
      text: widget.liability != null && widget.liability!.noOfMonths > 0
          ? widget.liability!.noOfMonths.toString()
          : '',
    );
    _paidMonthsController = TextEditingController(
      text: widget.liability != null && widget.liability!.paidMonths > 0
          ? widget.liability!.paidMonths.toString()
          : '',
    );
    _downPaymentController = TextEditingController(
      text: widget.liability != null && widget.liability!.downPayment > 0
          ? widget.liability!.downPayment.toString()
          : '',
    );
    _selectedType = widget.liability?.type ?? 'Loan';
    _startDate = widget.liability?.startDate ?? DateTime.now();
    _selectedCategoryId = widget.liability?.categoryId;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryService.getCategories();
      if (mounted) {
        setState(() {
          _categories = categories
              .where(
                (c) =>
                    c.type == Category.fixedExpense &&
                    c.subCategory == 'Debt Related',
              )
              .toList();
          _isLoadingCategories = false;

          // Ensure valid selected category
          if (_selectedCategoryId != null &&
              !_categories.any((c) => c.id == _selectedCategoryId)) {
            _selectedCategoryId = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCategories = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _monthlyPayableController.dispose();
    _noOfMonthsController.dispose();
    _paidMonthsController.dispose();
    _downPaymentController.dispose();
    super.dispose();
  }

  Future<void> _saveLiability() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final monthlyPayable =
          double.tryParse(_monthlyPayableController.text) ?? 0.0;
      final noOfMonths = int.tryParse(_noOfMonthsController.text) ?? 0;
      final paidMonths = int.tryParse(_paidMonthsController.text) ?? 0;

      final isEmi = _selectedType == 'EMI';
      final downPayment = isEmi
          ? (double.tryParse(_downPaymentController.text) ?? 0.0)
          : 0.0;

      final totalAmount = isEmi
          ? downPayment + (monthlyPayable * noOfMonths)
          : monthlyPayable * noOfMonths;

      final paidAmount = isEmi
          ? downPayment + (paidMonths * monthlyPayable)
          : widget.liability?.paidAmount ?? 0.0;

      final liability = Liability(
        id: widget.liability?.id ?? '',
        userId: widget.liability?.userId ?? '',
        name: _nameController.text.trim(),
        totalAmount: totalAmount,
        paidAmount: paidAmount,
        interestRate: 0.0,
        dueDate: _startDate != null
            ? DateTime(
                _startDate!.year,
                _startDate!.month + noOfMonths,
                _startDate!.day,
              )
            : null,
        type: _selectedType,
        createdAt: widget.liability?.createdAt ?? DateTime.now(),
        categoryId: _selectedCategoryId,
        monthlyPayable: monthlyPayable,
        noOfMonths: noOfMonths,
        paidMonths: paidMonths,
        downPayment: downPayment,
        startDate: _startDate,
      );

      if (widget.liability == null) {
        await _liabilityService.addLiability(liability);
      } else {
        await _liabilityService.updateLiability(liability);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save liability: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteLiability() async {
    if (widget.liability == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Liability'),
        content: const Text('Are you sure you want to delete this liability?'),
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

    setState(() => _isDeleting = true);
    try {
      await _liabilityService.deleteLiability(widget.liability!.id);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete liability: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() => _startDate = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.liability != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Liability' : 'Add Liability'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              onPressed: _isDeleting ? null : _deleteLiability,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Debt Name',
                  hintText: 'e.g. Student Loan, Car Loan',
                  prefixIcon: Icon(Icons.description_rounded),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 24),
              if (_isLoadingCategories)
                const LinearProgressIndicator()
              else
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category_rounded),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category.id,
                      child: Row(
                        children: [
                          Icon(
                            Icons.circle,
                            color: Color(
                              int.parse(
                                category.colour.replaceFirst('#', '0xFF'),
                              ),
                            ),
                            size: 12,
                          ),
                          const SizedBox(width: 8),
                          Text(category.name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedCategoryId = val);
                  },
                  validator: (val) =>
                      val == null ? 'Please select a category' : null,
                ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Debt Type',
                  prefixIcon: Icon(Icons.category_rounded),
                ),
                items: _types
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedType = val);
                },
              ),
              const SizedBox(height: 24),
              if (_selectedType == 'EMI') ...[
                TextFormField(
                  controller: _downPaymentController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Down Payment',
                    prefixText: '\$ ',
                    hintText: 'Initial payment amount',
                  ),
                  validator: (val) {
                    if (val != null &&
                        val.isNotEmpty &&
                        double.tryParse(val) == null) {
                      return 'Invalid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
              ],
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _monthlyPayableController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Monthly Payable',
                        prefixText: '\$ ',
                      ),
                      validator: (val) =>
                          (val == null || double.tryParse(val) == null)
                          ? 'Invalid'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _noOfMonthsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'No. of Months',
                      ),
                      validator: (val) =>
                          (val == null || int.tryParse(val) == null)
                          ? 'Invalid'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _paidMonthsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'No. of Months Paid',
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return null; // Optional
                        if (int.tryParse(val) == null) return 'Invalid';
                        final paid = int.tryParse(val)!;
                        final total =
                            int.tryParse(_noOfMonthsController.text) ?? 0;
                        if (paid > total && total > 0) return 'Exceeds total';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: const SizedBox(),
                  ), // Empty space for alignment
                ],
              ),
              const SizedBox(height: 24),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        _startDate == null
                            ? 'Start Date'
                            : 'Start Date: ${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
                        style: TextStyle(
                          color: _startDate == null
                              ? Theme.of(
                                  context,
                                ).colorScheme.onSurface.withAlpha(150)
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveLiability,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditing ? 'Update Liability' : 'Add Liability'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
