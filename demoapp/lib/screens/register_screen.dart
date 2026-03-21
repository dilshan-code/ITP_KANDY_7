import 'package:flutter/material.dart';
import 'otp_screen.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  final _formKey = GlobalKey<FormState>();

  final TextEditingController storeNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  String selectedOption = "Phone"; // Default selection

  @override
  void dispose() {
    storeNameController.dispose();
    usernameController.dispose();
    contactController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }


  void _submit() {
    if (_formKey.currentState!.validate()) {

      // CREATE user and save
      UserService.addUser(
        UserModel(
          storeName: storeNameController.text.trim(),
          username: usernameController.text.trim(),
          contact: contactController.text.trim(),
          password: passwordController.text.trim(),
        ),
      );

      // Navigate to OTP
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OTPScreen(
            contact: contactController.text.trim(),
          ),
        ),
      );
    }
  }

  InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [

              const SizedBox(height: 60),

              const Text(
                "REGISTER",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 30),

              // Store Name
              TextFormField(
                controller: storeNameController,
                decoration: inputDecoration("Store Name"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Store Name is required";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Username
              TextFormField(
                controller: usernameController,
                decoration: inputDecoration("Username"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Username is required";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Radio Buttons (Phone / Email)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Radio(
                    value: "Phone",
                    groupValue: selectedOption,
                    onChanged: (value) {
                      setState(() {
                        selectedOption = value!;
                        contactController.clear();
                      });
                    },
                  ),
                  const Text("Phone"),

                  Radio(
                    value: "Email",
                    groupValue: selectedOption,
                    onChanged: (value) {
                      setState(() {
                        selectedOption = value!;
                        contactController.clear();
                      });
                    },
                  ),
                  const Text("Email"),
                ],
              ),

              const SizedBox(height: 10),

              // Phone or Email Field
              TextFormField(
                controller: contactController,
                keyboardType: selectedOption == "Phone"
                    ? TextInputType.number
                    : TextInputType.emailAddress,
                decoration: inputDecoration(
                    selectedOption == "Phone"
                        ? "Enter 10-digit Phone"
                        : "Enter Email"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "This field is required";
                  }

                  if (selectedOption == "Phone") {
                    if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                      return "Phone must be exactly 10 digits";
                    }
                  } else {
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return "Enter valid email";
                    }
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Password
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: inputDecoration("Password"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Password is required";
                  }
                  if (value.length < 8) {
                    return "Password must be at least 8 characters";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Confirm Password
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: inputDecoration("Confirm Password"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Confirm Password is required";
                  }
                  if (value != passwordController.text) {
                    return "Passwords do not match";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 55),
                ),
                onPressed: _submit,
                child: const Text("CREATE ACCOUNT"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}