// models/favorite_item_model.dart
class FavoriteItemModel {
  final int id; // id سجل المفضلة
  final int userId;
  final int itemId; // id العنصر المفضل (office, company, project)
  final String itemType; // 'office', 'company', 'project'
  final DateTime createdAt;

  FavoriteItemModel({
    required this.id,
    required this.userId,
    required this.itemId,
    required this.itemType,
    required this.createdAt,
  });

  factory FavoriteItemModel.fromJson(Map<String, dynamic> json) {
    return FavoriteItemModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      itemId: json['item_id'] as int,
      itemType: json['item_type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
