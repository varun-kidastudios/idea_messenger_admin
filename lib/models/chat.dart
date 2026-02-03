import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? categoryId;
  final int messageCount;

  Chat({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.categoryId,
    required this.messageCount,
  });

  factory Chat.fromMap(String id, Map<String, dynamic> data, int msgCount) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.parse(value);
      return DateTime.now();
    }

    return Chat(
      id: id,
      title: data['title'] ?? 'Untitled Chat',
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
      categoryId: data['categoryId'],
      messageCount: msgCount,
    );
  }

  String get categoryName {
    if (categoryId == null) return 'General';
    
    final categoryMap = {
      'youtube': 'YouTube',
      'finance': 'Finance',
      'diy': 'DIY',
      'tech': 'Tech',
      'music': 'Music',
      'business': 'Business',
      'health': 'Health',
      'education': 'Education',
      'fashion': 'Fashion',
      'travel': 'Travel',
      'creation': 'Content',
      'art': 'Art',
      'others': 'Others',
    };
    
    return categoryMap[categoryId] ?? categoryId!;
  }

  // Color coding matching the main app
  int get categoryColor {
    final colorMap = {
      'youtube': 0xFFFF0000,
      'finance': 0xFF4CAF50,
      'diy': 0xFFFF9800,
      'tech': 0xFF2196F3,
      'music': 0xFF9C27B0,
      'business': 0xFF673AB7,
      'health': 0xFF00BCD4,
      'education': 0xFF3F51B5,
      'fashion': 0xFFE91E63,
      'travel': 0xFF8BC34A,
      'creation': 0xFF009688,
      'art': 0xFF9E9E9E,
      'others': 0xFF607D8B,
    };
    
    return colorMap[categoryId] ?? 0xFF607D8B;
  }
}
