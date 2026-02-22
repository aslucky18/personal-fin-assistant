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
  late final TextEditingController _totalController;
  late final TextEditingController _paidController;
  late final TextEditingController _interestController;
  String _selectedType = 'loan';
  DateTime? _selectedDate;

  final _liabilityService = LiabilityService();
  final _categoryService = CategoryService();
  bool _isSaving = false;
  bool _isDeleting = false;
  List<Category> _categories = [];
  String? _selectedCategoryId;
  bool _isLoadingCategories = true;

  final List<String> _types = ['loan', 'credit_card', 'mortgage', 'other'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.liability?.name ?? '');
    _totalController = TextEditingController(
      text: widget.liability?.totalAmount.toString() ?? '',
    );
    _paidController = TextEditingController(
      text: widget.liability?.paidAmount.toString() ?? '',
    );
    _interestController = TextEditingController(
      text: widget.liability?.interestRate.toString() ?? '0.0',
    );
    _selectedType = widget.liability?.type ?? 'loan';
    _selectedDate = widget.liability?.dueDate;
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
                    c.name.trim().toLowerCase() != 'salary' &&
                    c.name.trim().toLowerCase() != 'housing rent',
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
    _totalController.dispose();
    _paidController.dispose();
    _interestController.dispose();
    super.dispose();
  }

  Future<void> _saveLiability() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final liability = Liability(
        id: widget.liability?.id ?? '',
        userId: widget.liability?.userId ?? '',
        name: _nameController.text.trim(),
        totalAmount: double.parse(_totalController.text),
        paidAmount: double.parse(_paidController.text),
        interestRate: double.parse(_interestController.text),
        dueDate: _selectedDate,
        type: _selectedType,
        createdAt: widget.liability?.createdAt ?? DateTime.now(),
        categoryId: _selectedCategoryId,
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
      initialDate:
          _selectedDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
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
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _totalController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Total Debt',
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
                      controller: _paidController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Amount Paid',
                        prefixText: '\$ ',
                      ),
                      validator: (val) =>
                          (val == null || double.tryParse(val) == null)
                          ? 'Invalid'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _interestController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Interest Rate',
                  suffixText: '%',
                  prefixIcon: Icon(Icons.percent_rounded),
                ),
                validator: (val) =>
                    (val == null || double.tryParse(val) == null)
                    ? 'Invalid'
                    : null,
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
                        _selectedDate == null
                            ? 'Next Due Date (Optional)'
                            : 'Due Date: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                        style: TextStyle(
                          color: _selectedDate == null
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
