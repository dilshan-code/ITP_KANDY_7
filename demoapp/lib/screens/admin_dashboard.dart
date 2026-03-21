import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import 'welcome_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<String> storeStatus = [];

  @override
  void initState() {
    super.initState();
    storeStatus = List.generate(
      UserService.getUsers().length,
      (index) => "Pending",
    );
  }

  void updateStatus(int index, String status) {
    setState(() {
      storeStatus[index] = status;
    });
  }

  void _showEditDialog(int index, UserModel user) {
    final storeController = TextEditingController(text: user.storeName);
    final usernameController = TextEditingController(text: user.username);
    final contactController = TextEditingController(text: user.contact);

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Update User"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: storeController,
                decoration: const InputDecoration(labelText: "Store Name"),
              ),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: "Username"),
              ),
              TextField(
                controller: contactController,
                decoration: const InputDecoration(labelText: "Contact"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                UserService.updateUser(
                  index,
                  UserModel(
                    storeName: storeController.text,
                    username: usernameController.text,
                    contact: contactController.text,
                    password: user.password,
                  ),
                );
                setState(() {});
                Navigator.pop(context);
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final users = UserService.getUsers();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: const Color.fromARGB(255, 88, 196, 78),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "Total Stores: ${users.length}",
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: users.isEmpty
                  ? const Center(
                      child: Text("No Users Registered"),
                    )
                  : ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        if (storeStatus.length <= index) {
                          storeStatus.add("Pending");
                        }
                        return Card(
                          child: ListTile(
                            title: Text(user.storeName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Username: ${user.username}"),
                                Text("Contact: ${user.contact}"),
                                Text("Status: ${storeStatus[index]}"),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // APPROVE
                                IconButton(
                                  icon: const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  ),
                                  tooltip: "Approve",
                                  onPressed: () =>
                                      updateStatus(index, "Approved"),
                                ),
                                // SUSPEND
                                IconButton(
                                  icon: const Icon(
                                    Icons.cancel,
                                    color: Colors.red,
                                  ),
                                  tooltip: "Suspend",
                                  onPressed: () =>
                                      updateStatus(index, "Suspended"),
                                ),
                                // UPDATE
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  tooltip: "Update",
                                  onPressed: () => _showEditDialog(index, user),
                                ),
                                // DELETE
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.black,
                                  ),
                                  tooltip: "Delete",
                                  onPressed: () {
                                    setState(() {
                                      UserService.deleteUser(index);
                                      storeStatus.removeAt(index);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (_) => WelcomeScreen()),
                  (route) => false,
                );
              },
              child: const Text("Logout"),
            ),
          ],
        ),
      ),
    );
  }
}