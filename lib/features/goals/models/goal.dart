class FinancialGoal {
  final String id;
  final String userId;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadline;
  final String icon;
  final String colour;
  final DateTime createdAt;
  final bool isChit;
  final double monthlyContribution;
  final int durationMonths;
  final DateTime? startDate;
  final String? categoryId;

  FinancialGoal({
    required this.id,
    required this.userId,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    this.deadline,
    required this.icon,
    required this.colour,
    required this.createdAt,
    this.isChit = false,
    this.monthlyContribution = 0,
    this.durationMonths = 0,
    this.startDate,
    this.categoryId,
  });

  factory FinancialGoal.fromJson(Map<String, dynamic> json) {
    return FinancialGoal(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      targetAmount: (json['target_amount'] as num).toDouble(),
      currentAmount: (json['current_amount'] as num).toDouble(),
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
      icon: json['icon'] as String? ?? 'flag',
      colour: json['colour'] as String? ?? '#2196F3',
      createdAt: DateTime.parse(json['created_at'] as String),
      isChit: json['is_chit'] as bool? ?? false,
      monthlyContribution:
          (json['monthly_contribution'] as num?)?.toDouble() ?? 0,
      durationMonths: json['duration_months'] as int? ?? 0,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      categoryId: json['category_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'deadline': deadline?.toIso8601String(),
      'icon': icon,
      'colour': colour,
      'is_chit': isChit,
      'monthly_contribution': monthlyContribution,
      'duration_months': durationMonths,
      'start_date': startDate?.toIso8601String(),
      'category_id': categoryId,
    };
  }

  double get percentComplete =>
      targetAmount > 0 ? (currentAmount / targetAmount) : 0;
}
