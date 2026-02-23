import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
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

  // Expanded states for each group
  final Map<String, bool> _expanded = {
    'fixed_income': true,
    'variable_income': true,
    'fixed_expense': true,
    'variable_expense': true,
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
            subCategory:
                suggestion['sub_category'] ??
                (type == 'fixed_expense' ? 'General' : null),
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
    String selectedClassification = suggestion?['sub_category'] ?? 'General';

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

                if (type == 'fixed_expense') ...[
                  const Text(
                    'Classification',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedClassification,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    items: ['General', 'Goal Related', 'Debt Related']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedClassification = val);
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                ],

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
                  final data = {
                    'name': nameController.text.trim(),
                    'icon': selectedIcon,
                    'color': selectedColor,
                  };
                  if (type == 'fixed_expense') {
                    data['sub_category'] = selectedClassification;
                  }
                  Navigator.pop(context, data);
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

  Future<void> _showDeleteConfirmation(String type, int index) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: const Text('Are you sure you want to delete this category?'),
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

    if (confirm == true) {
      setState(() {
        _suggestedCategories[type]!.removeAt(index);
        final newSelected = <int>{};
        for (int i in _selectedIndices[type]!) {
          if (i < index) {
            newSelected.add(i);
          } else if (i > index) {
            newSelected.add(i - 1);
          }
        }
        _selectedIndices[type] = newSelected;
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
            _buildSectionHeader(
              'Fixed',
              Icons.push_pin_rounded,
              Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            _buildGroup(
              'Income',
              'fixed_income',
              Icons.arrow_upward_rounded,
              Colors.green,
            ),
            const SizedBox(height: 4),
            _buildGroup(
              'Expense',
              'fixed_expense',
              Icons.arrow_downward_rounded,
              Colors.red,
            ),
            const SizedBox(height: 20),

            // VARIABLE Section
            _buildSectionHeader(
              'Variable',
              Icons.sync_rounded,
              const Color(0xFFF59E0B),
            ),
            const SizedBox(height: 8),
            _buildGroup(
              'Income',
              'variable_income',
              Icons.arrow_upward_rounded,
              Colors.green,
            ),
            const SizedBox(height: 4),
            _buildGroup(
              'Expense',
              'variable_expense',
              Icons.arrow_downward_rounded,
              Colors.red,
            ),
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

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withAlpha(40), color.withAlpha(10)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(60),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroup(
    String title,
    String type,
    IconData incomeIcon,
    Color incomeColor,
  ) {
    final suggestions = _suggestedCategories[type]!;
    final isExpanded = _expanded[type] ?? true;

    return Container(
      margin: const EdgeInsets.only(left: 12, right: 0, bottom: 4),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: incomeColor.withAlpha(100), width: 3),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isExpanded,
          onExpansionChanged: (val) => setState(() => _expanded[type] = val),
          leading: Icon(incomeIcon, color: incomeColor, size: 20),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: incomeColor,
              fontSize: 14,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: incomeColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${suggestions.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: incomeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => _addCustomCategory(type),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.add_circle_outline,
                    color: incomeColor,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          children: suggestions.isEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Text(
                      'No $title categories yet. Tap + to add.',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ]
              : List.generate(suggestions.length, (index) {
                  return _buildCategoryTile(type, index);
                }),
        ),
      ),
    );
  }

  Widget _buildCategoryTile(String type, int index) {
    final suggestions = _suggestedCategories[type]!;
    final selected = _selectedIndices[type]!;

    final suggestion = suggestions[index];
    final isSelected = selected.contains(index);
    final color = IconColorMapper.hexToColor(suggestion['color']!);
    final icon = IconColorMapper.stringToIcon(suggestion['icon']!);

    return Slidable(
      key: ValueKey('${type}_$index'),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          if (isSelected)
            SlidableAction(
              onPressed: (_) => _showCategoryEditor(type, index: index),
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              icon: Icons.edit_rounded,
              label: 'Edit',
            ),
          if (isSelected)
            SlidableAction(
              onPressed: (_) => _showDeleteConfirmation(type, index),
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              icon: Icons.delete_rounded,
              label: 'Delete',
            ),
        ],
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.white : Colors.grey.shade600,
            size: 20,
          ),
        ),
        title: Text(
          suggestion['name']!,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? color : Colors.black87,
            fontSize: 14,
          ),
        ),
        subtitle: type == 'fixed_expense' && suggestion['sub_category'] != null
            ? Text(
                suggestion['sub_category']!,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              )
            : null,
        trailing: Checkbox(
          value: isSelected,
          activeColor: color,
          onChanged: (val) {
            setState(() {
              if (val == true) {
                selected.add(index);
              } else {
                if (selected.length > 1) selected.remove(index);
              }
            });
          },
        ),
        onTap: () {
          setState(() {
            if (!isSelected) {
              selected.add(index);
            } else {
              if (selected.length > 1) selected.remove(index);
            }
          });
        },
      ),
    );
  }
}
