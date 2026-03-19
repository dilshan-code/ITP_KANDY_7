import 'package:flutter/material.dart';
import 'package:frontend/core/network/api_client.dart';

// A NotificationItem represents a single alert or message, like a "Low Stock" warning.
class NotificationItem {
  final String id;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    this.type = 'info',
    this.title = '',
    this.message = '',
    this.isRead = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] ?? '',
      type: json['type'] ?? 'info',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

// NotificationProvider handles the list of alerts (like low stock or new sales) in the app.
class NotificationProvider extends ChangeNotifier {
  List<NotificationItem> _notifications = []; // The list of all alerts
  bool _isLoading = false; // Indicates if data is currently being fetched.
  String? _error; // Stores any error message that occurred during API calls.

  List<NotificationItem> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  // A helper that counts how many notifications haven't been opened yet.
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // Pulls the latest alerts from the backend.
  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await ApiClient.get('/notifications');
      _notifications = (response['data'] as List)
          .map((json) => NotificationItem.fromJson(json))
          .toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await ApiClient.put('/notifications/$id/read', {});
      await fetchNotifications();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await ApiClient.put('/notifications/read-all', {});
      await fetchNotifications();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await ApiClient.delete('/notifications/$id');
      await fetchNotifications();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> clearAllNotifications() async {
    try {
      await ApiClient.delete('/notifications');
      await fetchNotifications();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> createNotification({
    required String type,
    required String title,
    required String message,
  }) async {
    try {
      await ApiClient.post('/notifications', {
        'type': type,
        'title': title,
        'message': message,
      });
      await fetchNotifications();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
