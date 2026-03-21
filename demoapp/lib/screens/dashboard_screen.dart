import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'activity_log_screen.dart';
import 'welcome_screen.dart';

class DashboardScreen extends StatelessWidget {
  final String username;

  DashboardScreen({required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Store Dashboard"),
        backgroundColor: Color.fromARGB(255, 86, 196, 78),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome, $username 👋",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 10),

            Text(
              "Account Status: Pending",
              style: TextStyle(color: Colors.orange),
            ),

            SizedBox(height: 30),

            Card(
              child: ListTile(
                leading: Icon(Icons.person),
                title: Text("Profile"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ProfileScreen()),
                  );
                },
              ),
            ),

            Card(
              child: ListTile(
                leading: Icon(Icons.history),
                title: Text("Activity Log"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ActivityLogScreen()),
                  );
                },
              ),
            ),

            Card(
              child: ListTile(
                leading: Icon(Icons.logout),
                title: Text("Logout"),
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => WelcomeScreen()),
                    (route) => false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}