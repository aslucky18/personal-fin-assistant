import 'package:flutter/material.dart';
import '../services/goal_service.dart';
import '../models/goal.dart';
import '../../categories/services/category_service.dart';
import '../../categories/models/category.dart';

class AddEditGoalScreen extends StatefulWidget {
  final FinancialGoal? goal;

  const AddEditGoalScreen({super.key, this.goal});

  @override
  State<AddEditGoalScreen> createState() => _AddEditGoalScreenState();
}

class _AddEditGoalScreenState extends State<AddEditGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _targetController;
  late final TextEditingController _currentController;
  DateTime? _selectedDate;

  bool _isChit = false;
  late final TextEditingController _monthlyController;
  late final TextEditingController _durationController;

  final _goalService = GoalService();
  final _categoryService = CategoryService();
  bool _isSaving = false;
  bool _isDeleting = false;
  List<Category> _categories = [];
  String? _selectedCategoryId;
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.goal?.name ?? '');
    _targetController = TextEditingController(
      text: widget.goal?.targetAmount.toString() ?? '',
    );
    _currentController = TextEditingController(
      text: widget.goal?.currentAmount.toString() ?? '',
    );
    _selectedDate = widget.goal?.deadline;
    _isChit = widget.goal?.isChit ?? false;
    _monthlyController = TextEditingController(
      text: widget.goal?.monthlyContribution.toString() ?? '',
    );
    _durationController = TextEditingController(
      text: widget.goal?.durationMonths.toString() ?? '',
    );
    _selectedCategoryId = widget.goal?.categoryId;
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
    _targetController.dispose();
    _currentController.dispose();
    _monthlyController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _calculateTarget() {
    if (_isChit) {
      final monthly = double.tryParse(_monthlyController.text) ?? 0;
      final duration = int.tryParse(_durationController.text) ?? 0;
      if (monthly > 0 && duration > 0) {
        _targetController.text = (monthly * duration).toStringAsFixed(2);
        if (_selectedDate == null) {
          final now = DateTime.now();
          _selectedDate = DateTime(now.year, now.month + duration, now.day);
        }
      }
    }
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final goal = FinancialGoal(
        id: widget.goal?.id ?? '',
        userId: widget.goal?.userId ?? '',
        name: _nameController.text.trim(),
        targetAmount: double.parse(_targetController.text),
        currentAmount: double.parse(_currentController.text),
        deadline: _selectedDate,
        icon: 'flag',
        colour: '#2196F3',
        createdAt: widget.goal?.createdAt ?? DateTime.now(),
        isChit: _isChit,
        monthlyContribution: double.tryParse(_monthlyController.text) ?? 0,
        durationMonths: int.tryParse(_durationController.text) ?? 0,
        startDate: _isChit ? DateTime.now() : null,
        categoryId: _selectedCategoryId,
      );

      if (widget.goal == null) {
        await _goalService.addGoal(goal);
      } else {
        await _goalService.updateGoal(goal);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save goal: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteGoal() async {
    if (widget.goal == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: const Text('Are you sure you want to delete this goal?'),
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
      await _goalService.deleteGoal(widget.goal!.id);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete goal: $e')));
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
    final isEditing = widget.goal != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Goal' : 'Add Goal'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              onPressed: _isDeleting ? null : _deleteGoal,
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
                  labelText: 'Goal Name',
                  hintText: 'e.g. New Car, Vacation',
                  prefixIcon: Icon(Icons.flag_rounded),
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
              SwitchListTile(
                title: const Text('Chit Scheme'),
                subtitle: const Text('Regular monthly contribution scheme'),
                value: _isChit,
                onChanged: (val) {
                  setState(() {
                    _isChit = val;
                    if (_isChit) {
                      _calculateTarget();
                    }
                  });
                },
                secondary: const Icon(Icons.auto_graph_rounded),
              ),
              const SizedBox(height: 16),
              if (_isChit) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _monthlyController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Monthly Amt',
                          prefixText: '\$ ',
                        ),
                        onChanged: (_) => _calculateTarget(),
                        validator: (val) =>
                            _isChit && (val == null || val.isEmpty)
                            ? 'Required'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _durationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Months'),
                        onChanged: (_) => _calculateTarget(),
                        validator: (val) =>
                            _isChit && (val == null || val.isEmpty)
                            ? 'Required'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
              TextFormField(
                controller: _targetController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                readOnly: _isChit,
                decoration: InputDecoration(
                  labelText: 'Target Amount',
                  prefixText: '\$ ',
                  prefixIcon: const Icon(Icons.ads_click_rounded),
                  suffixIcon: _isChit
                      ? IconButton(
                          icon: const Icon(Icons.info_outline),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Target is auto-calculated for Chit schemes',
                                ),
                              ),
                            );
                          },
                        )
                      : null,
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Please enter target';
                  if (double.tryParse(val) == null) return 'Invalid amount';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _currentController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Current Savings',
                  prefixText: '\$ ',
                  prefixIcon: Icon(Icons.savings_rounded),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Please enter current amount';
                  }
                  if (double.tryParse(val) == null) return 'Invalid amount';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              InkWell(
                onTap: _isChit ? null : _pickDate,
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
                  child: Opacity(
                    opacity: _isChit ? 0.6 : 1.0,
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          _selectedDate == null
                              ? 'Set Deadline (Optional)'
                              : 'Deadline: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
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
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveGoal,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditing ? 'Update Goal' : 'Create Goal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
