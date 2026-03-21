import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 243, 244, 243),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Spacer(),

          Text(
            "Let's Go Shopping",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 60,
              color: const Color.fromARGB(255, 98, 199, 77),
              fontWeight: FontWeight.bold,
            ),
          ),

          Spacer(),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 69, 189, 69),
                    minimumSize: Size(double.infinity, 55),
                  ),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => LoginScreen()));
                  },
                  child: Text("LOGIN",
                      style: TextStyle(color: const Color.fromARGB(255, 239, 242, 239))),
                ),

                SizedBox(height: 15),

                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: const Color.fromARGB(255, 97, 195, 82)),
                    minimumSize: Size(double.infinity, 55),
                  ),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => RegisterScreen()));
                  },
                  child: Text("REGISTER",
                      style: TextStyle(color: const Color.fromARGB(255, 77, 217, 91))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}