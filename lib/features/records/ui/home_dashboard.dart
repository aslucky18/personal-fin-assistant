import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

import '../../../core/utils/responsive.dart';
import '../../../core/utils/icon_color_mapper.dart';
import '../../accounts/ui/accounts_list_screen.dart';
import '../../categories/ui/categories_list_screen.dart';
import 'add_record_screen.dart';
import 'edit_record_screen.dart';
import '../services/record_service.dart';
import '../../categories/services/category_service.dart';
import '../models/record.dart';
import '../../categories/models/category.dart';
import '../../auth/ui/settings_screen.dart';
import '../../auth/ui/user_profile_screen.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/models/user_profile.dart';
import '../../goals/ui/goals_list_screen.dart';
import '../../goals/services/goal_service.dart';
import '../../goals/models/goal.dart';
import '../../liabilities/ui/liabilities_list_screen.dart';
import '../../liabilities/services/liability_service.dart';
import '../../liabilities/models/liability.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  int _currentIndex = 0;
  final _recordService = RecordService();
  final _categoryService = CategoryService();
  final _authService = AuthService();
  final _goalService = GoalService();
  final _liabilityService = LiabilityService();

  List<FinancialRecord> _records = [];
  Map<String, Category> _categoryMap = {};
  UserProfile? _userProfile;
  List<FinancialGoal> _goals = [];
  List<Liability> _liabilities = [];

  bool _isLoading = true;
  double _totalBalance = 0;
  double _monthlyIncome = 0;
  double _monthlyExpense = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final records = await _recordService.getRecords(limit: 50);
      final categoriesList = await _categoryService.getCategories();
      final profile = await _authService.getCurrentUserProfile();
      final goals = await _goalService.getGoals();
      final liabilities = await _liabilityService.getLiabilities();

      final Map<String, Category> map = {};
      for (var c in categoriesList) {
        map[c.id] = c;
      }

      double income = 0;
      double expense = 0;
      double total = 0;
      final now = DateTime.now();

      for (var r in records) {
        if (r.timestamp.month == now.month && r.timestamp.year == now.year) {
          if (r.type == 'credit') income += r.amount;
          if (r.type == 'debit') expense += r.amount;
        }

        if (r.type == 'credit') total += r.amount;
        if (r.type == 'debit') total -= r.amount;
      }

      if (mounted) {
        setState(() {
          _records = records;
          _categoryMap = map;
          _userProfile = profile;
          _goals = goals;
          _liabilities = liabilities;
          _monthlyIncome = income;
          _monthlyExpense = expense;
          _totalBalance = total;
        });
      }
    } catch (e) {
      debugPrint('Failed to load home data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _currentIndex == 0
          ? AppBar(
              title: const Text('Dashboard'),
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded),
                  onPressed: () {},
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () async {
                    if (_userProfile != null) {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              UserProfileScreen(profile: _userProfile!),
                        ),
                      );
                      if (result == true) {
                        _loadData(); // reload on return to reflect changes
                      }
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 38,
                            height: 38,
                            child: CircularProgressIndicator(
                              value: _userProfile?.completeness ?? 0,
                              strokeWidth: 2.5,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary.withAlpha(20),
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          CircleAvatar(
                            radius: 15,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            backgroundImage: _userProfile?.avatarUrl != null
                                ? NetworkImage(_userProfile!.avatarUrl!)
                                : null,
                            child: _userProfile?.avatarUrl == null
                                ? Text(
                                    _userProfile?.fullName != null &&
                                            _userProfile!.fullName!.isNotEmpty
                                        ? _userProfile!.fullName![0]
                                              .toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  )
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${((_userProfile?.completeness ?? 0) * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
              ],
            )
          : null,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: Container(
                    color: Theme.of(context).colorScheme.surface,
                    child: ResponsiveBuilder(
                      mobile: _buildDashboardContent(context, isDesktop: false),
                      desktop: _buildDashboardContent(context, isDesktop: true),
                    ),
                  ),
                ),
          const AccountsListScreen(),
          const CategoriesListScreen(),
          const SettingsScreen(),
        ],
      ),
      floatingActionButton: _currentIndex == 0 ? _buildSpeedDial() : null,
      bottomNavigationBar: ResponsiveBuilder.isDesktop(context)
          ? null
          : NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() => _currentIndex = index);
              },
              backgroundColor: Theme.of(context).colorScheme.surface,
              indicatorColor: Theme.of(
                context,
              ).colorScheme.primary.withAlpha(50),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_rounded),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.account_balance_wallet_rounded),
                  label: 'Accounts',
                ),
                NavigationDestination(
                  icon: Icon(Icons.category_rounded),
                  label: 'Categories',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_rounded),
                  label: 'Settings',
                ),
              ],
            ),
    );
  }

  Widget _buildDashboardContent(
    BuildContext context, {
    required bool isDesktop,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : 24,
        vertical: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Greeting
          Text(
            'Hello, ${_userProfile?.fullName ?? 'User'}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Here is a summary of your finances',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color:
                  Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withAlpha(180) ??
                  Colors.grey,
            ),
          ),
          const SizedBox(height: 32),

          // Summary Cards
          if (isDesktop)
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    context,
                    'Total Balance',
                    '\$${_totalBalance.toStringAsFixed(2)}',
                    Icons.account_balance_rounded,
                    Theme.of(context).colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildSummaryCard(
                    context,
                    'Monthly Income',
                    '+\$${_monthlyIncome.toStringAsFixed(2)}',
                    Icons.arrow_upward_rounded,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildSummaryCard(
                    context,
                    'Monthly Expense',
                    '-\$${_monthlyExpense.toStringAsFixed(2)}',
                    Icons.arrow_downward_rounded,
                    Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                _buildSummaryCard(
                  context,
                  'Total Balance',
                  '\$${_totalBalance.toStringAsFixed(2)}',
                  Icons.account_balance_rounded,
                  Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        context,
                        'Income',
                        '+\$${_monthlyIncome.toStringAsFixed(0)}',
                        Icons.arrow_upward_rounded,
                        Colors.green,
                        small: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        context,
                        'Expense',
                        '-\$${_monthlyExpense.toStringAsFixed(0)}',
                        Icons.arrow_downward_rounded,
                        Theme.of(context).colorScheme.error,
                        small: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),

          const SizedBox(height: 48),

          // Recent Transactions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Records',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton(onPressed: () {}, child: const Text('View All')),
            ],
          ),
          const SizedBox(height: 16),
          _buildTransactionList(),

          const SizedBox(height: 48),

          // Goals Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Financial Goals',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GoalsListScreen()),
                  );
                  _loadData();
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildGoalsSummary(),

          const SizedBox(height: 48),

          // Debt Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Debt Manager',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LiabilitiesListScreen(),
                    ),
                  );
                  _loadData();
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDebtSummary(),
          const SizedBox(height: 100), // extra padding for fab
        ],
      ),
    );
  }

  Widget _buildGoalsSummary() {
    if (_goals.isEmpty) {
      return _buildEmptySection('No goals set yet', Icons.flag_outlined);
    }

    final topGoal = _goals.first;
    final color = Color(int.parse(topGoal.colour.replaceFirst('#', '0xFF')));

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag_rounded, color: color),
                const SizedBox(width: 12),
                Text(
                  topGoal.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text('${(topGoal.percentComplete * 100).toStringAsFixed(0)}%'),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: topGoal.percentComplete,
              backgroundColor: color.withAlpha(50),
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtSummary() {
    if (_liabilities.isEmpty) {
      return _buildEmptySection('You are debt-free!', Icons.money_off_rounded);
    }

    final totalDebt = _liabilities.fold<double>(
      0,
      (sum, item) => sum + item.remainingAmount,
    );

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withAlpha(40),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.account_balance_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Remaining Debt',
                  style: TextStyle(fontSize: 12),
                ),
                Text(
                  '\$${totalDebt.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySection(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withAlpha(10),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String amount,
    IconData icon,
    Color color, {
    bool small = false,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color:
                        Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withAlpha(180) ??
                        Colors.grey,
                    fontSize: small ? 14 : 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withAlpha(50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: small ? 20 : 24),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              amount,
              style: TextStyle(
                fontSize: small ? 24 : 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: -1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    if (_records.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: Text(
          'No records found',
          style: TextStyle(
            color:
                Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(180) ??
                Colors.grey,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _records.length,
      itemBuilder: (context, index) {
        final tx = _records[index];
        final isExpense = tx.type == 'debit';
        final category = _categoryMap[tx.categoryId];

        final color = category != null
            ? IconColorMapper.hexToColor(category.colour)
            : Theme.of(context).colorScheme.secondary;
        final icon = category != null
            ? IconColorMapper.stringToIcon(category.icon)
            : Icons.category_rounded;

        final amountString = isExpense
            ? '- \$${tx.amount.toStringAsFixed(2)}'
            : '+ \$${tx.amount.toStringAsFixed(2)}';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide.none,
          ),
          color: Theme.of(context).colorScheme.surface,
          elevation: 0,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EditRecordScreen(record: tx)),
              );
              if (result == true) {
                _loadData();
              }
            },
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(40),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color),
            ),
            title: Text(
              tx.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              category?.name ?? 'Unknown',
              style: TextStyle(
                color:
                    Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withAlpha(180) ??
                    Colors.grey,
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amountString,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isExpense
                        ? Theme.of(context).colorScheme.onSurface
                        : Colors.green,
                  ),
                ),
                Text(
                  '${tx.timestamp.day}/${tx.timestamp.month}/${tx.timestamp.year}',
                  style: TextStyle(
                    color:
                        Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withAlpha(180) ??
                        Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpeedDial() {
    return SpeedDial(
      icon: Icons.add_rounded,
      activeIcon: Icons.close_rounded,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      overlayColor: Colors.black,
      overlayOpacity: 0.3,
      spacing: 12,
      spaceBetweenChildren: 8,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.flag_outlined),
          backgroundColor: const Color(0xFF22C55E),
          foregroundColor: Colors.white,
          label: 'Goal',
          labelBackgroundColor: const Color(0xFF22C55E),
          labelStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GoalsListScreen()),
            );
            if (result == true) _loadData();
          },
        ),
        SpeedDialChild(
          child: const Icon(Icons.account_balance_outlined),
          backgroundColor: Color(0xFFEF4444),
          foregroundColor: Colors.white,
          label: 'Debt',
          labelBackgroundColor: Color(0xFFEF4444),
          labelStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LiabilitiesListScreen()),
            );
            if (result == true) _loadData();
          },
        ),
        SpeedDialChild(
          child: const Icon(Icons.receipt_long_rounded),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          label: 'Record',
          labelBackgroundColor: Theme.of(context).colorScheme.primary,
          labelStyle: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddRecordScreen()),
            );
            if (result == true) _loadData();
          },
        ),
      ],
    );
  }
}
