class UserFeedback {
  final String id;
  final String ownerId;
  final String ownerName;
  final String category;
  final String message;
  final DateTime createdAt;

  UserFeedback({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.category,
    required this.message,
    required this.createdAt,
  });

  factory UserFeedback.fromJson(Map<String, dynamic> json) {
    return UserFeedback(
      id: json['id'] ?? '',
      ownerId: json['ownerId'] ?? '',
      ownerName: json['ownerName'] ?? '',
      category: json['category'] ?? '',
      message: json['message'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'message': message,
    };
  }
}
