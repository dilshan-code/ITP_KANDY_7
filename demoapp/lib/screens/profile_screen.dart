import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {

  final nameController =
      TextEditingController(text: "Store User");
  final phoneController =
      TextEditingController(text: "0771234567");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profile")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [

            TextField(
              controller: nameController,
              decoration:
                  InputDecoration(labelText: "Name"),
            ),

            SizedBox(height: 20),

            TextField(
              controller: phoneController,
              decoration:
                  InputDecoration(labelText: "Phone"),
            ),

            SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  SnackBar(
                      content:
                          Text("Profile Updated")),
                );
              },
              child: Text("Save"),
            )
          ],
        ),
      ),
    );
  }
}