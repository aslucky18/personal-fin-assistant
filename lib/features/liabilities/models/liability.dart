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
  final double monthlyPayable;
  final int noOfMonths;
  final int paidMonths;
  final double downPayment;
  final DateTime? startDate;

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
    this.monthlyPayable = 0.0,
    this.noOfMonths = 0,
    this.paidMonths = 0,
    this.downPayment = 0.0,
    this.startDate,
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
      monthlyPayable: (json['monthly_payable'] as num?)?.toDouble() ?? 0.0,
      noOfMonths: json['no_of_months'] as int? ?? 0,
      paidMonths: json['paid_months'] as int? ?? 0,
      downPayment: (json['down_payment'] as num?)?.toDouble() ?? 0.0,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
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
      'monthly_payable': monthlyPayable,
      'no_of_months': noOfMonths,
      'paid_months': paidMonths,
      'down_payment': downPayment,
      'start_date': startDate?.toIso8601String(),
    };
  }

  double get remainingAmount => totalAmount - paidAmount;
  double get percentPaid => totalAmount > 0 ? (paidAmount / totalAmount) : 0;

  Liability copyWith({
    String? id,
    String? userId,
    String? name,
    double? totalAmount,
    double? paidAmount,
    double? interestRate,
    DateTime? dueDate,
    String? type,
    DateTime? createdAt,
    String? categoryId,
    double? monthlyPayable,
    int? noOfMonths,
    int? paidMonths,
    double? downPayment,
    DateTime? startDate,
  }) {
    return Liability(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      interestRate: interestRate ?? this.interestRate,
      dueDate: dueDate ?? this.dueDate,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      categoryId: categoryId ?? this.categoryId,
      monthlyPayable: monthlyPayable ?? this.monthlyPayable,
      noOfMonths: noOfMonths ?? this.noOfMonths,
      paidMonths: paidMonths ?? this.paidMonths,
      downPayment: downPayment ?? this.downPayment,
      startDate: startDate ?? this.startDate,
    );
  }

  double get monthsPercentPaid =>
      noOfMonths > 0 ? (paidMonths / noOfMonths) : 0;

  DateTime? get expectedCompletionDate {
    if (startDate == null || noOfMonths <= 0) return null;
    return DateTime(
      startDate!.year,
      startDate!.month + noOfMonths,
      startDate!.day,
    );
  }
}
