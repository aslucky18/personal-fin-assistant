import 'dart:convert';

enum PendingTransactionStatus { pending, approved, rejected }

class PendingTransaction {
  final String id;
  final String rawSms;
  final String sender;
  final double amount;
  final String type; // 'debit' or 'credit'
  final String? accountEndsWith;
  final String merchant;
  final DateTime timestamp;
  final PendingTransactionStatus status;
  // Auto-assigned / user overridable
  final String? categoryId;
  final String? goalId;
  final String? liabilityId;
  final String? accountId;

  PendingTransaction({
    required this.id,
    required this.rawSms,
    required this.sender,
    required this.amount,
    required this.type,
    this.accountEndsWith,
    required this.merchant,
    required this.timestamp,
    this.status = PendingTransactionStatus.pending,
    this.categoryId,
    this.goalId,
    this.liabilityId,
    this.accountId,
  });

  PendingTransaction copyWith({
    String? id,
    String? rawSms,
    String? sender,
    double? amount,
    String? type,
    String? accountEndsWith,
    String? merchant,
    DateTime? timestamp,
    PendingTransactionStatus? status,
    String? categoryId,
    String? goalId,
    String? liabilityId,
    String? accountId,
  }) {
    return PendingTransaction(
      id: id ?? this.id,
      rawSms: rawSms ?? this.rawSms,
      sender: sender ?? this.sender,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      accountEndsWith: accountEndsWith ?? this.accountEndsWith,
      merchant: merchant ?? this.merchant,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      categoryId: categoryId ?? this.categoryId,
      goalId: goalId ?? this.goalId,
      liabilityId: liabilityId ?? this.liabilityId,
      accountId: accountId ?? this.accountId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'rawSms': rawSms,
    'sender': sender,
    'amount': amount,
    'type': type,
    'accountEndsWith': accountEndsWith,
    'merchant': merchant,
    'timestamp': timestamp.toIso8601String(),
    'status': status.name,
    'categoryId': categoryId,
    'goalId': goalId,
    'liabilityId': liabilityId,
    'accountId': accountId,
  };

  factory PendingTransaction.fromJson(Map<String, dynamic> json) {
    return PendingTransaction(
      id: json['id'] as String,
      rawSms: json['rawSms'] as String,
      sender: json['sender'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      accountEndsWith: json['accountEndsWith'] as String?,
      merchant: json['merchant'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: PendingTransactionStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String? ?? 'pending'),
        orElse: () => PendingTransactionStatus.pending,
      ),
      categoryId: json['categoryId'] as String?,
      goalId: json['goalId'] as String?,
      liabilityId: json['liabilityId'] as String?,
      accountId: json['accountId'] as String?,
    );
  }

  static List<PendingTransaction> listFromJson(String jsonString) {
    final list = jsonDecode(jsonString) as List;
    return list
        .map((e) => PendingTransaction.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String listToJson(List<PendingTransaction> transactions) {
    return jsonEncode(transactions.map((e) => e.toJson()).toList());
  }
}
