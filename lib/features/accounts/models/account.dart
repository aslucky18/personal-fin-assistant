class Account {
  final String id;
  final String userId;
  final String bankName;
  final String type;
  final String endsWith;
  final DateTime createdAt;

  Account({
    required this.id,
    required this.userId,
    required this.bankName,
    required this.type,
    required this.endsWith,
    required this.createdAt,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      bankName: json['bank_name'] as String,
      type: json['type'] as String,
      endsWith: json['ends_with'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {'bank_name': bankName, 'type': type, 'ends_with': endsWith};
  }
}
