import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:shimmer/shimmer.dart';

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
      body: IndexedStack(
        index: _currentIndex,
        children: [
          RefreshIndicator(
            onRefresh: _loadData,
            child: _isLoading
                ? _buildHomeShimmer(
                    context,
                    isDesktop: ResponsiveBuilder.isDesktop(context),
                  )
                : Container(
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
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top section with gradient background
          Container(
            padding: EdgeInsets.fromLTRB(
              isDesktop ? 64 : 24,
              48,
              isDesktop ? 64 : 24,
              32,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withRed(100),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withAlpha(80),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, ${_userProfile?.fullName ?? 'User'} 👋',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Here is a summary of your finances',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.notifications_none_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () {},
                        ),
                        const SizedBox(width: 8),
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
                                      backgroundColor: Colors.white.withAlpha(
                                        50,
                                      ),
                                      color: Colors.white,
                                    ),
                                  ),
                                  CircleAvatar(
                                    radius: 15,
                                    backgroundColor: Colors.white,
                                    backgroundImage:
                                        _userProfile?.avatarUrl != null
                                        ? NetworkImage(_userProfile!.avatarUrl!)
                                        : null,
                                    child: _userProfile?.avatarUrl == null
                                        ? Text(
                                            _userProfile?.fullName != null &&
                                                    _userProfile!
                                                        .fullName!
                                                        .isNotEmpty
                                                ? _userProfile!.fullName![0]
                                                      .toUpperCase()
                                                : 'U',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                            ),
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${((_userProfile?.completeness ?? 0) * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
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
                          Icons.account_balance_wallet_rounded,
                          Colors.white,
                          Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildSummaryCard(
                          context,
                          'Monthly Income',
                          '+\$${_monthlyIncome.toStringAsFixed(2)}',
                          Icons.trending_up_rounded,
                          Colors.green.shade50,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildSummaryCard(
                          context,
                          'Monthly Expense',
                          '-\$${_monthlyExpense.toStringAsFixed(2)}',
                          Icons.trending_down_rounded,
                          Colors.red.shade50,
                          Colors.red,
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
                        Icons.account_balance_wallet_rounded,
                        Colors.white,
                        Theme.of(context).colorScheme.primary,
                        isPrimary: true,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              context,
                              'Income',
                              '+\$${_monthlyIncome.toStringAsFixed(0)}',
                              Icons.trending_up_rounded,
                              Colors.white,
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
                              Icons.trending_down_rounded,
                              Colors.white,
                              Colors.red,
                              small: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Main body content
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 64 : 24,
              vertical: 32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionTitle('Recent Records', 'View All', () {}),
                const SizedBox(height: 16),
                _buildTransactionList(),

                const SizedBox(height: 40),

                _buildSectionTitle('Financial Goals', 'View All', () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GoalsListScreen()),
                  );
                  _loadData();
                }),
                const SizedBox(height: 16),
                _buildGoalsSummary(),

                const SizedBox(height: 40),

                _buildSectionTitle('Debt Manager', 'View All', () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LiabilitiesListScreen(),
                    ),
                  );
                  _loadData();
                }),
                const SizedBox(height: 16),
                _buildDebtSummary(),

                const SizedBox(height: 100), // padding for fab
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeShimmer(BuildContext context, {required bool isDesktop}) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top section Shimmer
          Container(
            padding: EdgeInsets.fromLTRB(
              isDesktop ? 64 : 24,
              48,
              isDesktop ? 64 : 24,
              32,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withRed(100),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Shimmer.fromColors(
              baseColor: Colors.white.withAlpha(50),
              highlightColor: Colors.white.withAlpha(150),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(height: 30, width: 200, color: Colors.white),
                      Container(
                        height: 38,
                        width: 38,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(height: 16, width: 150, color: Colors.white),
                  const SizedBox(height: 32),
                  if (isDesktop)
                    Row(
                      children: [
                        Expanded(child: _buildShimmerSummaryCard(100)),
                        const SizedBox(width: 24),
                        Expanded(child: _buildShimmerSummaryCard(100)),
                        const SizedBox(width: 24),
                        Expanded(child: _buildShimmerSummaryCard(100)),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildShimmerSummaryCard(120),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildShimmerSummaryCard(100)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildShimmerSummaryCard(100)),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          // Body Lists Shimmer
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 64 : 24,
              vertical: 32,
            ),
            child: Shimmer.fromColors(
              baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              highlightColor: Theme.of(context).colorScheme.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildShimmerSectionHeader(),
                  const SizedBox(height: 16),
                  _buildShimmerList(3, 80),
                  const SizedBox(height: 32),
                  _buildShimmerSectionHeader(),
                  const SizedBox(height: 16),
                  _buildShimmerList(2, 60),
                  const SizedBox(height: 32),
                  _buildShimmerSectionHeader(),
                  const SizedBox(height: 16),
                  _buildShimmerList(2, 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerSummaryCard(double height) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }

  Widget _buildShimmerSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          height: 24,
          width: 150,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        Container(
          height: 16,
          width: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerList(int count, double itemHeight) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Container(
          height: itemHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(
    String title,
    String actionText,
    VoidCallback onAction,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
          ),
          child: Text(
            actionText,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalsSummary() {
    if (_goals.isEmpty) {
      return _buildEmptySection('No goals set yet', Icons.flag_outlined);
    }

    final topGoal = _goals.first;
    final color = Color(int.parse(topGoal.colour.replaceFirst('#', '0xFF')));

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.flag_rounded, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topGoal.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(topGoal.percentComplete * 100).toStringAsFixed(0)}% Completed',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(150),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: topGoal.percentComplete,
              backgroundColor: color.withAlpha(30),
              color: color,
              minHeight: 12,
            ),
          ),
        ],
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

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.error,
            Theme.of(context).colorScheme.error.withAlpha(204),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.error.withAlpha(60),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(50),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.account_balance_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Remaining Debt',
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Text(
                '\$${totalDebt.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySection(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withAlpha(20),
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 24, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          Text(
            message,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String amount,
    IconData icon,
    Color bgColor,
    Color accentColor, {
    bool small = false,
    bool isPrimary = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isPrimary ? 20 : 5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: EdgeInsets.all(small ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isPrimary ? Colors.black87 : Colors.grey.shade700,
                    fontSize: small ? 13 : 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(small ? 8 : 12),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: small ? 18 : 24),
              ),
            ],
          ),
          SizedBox(height: small ? 12 : 16),
          Text(
            amount,
            style: TextStyle(
              fontSize: small ? 20 : 32,
              fontWeight: FontWeight.bold,
              color: isPrimary ? Colors.black : Colors.black87,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    if (_records.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(20),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: Colors.grey.withAlpha(100),
            ),
            const SizedBox(height: 16),
            Text(
              'No records found',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _records.length > 5 ? 5 : _records.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
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

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditRecordScreen(record: tx),
                  ),
                );
                if (result == true) {
                  _loadData();
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: color.withAlpha(30),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            category?.name ?? 'Unknown',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withAlpha(150),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          amountString,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isExpense
                                ? Theme.of(context).colorScheme.onSurface
                                : Colors.green.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${tx.timestamp.day}/${tx.timestamp.month}/${tx.timestamp.year}',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withAlpha(150),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
