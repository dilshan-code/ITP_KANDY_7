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
                    padding: const EdgeInsets.all(12),
                    itemCount: notifs.length,
                    itemBuilder: (context, i) => _NotifCard(
                        notif: notifs[i], service: _service),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final NotificationModel notif;
  final NotificationService service;

  const _NotifCard({required this.notif, required this.service});

  Color get _accentColor {
    switch (notif.type) {
      case 'credit':
        return Colors.red;
      case 'stock':
        return Colors.orange;
      case 'report':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  IconData get _icon {
    switch (notif.type) {
      case 'credit':
        return Icons.warning_amber_rounded;
      case 'stock':
        return Icons.inventory_2;
      case 'report':
        return Icons.bar_chart;
      default:
        return Icons.payment;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border:
            Border(left: BorderSide(color: _accentColor, width: 3)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _accentColor.withOpacity(0.15),
          child: Icon(_icon, color: _accentColor, size: 20),
        ),
        title: Text(notif.title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notif.message,
                style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Row(children: [
              if (!notif.isRead)
                TextButton(
                  onPressed: () => service.markAsRead(notif.id),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Mark read',
                      style: TextStyle(
                          fontSize: 11, color: Colors.green)),
                ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () => service.delete(notif.id),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize:
                      MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Delete',
                    style: TextStyle(
                        fontSize: 11, color: Colors.red)),
              ),
            ])
          ],
        ),
        trailing: notif.isRead
            ? null
            : Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                    color: _accentColor,
                    shape: BoxShape.circle),
              ),
      ),
    );
  }
}