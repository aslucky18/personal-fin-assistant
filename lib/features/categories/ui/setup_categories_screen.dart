import 'package:flutter/material.dart';
import '../services/category_service.dart';
import '../models/category.dart';
import '../../onboarding/ui/setup_account_screen.dart';
import '../../../core/utils/icon_color_mapper.dart';

class SetupCategoriesScreen extends StatefulWidget {
  const SetupCategoriesScreen({super.key});

  @override
  State<SetupCategoriesScreen> createState() => _SetupCategoriesScreenState();
}

class _SetupCategoriesScreenState extends State<SetupCategoriesScreen> {
  final _categoryService = CategoryService();
  bool _isLoading = false;

  final Map<String, List<Map<String, String>>> _suggestedCategories = {
    'fixed_income': [],
    'variable_income': [],
    'fixed_expense': [],
    'variable_expense': [],
  };

  final Map<String, Set<int>> _selectedIndices = {
    'fixed_income': {},
    'variable_income': {},
    'fixed_expense': {},
    'variable_expense': {},
  };

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  void _loadSuggestions() {
    // Merged generic suggestions
    _suggestedCategories['fixed_income'] = [
      {'name': 'Salary', 'icon': 'payments', 'color': '#10B981'},
      {'name': 'Bonus', 'icon': 'card_giftcard', 'color': '#F59E0B'},
      {'name': 'Wages', 'icon': 'work', 'color': '#3B82F6'},
    ];
    _suggestedCategories['variable_income'] = [
      {'name': 'Dividends', 'icon': 'trending_up', 'color': '#8B5CF6'},
      {'name': 'Freelance', 'icon': 'computer', 'color': '#EC4899'},
      {'name': 'Tips', 'icon': 'savings', 'color': '#0EA5E9'},
    ];
    _suggestedCategories['fixed_expense'] = [
      {'name': 'Rent/Mortgage', 'icon': 'home', 'color': '#EF4444'},
      {'name': 'Internet', 'icon': 'wifi', 'color': '#06B6D4'},
      {'name': 'Insurance', 'icon': 'verified_user', 'color': '#6366F1'},
      {'name': 'Transportation', 'icon': 'directions_car', 'color': '#F97316'},
    ];
    _suggestedCategories['variable_expense'] = [
      {'name': 'Groceries', 'icon': 'shopping_cart', 'color': '#F97316'},
      {'name': 'Dining', 'icon': 'restaurant', 'color': '#EC4899'},
      {'name': 'Travel', 'icon': 'flight', 'color': '#0EA5E9'},
      {'name': 'Healthcare', 'icon': 'medical_services', 'color': '#EF4444'},
    ];

    // Select first one by default for each to satisfy validation
    _selectedIndices['fixed_income']!.add(0);
    _selectedIndices['variable_income']!.add(0);
    _selectedIndices['fixed_expense']!.add(0);
    _selectedIndices['variable_expense']!.add(0);
  }

  Future<void> _createCategoriesAndNext() async {
    setState(() => _isLoading = true);
    try {
      for (var type in _selectedIndices.keys) {
        for (var index in _selectedIndices[type]!) {
          final suggestion = _suggestedCategories[type]![index];
          final cat = Category(
            id: '',
            userId: '',
            name: suggestion['name']!,
            type: type,
            icon: suggestion['icon']!,
            colour: suggestion['color']!,
            createdAt: DateTime.now(),
          );
          await _categoryService.addCategory(cat);
        }
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SetupAccountScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to setup categories: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showCategoryEditor(String type, {int? index}) async {
    final bool isEditing = index != null;
    final suggestion = isEditing ? _suggestedCategories[type]![index] : null;

    final nameController = TextEditingController(
      text: suggestion?['name'] ?? '',
    );
    String selectedIcon = suggestion?['icon'] ?? 'category';
    String selectedColor =
        suggestion?['color'] ?? IconColorMapper.premiumColors.first;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Category' : 'Add Custom Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Preview Area
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: IconColorMapper.hexToColor(
                        selectedColor,
                      ).withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      IconColorMapper.stringToIcon(selectedIcon),
                      size: 48,
                      color: IconColorMapper.hexToColor(selectedColor),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: !isEditing,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Icon',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  width: double.maxFinite,
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                    itemCount: IconColorMapper.availableIcons.length,
                    itemBuilder: (context, i) {
                      final iconName = IconColorMapper.availableIcons[i];
                      final isSelected = selectedIcon == iconName;
                      return GestureDetector(
                        onTap: () =>
                            setDialogState(() => selectedIcon = iconName),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? IconColorMapper.hexToColor(
                                    selectedColor,
                                  ).withAlpha(40)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? IconColorMapper.hexToColor(selectedColor)
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            IconColorMapper.stringToIcon(iconName),
                            size: 20,
                            color: isSelected
                                ? IconColorMapper.hexToColor(selectedColor)
                                : Colors.grey.shade600,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Color',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: IconColorMapper.premiumColors.map((hex) {
                    final isSelected = selectedColor == hex;
                    final color = IconColorMapper.hexToColor(hex);
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = hex),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withAlpha(100),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  Navigator.pop(context, {
                    'name': nameController.text.trim(),
                    'icon': selectedIcon,
                    'color': selectedColor,
                  });
                }
              },
              child: Text(isEditing ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        if (isEditing) {
          _suggestedCategories[type]![index] = result;
        } else {
          _suggestedCategories[type]!.add(result);
          _selectedIndices[type]!.add(_suggestedCategories[type]!.length - 1);
        }
      });
    }
  }

  void _addCustomCategory(String type) => _showCategoryEditor(type);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup Categories')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select your categories',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'We have pre-selected common categories for you. Tap any to customize.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            _buildCategoryGroup('Fixed Income', 'fixed_income'),
            _buildCategoryGroup('Variable Income', 'variable_income'),
            _buildCategoryGroup('Fixed Expense', 'fixed_expense'),
            _buildCategoryGroup('Variable Expense', 'variable_expense'),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _isLoading ? null : _createCategoriesAndNext,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Next: Link Bank Account'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGroup(String title, String type) {
    final suggestions = _suggestedCategories[type]!;
    final selected = _selectedIndices[type]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () => _addCustomCategory(type),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Custom'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(suggestions.length, (index) {
            final suggestion = suggestions[index];
            final isSelected = selected.contains(index);
            final color = IconColorMapper.hexToColor(suggestion['color']!);

            return IntrinsicWidth(
              child: FilterChip(
                label: Text(suggestion['name']!),
                selected: isSelected,
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      selected.add(index);
                    } else {
                      if (selected.length > 1) selected.remove(index);
                    }
                  });
                },
                avatar: Icon(
                  IconColorMapper.stringToIcon(suggestion['icon']!),
                  size: 18,
                  color: isSelected ? color : Colors.grey.shade600,
                ),
                onDeleted: isSelected
                    ? () => _showCategoryEditor(type, index: index)
                    : null,
                deleteIcon: const Icon(Icons.edit, size: 14),
                deleteButtonTooltipMessage: 'Edit category',
                selectedColor: color.withAlpha(40),
                checkmarkColor: color,
                labelStyle: TextStyle(
                  color: isSelected ? color : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? color : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
