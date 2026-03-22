import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/notification_model.dart';

class NotificationService {
  final DatabaseReference _ref = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://notification-47e11-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref('notifications');

  Future<void> addNotification(NotificationModel notification) async {
    await _ref.push().set({
      ...notification.toMap(),
      'timestamp': ServerValue.timestamp,
    });
  }

  Stream<List<NotificationModel>> getNotifications() {
    return _ref.orderByChild('timestamp').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];
      return data.entries
          .map((e) => NotificationModel.fromMap(
                e.key.toString(),
                Map<dynamic, dynamic>.from(e.value),
              ))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    });
  }

  Stream<List<NotificationModel>> getByCategory(String category) {
    return _ref
        .orderByChild('category')
        .equalTo(category)
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];
      return data.entries
          .map((e) => NotificationModel.fromMap(
                e.key.toString(),
                Map<dynamic, dynamic>.from(e.value),
              ))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    });
  }

  Future<void> markAsRead(String id) async {
    await _ref.child('$id/isRead').set(true);
  }

  Future<void> delete(String id) async {
    await _ref.child(id).remove();
  }

  Stream<int> getUnreadCount() {
    return _ref.orderByChild('isRead').equalTo(false).onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      return data?.length ?? 0;
    });
  }
}