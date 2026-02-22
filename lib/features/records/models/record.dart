class FinancialRecord {
  final String id;
  final String userId;
  final String accountId;
  final String categoryId;
  final String? goalId;
  final String? liabilityId;
  final String name;
  final double amount;
  final String type; // 'credit' or 'debit'
  final DateTime timestamp;
  final DateTime createdAt;

  FinancialRecord({
    required this.id,
    required this.userId,
    required this.accountId,
    required this.categoryId,
    this.goalId,
    this.liabilityId,
    required this.name,
    required this.amount,
    required this.type,
    required this.timestamp,
    required this.createdAt,
  });

  factory FinancialRecord.fromJson(Map<String, dynamic> json) {
    return FinancialRecord(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      accountId: json['account_id'] as String,
      categoryId: json['category_id'] as String,
      goalId: json['goal_id'] as String?,
      liabilityId: json['liability_id'] as String?,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'account_id': accountId,
      'category_id': categoryId,
      'goal_id': goalId,
      'liability_id': liabilityId,
      'name': name,
      'amount': amount,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
