import 'package:flutter/material.dart';

class ActivityLogScreen extends StatelessWidget {

  final List<String> logs = [
    "Login - 12 Feb 2026 - 10:30 AM",
    "Profile Updated - 12 Feb 2026 - 10:45 AM",
    "Logout - 12 Feb 2026 - 11:00 AM"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Activity Log")),
      body: ListView.builder(
        itemCount: logs.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Icon(Icons.history),
            title: Text(logs[index]),
          );
        },
      ),
    );
  }
}