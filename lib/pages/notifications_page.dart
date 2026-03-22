import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import 'reports_page.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationService _service = NotificationService();
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Credit',
    'Stock',
    'System'
  ];

  Stream<List<NotificationModel>> get _stream {
    if (_selectedCategory == 'All') return _service.getNotifications();
    return _service.getByCategory(_selectedCategory);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B5E20),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: StreamBuilder<int>(
          stream: _service.getUnreadCount(),
          builder: (context, snap) {
            final count = snap.data ?? 0;
            return Row(children: [
              const Text('Notifications',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              if (count > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('$count',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.white)),
                )
              ]
            ]);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2E7D32),
        icon: const Icon(Icons.download, color: Colors.white),
        label: const Text('Reports',
            style: TextStyle(color: Colors.white, fontSize: 13)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReportsPage(),
            ),
          );
        },
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            child: Row(
              children: _categories.map((cat) {
                final selected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedCategory = cat),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: selected
                              ? Colors.white
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(cat,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : Colors.white60,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        )),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF1F8E9),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: StreamBuilder<List<NotificationModel>>(
                stream: _stream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }
                  final notifs = snapshot.data ?? [];
                  if (notifs.isEmpty) {
                    return const Center(
                        child: Text('No notifications'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(12