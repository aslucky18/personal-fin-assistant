import 'package:flutter/material.dart';
import '../services/liability_service.dart';
import '../models/liability.dart';
import 'add_edit_liability_screen.dart';

class LiabilitiesListScreen extends StatefulWidget {
  const LiabilitiesListScreen({super.key});

  @override
  State<LiabilitiesListScreen> createState() => _LiabilitiesListScreenState();
}

class _LiabilitiesListScreenState extends State<LiabilitiesListScreen> {
  final _liabilityService = LiabilityService();
  List<Liability> _liabilities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLiabilities();
  }

  Future<void> _loadLiabilities() async {
    setState(() => _isLoading = true);
    try {
      final liabilities = await _liabilityService.getLiabilities();
      if (mounted) {
        setState(() {
          _liabilities = liabilities;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load liabilities: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteLiability(String id) async {
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

    if (confirm == true) {
      try {
        await _liabilityService.deleteLiability(id);
        _loadLiabilities();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete liability: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debt Manager'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddEditLiabilityScreen(),
                ),
              );
              if (result == true) {
                _loadLiabilities();
              }
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _liabilities.isEmpty
          ? _buildEmptyState()
          : _buildLiabilitiesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.money_off_rounded,
            size: 80,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
          ),
          const SizedBox(height: 16),
          Text(
            'No debts found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
            ),
          ),
          const SizedBox(height: 8),
          const Text('You are debt-free! Awesome!'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddEditLiabilityScreen(),
                ),
              );
              if (result == true) {
                _loadLiabilities();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Add a Liability'),
          ),
        ],
      ),
    );
  }

  Widget _buildLiabilitiesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _liabilities.length,
      itemBuilder: (context, index) {
        final liability = _liabilities[index];
        final percent = liability.percentPaid;
        final color = Theme.of(context).colorScheme.error;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditLiabilityScreen(liability: liability),
                ),
              );
              if (result == true) {
                _loadLiabilities();
              }
            },
            onLongPress: () => _deleteLiability(liability.id),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withAlpha(40),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.account_balance_rounded,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              liability.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Type: ${liability.type.toUpperCase()}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withAlpha(150),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${(percent * 100).toStringAsFixed(0)}% Paid',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          if (liability.noOfMonths > 0)
                            Text(
                              '${liability.paidMonths}/${liability.noOfMonths} Months',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          if (liability.interestRate > 0)
                            Text(
                              '${liability.interestRate}% Int.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withAlpha(150),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Stack(
                    children: [
                      LinearProgressIndicator(
                        value: percent,
                        backgroundColor: Colors.green.withAlpha(30),
                        color: Colors.green.withAlpha(
                          150,
                        ), // Financial progress darker
                        minHeight: 12,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      if (liability.noOfMonths > 0)
                        LinearProgressIndicator(
                          value: liability.monthsPercentPaid,
                          backgroundColor: Colors.transparent,
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withAlpha(200), // Time progress
                          minHeight: 12,
                          borderRadius: BorderRadius.circular(6),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\$${liability.remainingAmount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          Text(
                            'Remaining',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withAlpha(150),
                            ),
                          ),
                        ],
                      ),
                      if (liability.expectedCompletionDate != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '${_getMonthName(liability.expectedCompletionDate!.month)} ${liability.expectedCompletionDate!.year}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              'Est. Completion',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withAlpha(150),
                              ),
                            ),
                          ],
                        ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${liability.totalAmount.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Total Debt',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withAlpha(150),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getMonthName(int month) {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return monthNames[month - 1];
  }
}
