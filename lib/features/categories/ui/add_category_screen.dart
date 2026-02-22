import 'package:flutter/material.dart';

import '../../../core/utils/responsive.dart';
import '../services/category_service.dart';
import '../models/category.dart';
import '../../../core/utils/icon_color_mapper.dart';

class AddCategoryScreen extends StatefulWidget {
  final Category? category;

  const AddCategoryScreen({super.key, this.category});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _nameController = TextEditingController();
  final _subCategoryController = TextEditingController();
  final _categoryService = CategoryService();
  String _selectedNature = 'fixed';
  String _selectedClass = 'expense';
  Color _selectedColor = const Color(0xFFFF6B35);
  IconData _selectedIcon = Icons.category_rounded;
  bool _isLoading = false;

  final List<Color> _colorOptions = [
    const Color(0xFFFF6B35),
    const Color(0xFF4CAF50),
    const Color(0xFF2196F3),
    const Color(0xFFF44336),
    const Color(0xFFFF9800),
    const Color(0xFFE91E63),
    const Color(0xFF8BC34A),
    const Color(0xFF3F51B5),
    const Color(0xFF9C27B0),
    const Color(0xFF00BCD4),
  ];

  final List<IconData> _iconOptions = [
    Icons.restaurant_rounded,
    Icons.shopping_cart_rounded,
    Icons.directions_car_rounded,
    Icons.home_rounded,
    Icons.bolt_rounded,
    Icons.movie_rounded,
    Icons.local_hospital_rounded,
    Icons.account_balance_wallet_rounded,
    Icons.work_rounded,
    Icons.trending_up_rounded,
    Icons.pets_rounded,
    Icons.flight_rounded,
    Icons.school_rounded,
    Icons.fitness_center_rounded,
    Icons.devices_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.category?.name ?? '';
    _subCategoryController.text = widget.category?.subCategory ?? '';
    if (widget.category != null) {
      final parts = widget.category!.type.split('_');
      if (parts.length == 2) {
        _selectedNature = parts[0];
        _selectedClass = parts[1];
      }
      _selectedColor = IconColorMapper.hexToColor(widget.category!.colour);
      _selectedIcon = IconColorMapper.stringToIcon(widget.category!.icon);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subCategoryController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final category = Category(
        id: widget.category?.id ?? '',
        userId: widget.category?.userId ?? '',
        name: name,
        type: '${_selectedNature}_$_selectedClass',
        subCategory: _subCategoryController.text.trim().isEmpty
            ? null
            : _subCategoryController.text.trim(),
        icon: IconColorMapper.iconToString(_selectedIcon),
        colour: IconColorMapper.colorToHex(_selectedColor),
        createdAt: widget.category?.createdAt ?? DateTime.now(),
      );

      if (widget.category == null) {
        await _categoryService.addCategory(category);
      } else {
        await _categoryService.updateCategory(category);
      }
      if (mounted) Navigator.pop(context, true); // true indicates success
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCategory() async {
    if (widget.category == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: const Text(
          'Are you sure you want to delete this category? This may affect records linked to it.',
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
      await _categoryService.deleteCategory(widget.category!.id);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.category != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Category' : 'New Category'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              onPressed: _isLoading ? null : _deleteCategory,
            ),
          const SizedBox(width: 8),
        ],
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
              CircleAvatar(
                radius: 40,
                backgroundColor: _selectedColor.withAlpha(40),
                child: Icon(_selectedIcon, size: 40, color: _selectedColor),
              ),
              const SizedBox(height: 32),

              // Row 1: Nature (Fixed / Variable)
              Text(
                'Nature',
                style: TextStyle(
                  color:
                      Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withAlpha(180) ??
                      Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildNatureButton(
                      'Fixed',
                      'fixed',
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildNatureButton(
                      'Variable',
                      'variable',
                      Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Row 2: Class (Income / Expense)
              Text(
                'Class',
                style: TextStyle(
                  color:
                      Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withAlpha(180) ??
                      Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildClassButton(
                      'Expense',
                      'expense',
                      Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildClassButton('Income', 'income', Colors.green),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // General Info Fields
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  hintText: 'e.g. Groceries',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _subCategoryController,
                decoration: const InputDecoration(
                  labelText: 'Sub Category (Optional)',
                  hintText: 'e.g. Shopping',
                ),
              ),
              const SizedBox(height: 32),

              // Color Picker
              Text(
                'Color',
                style: TextStyle(
                  color:
                      Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withAlpha(180) ??
                      Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 50,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _colorOptions.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final color = _colorOptions[index];
                    final isSelected = color == _selectedColor;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedColor = color);
                      },
                      child: Container(
                        width: 50,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  width: 3,
                                )
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),

              // Icon Picker
              Text(
                'Icon',
                style: TextStyle(
                  color:
                      Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withAlpha(180) ??
                      Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _iconOptions.length,
                itemBuilder: (context, index) {
                  final icon = _iconOptions[index];
                  final isSelected = icon == _selectedIcon;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _selectedColor.withAlpha(40)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: isSelected
                            ? Border.all(color: _selectedColor, width: 2)
                            : Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withAlpha(20),
                              ),
                      ),
                      child: Icon(
                        icon,
                        color: isSelected
                            ? _selectedColor
                            : Theme.of(context).textTheme.bodyMedium?.color
                                      ?.withAlpha(180) ??
                                  Colors.grey,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 48),

              ElevatedButton(
                onPressed: _isLoading ? null : _saveCategory,
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
                    : const Text('Save Category'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNatureButton(String label, String value, Color color) {
    final isSelected = _selectedNature == value;
    return InkWell(
      onTap: () {
        setState(() => _selectedNature = value);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withAlpha(40)
              : Theme.of(context).scaffoldBackgroundColor,
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
              color: isSelected
                  ? color
                  : Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withAlpha(180) ??
                        Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClassButton(String label, String value, Color color) {
    final isSelected = _selectedClass == value;
    return InkWell(
      onTap: () {
        setState(() => _selectedClass = value);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withAlpha(40)
              : Theme.of(context).scaffoldBackgroundColor,
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
              color: isSelected
                  ? color
                  : Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withAlpha(180) ??
                        Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
