import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import 'add_category_screen.dart';
import '../services/category_service.dart';
import '../models/category.dart';
import '../../../core/utils/icon_color_mapper.dart';
import 'package:shimmer/shimmer.dart';

class CategoriesListScreen extends StatefulWidget {
  const CategoriesListScreen({super.key});

  @override
  State<CategoriesListScreen> createState() => _CategoriesListScreenState();
}

class _CategoriesListScreenState extends State<CategoriesListScreen> {
  final _categoryService = CategoryService();
  List<Category> _categories = [];
  bool _isLoading = true;

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
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final categories = await _categoryService.getCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load categories: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCategory(String id) async {
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

    if (confirm == true) {
      try {
        await _categoryService.deleteCategory(id);
        _loadCategories();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete category: $e')),
          );
        }
      }
    }
  }

  List<Category> _getGroup(String type) =>
      _categories.where((c) => c.type == type).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'categories_fab',
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddCategoryScreen()),
          );
          if (result == true) {
            _loadCategories();
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Category'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadCategories,
        child: _isLoading
            ? _buildShimmerLoading()
            : _categories.isEmpty
            ? _buildEmptyState()
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                children: [
                  // FIXED Section
                  _buildSectionHeader(
                    'Fixed',
                    Icons.lock_rounded,
                    const Color(0xFF6366F1),
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
                  const SizedBox(height: 80),
                ],
              ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView(
      // AlwaysScrollable so RefreshIndicator can detect the pull gesture
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        _buildShimmerSectionHeader(),
        const SizedBox(height: 8),
        _buildShimmerGroup(),
        const SizedBox(height: 12),
        _buildShimmerGroup(),
        const SizedBox(height: 24),
        _buildShimmerSectionHeader(),
        const SizedBox(height: 8),
        _buildShimmerGroup(),
      ],
    );
  }

  Widget _buildShimmerSectionHeader() {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      highlightColor: Theme.of(context).colorScheme.surface,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildShimmerGroup() {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      highlightColor: Theme.of(context).colorScheme.surface,
      child: Container(
        margin: const EdgeInsets.only(left: 12, right: 0, bottom: 4),
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
    final cats = _getGroup(type);
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
                  '${cats.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: incomeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddCategoryScreen(preselectedType: type),
                    ),
                  );
                  if (result == true) _loadCategories();
                },
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
          children: cats.isEmpty
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
              : cats.map((cat) => _buildCategoryTile(cat)).toList(),
        ),
      ),
    );
  }

  Widget _buildCategoryTile(Category cat) {
    final color = IconColorMapper.hexToColor(cat.colour);
    final icon = IconColorMapper.stringToIcon(cat.icon);

    return Slidable(
      key: ValueKey(cat.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddCategoryScreen(category: cat),
                ),
              );
              if (result == true) _loadCategories();
            },
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
            icon: Icons.edit_rounded,
            label: 'Edit',
          ),
          SlidableAction(
            onPressed: (_) => _deleteCategory(cat.id),
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
            color: color.withAlpha(40),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          cat.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: cat.subCategory != null
            ? Text(
                cat.subCategory!,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              )
            : null,
        trailing: const Icon(
          Icons.chevron_left_rounded,
          color: Colors.grey,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 80,
            color:
                Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(100) ??
                Colors.grey.withAlpha(100),
          ),
          const SizedBox(height: 16),
          Text(
            'No categories found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color:
                  Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withAlpha(180) ??
                  Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddCategoryScreen()),
              );
              if (result == true) {
                _loadCategories();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Category'),
          ),
        ],
      ),
    );
  }
}
