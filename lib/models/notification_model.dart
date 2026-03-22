class NotificationModel {
  final String id;
  final String type;
  final String category;
  final String title;
  final String message;
  final bool isRead;
  final int timestamp;
  final String? relatedId;
  final double? amount;
  final int? daysOverdue;
  final String severity;

  NotificationModel({
    required this.id,
    required this.type,
    required this.category,
    required this.title,
    required this.message,
    required this.isRead,
    required this.timestamp,
    this.relatedId,
    this.amount,
    this.daysOverdue,
    this.severity = 'medium',
  });

  factory NotificationModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return NotificationModel(
      id: id,
      type: map['type'] ?? '',
      category: map['category'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      isRead: map['isRead'] ?? false,
      timestamp: map['timestamp'] ?? 0,
      relatedId: map['relatedId'],
      amount: map['amount']?.toDouble(),
      daysOverdue: map['daysOverdue'],
      severity: map['severity'] ?? 'medium',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'category': category,
      'title': title,
      'message': message,
      'isRead': isRead,
      'timestamp': timestamp,
      'relatedId': relatedId,
      'amount': amount,
      'daysOverdue': daysOverdue,
      'severity': severity,
      'createdBy': 'system',
    };
  }
}
