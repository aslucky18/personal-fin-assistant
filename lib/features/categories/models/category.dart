class Category {
  final String id;
  final String userId;
  final String name;
  final String type;
  final String? subCategory;
  final String icon;
  final String colour;
  final DateTime createdAt;

  Category({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    this.subCategory,
    required this.icon,
    required this.colour,
    required this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      subCategory: json['sub_category'] as String?,
      icon: json['icon'] as String? ?? 'category',
      colour: json['colour'] as String? ?? '#0EA5E9',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'sub_category': subCategory,
      'icon': icon,
      'colour': colour,
    };
  }
}
