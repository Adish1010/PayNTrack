import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:frontend/screens/addmoney_screen.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isBalanceVisible = false;
  
  final storage = const FlutterSecureStorage();
  @override
  void initState() {
    super.initState();
    _fetchBalance(); // Fetch balance when screen loads
  }
  
  final apiUrl = dotenv.env['FLASK_BACKEND_URL'];
  String balanceError="";

  Future<void> _fetchBalance() async
  {
  final userProvider = Provider.of<UserProvider>(context, listen: false);
  int userId = userProvider.userId;
  try {
    final response = await http.post(
      Uri.parse('$apiUrl/auth/fetchbalance'),
      headers: {
        'Authorization': 'Bearer ${await storage.read(key: 'access_token')}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({"user_id": userId}),
    );
    print(userId);
    print(await storage.read(key: 'access_token'));
    
    final responseData = jsonDecode(response.body);
    if (response.statusCode == 200) {
      // Update balance in provider instead of returning
      userProvider.setBalance(responseData["balance"]);
      balanceError="";
    }
    else if (response.statusCode == 401) {
      bool refreshed = await _refreshToken();
      if (refreshed) {
        return _fetchBalance(); // Retry
      } else {
        balanceError = "Session expired. Please login again.";
        _logoutUser(context);
      }
    }
    else {
      balanceError = "Couldn't fetch balance";
    }
  } catch (e) {
    balanceError = "Error";
  }
}

// Function to refresh token
Future<bool> _refreshToken() async {
  try {
    final refreshToken = await storage.read(key: 'refresh_token');
    if (refreshToken == null) return false;

    final response = await http.post(
      Uri.parse('$apiUrl/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"refresh_token": refreshToken}),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      await storage.write(key: 'access_token', value: responseData['access_token']);
      return true;
    } else {
      return false;
    }
  } catch (e) {
    return false;
  }
}

// Function to logout user (clear tokens and navigate to login)
void _logoutUser(BuildContext context) {
  storage.deleteAll();
  Navigator.pushReplacementNamed(context, '/login');
}

void toggleBalanceVisibility() {
    setState(() {
      isBalanceVisible = !isBalanceVisible;
    });
    _fetchBalance();
    if (isBalanceVisible) {
      Future.delayed(Duration(seconds: 5), () {
        setState(() {
          isBalanceVisible = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) 
  {
    String userName = Provider.of<UserProvider>(context).userName;
    String firstName = userName.split(' ')[0];
    
    return Consumer<UserProvider>(
      builder: (context,UserProvider,child) {
        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
             elevation: 0,
          title: Row(
        children: [
          
          const SizedBox(width: 8),
          Center(
            child: const Text(
              "PayNTrack",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ],
          ),
          actions: [
        IconButton(
          icon: const Icon(Icons.person, color: Colors.black),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          },
        ),
          ],
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                    
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      
                      children: [
                        Text("Welcome, $firstName", style: TextStyle(color: Colors.white, fontSize: 24,fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ElevatedButton(
                                onPressed: toggleBalanceVisibility,
                                style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: Colors.black,
                                          shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                child: Text(isBalanceVisible?(balanceError==""?UserProvider.balance.toStringAsFixed(2):balanceError):"Check balance"),
                                ),
                                SizedBox(width:8.0),
                              ElevatedButton(
                                onPressed: () {
                                Navigator.push(context,MaterialPageRoute(builder: (context) => AddMoneyScreen()));
                                },
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[700],
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                   ),
                                 ),
                                child: Text("Add Money"),
                                ),
                            ],
                          ),
                        ),
                        
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  buildSection("People", [Icons.person, Icons.person, Icons.person]),
                  buildSection("Groups", [Icons.group, Icons.group, Icons.add]),
                  buildSection("Business", [Icons.store, Icons.store, Icons.store]),
                  buildSection("Recharge", [Icons.phone_android, Icons.tv, Icons.cable, Icons.local_parking]),
                  buildSection("Utilities", [
                    Icons.electric_bolt, Icons.water, Icons.gas_meter, Icons.wifi,
                    Icons.credit_card, Icons.home, Icons.security, Icons.local_gas_station
                  ]),
                ],
              ),
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
              BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
              BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: "Scan"),
              BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: "Expense"),
              BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
            ],
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.grey,
          ),
        );
      }
    );
  }

  Widget buildSection(String title, List<IconData> icons) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Wrap(
            spacing: 16,
            children: icons
                .map((icon) => CircleAvatar(
                      backgroundColor: Colors.blue[50],
                      child: Icon(icon, color: Colors.blue),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}