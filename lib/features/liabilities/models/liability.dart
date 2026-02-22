class Liability {
  final String id;
  final String userId;
  final String name;
  final double totalAmount;
  final double paidAmount;
  final double interestRate;
  final DateTime? dueDate;
  final String type;
  final DateTime createdAt;
  final String? categoryId;

  Liability({
    required this.id,
    required this.userId,
    required this.name,
    required this.totalAmount,
    required this.paidAmount,
    required this.interestRate,
    this.dueDate,
    required this.type,
    required this.createdAt,
    this.categoryId,
  });

  factory Liability.fromJson(Map<String, dynamic> json) {
    return Liability(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      paidAmount: (json['paid_amount'] as num).toDouble(),
      interestRate: (json['interest_rate'] as num).toDouble(),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      type: json['type'] as String? ?? 'loan',
      createdAt: DateTime.parse(json['created_at'] as String),
      categoryId: json['category_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'interest_rate': interestRate,
      'due_date': dueDate?.toIso8601String(),
      'type': type,
      'category_id': categoryId,
    };
  }

  double get remainingAmount => totalAmount - paidAmount;
  double get percentPaid => totalAmount > 0 ? (paidAmount / totalAmount) : 0;
}
