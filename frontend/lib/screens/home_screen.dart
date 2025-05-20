import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class HomePage extends StatelessWidget {
  HomePage({Key? key}) : super(key: key);

  // Instance of secure storage for JWT tokens
  
  final _secureStorage = const FlutterSecureStorage();

  // Logout function
  void logout(BuildContext context) async {
    // Clear the JWT token from secure storage
    await _secureStorage.deleteAll();

    // Navigate to Login Page
    Navigator.pushReplacementNamed(
      context,
      '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Screen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Welcome to the Home Screen!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
