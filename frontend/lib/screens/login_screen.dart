import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend/components/my_button.dart';
import 'package:frontend/components/mytextfield.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
{
  final storage = const FlutterSecureStorage();
  // text editing controllers
  final mobilenoController = TextEditingController();
  final passwordController = TextEditingController();
  bool isMobileValid = false;
  bool isPasswordValid = false;
  Timer? _debounce;
  String mobileError = '';
  String passwordError = '';
  

  @override
  void dispose() {
    mobilenoController.dispose();
    passwordController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
  //To validate mobile number
  void _onMobileChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        if (value.length == 10 && RegExp(r'^\d{10}$').hasMatch(value)) {
          mobileError = '';
          isMobileValid = true;
        } else {
          mobileError = 'Mobile number must be 10 digits';
          isMobileValid = false;
        }
      });
    });
  }

//Password validation
  void _onPasswordChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        if (value.length >= 8 &&
            RegExp(r'^(?=.*[A-Z])(?=.*[!@#\$&*~])').hasMatch(value)) {
          passwordError = '';
          isPasswordValid = true;
        } else {
          passwordError = 'Password must be 8+ chars, 1 uppercase, 1 special char';
          isPasswordValid = false;
        }
      });
    });
  }


  // sign user in method
  void signUserIn() async
  {
    final apiUrl = dotenv.env['FLASK_BACKEND_URL'];
    print(apiUrl);
    final response = await http.post(
    Uri.parse('$apiUrl/auth/login'),
    headers: {
    'Content-Type': 'application/json', 
  },
    body: jsonEncode({ 
      'mobile_no': mobilenoController.text,
      'password': passwordController.text,
  }),
   );
   final responseData = jsonDecode(response.body);
   if (response.statusCode == 201) {
      
      final access_token = responseData['access_token'];
      final refresh_token = responseData['refresh_token'];
      await storage.delete(key: 'access_token');
      await storage.delete(key: 'refresh_token');
      await storage.write(key: 'access_token', value: access_token);
      await storage.write(key: 'refresh_token', value: refresh_token);
      await storage.write(key : 'user_id', value: responseData['user_id'].toString());
      await storage.write(key: 'user_name',value: responseData['user_name']);
      if (mounted)
      {
          final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.setUserId(responseData['user_id']); 
        userProvider.setUserName(responseData['user_name']);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login Successful')),
      );
      
      Navigator.pushReplacementNamed(context, '/home');
    } 
    else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(responseData['error']),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context,UserProvider,child) {
        return Scaffold(
          backgroundColor: Colors.grey[300],
          body: SafeArea(
            child: SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
              
                    // logo
                    const Icon(
                      Icons.lock,
                      size: 100,
                    ),
              
                    const SizedBox(height: 50),
              
                    // welcome back, you've been missed!
                    Text(
                      'Welcome back you\'ve been missed!',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 16,
                      ),
                    ),
              
                    const SizedBox(height: 25),
              
                    // username textfield
                    MyTextField(
                      controller: mobilenoController,
                      hintText: 'Mobile Number',
                      obscureText: false,
                      prefixIcon: Icon(Icons.phone),
                      onChanged: _onMobileChanged,
                      max_length: 10,
                    ),
                    if (mobileError.isNotEmpty)
                      Text(mobileError, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 10),
              
                    // password textfield
                    MyTextField(
                      controller: passwordController,
                      hintText: 'Password',
                      obscureText: true,
                      prefixIcon: Icon(Icons.lock),
                      onChanged: _onPasswordChanged,
                    ),
                    
                    if (passwordError.isNotEmpty)
                      Text(passwordError, style: const TextStyle(color: Colors.red)),
                    
                    const SizedBox(height: 10),
              
                    // forgot password?
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Forgot Password?',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
              
                    const SizedBox(height: 25),
              
                    // sign in button
                    MyButton(
                      onTap: isMobileValid && isPasswordValid ? signUserIn : null,
                      enabled: isMobileValid && isPasswordValid,
                      text : "Sign In"
                    ),
              
                    const SizedBox(height: 50),
              
              
                    // not a member? register now
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Not a member?',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          child: const Text(
                            'Register now',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: (){
                            Navigator.pushReplacementNamed(context,'/signup');
                          },
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      }
    );
  }
}