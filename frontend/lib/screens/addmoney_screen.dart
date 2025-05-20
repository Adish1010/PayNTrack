import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class AddMoneyScreen extends StatefulWidget {
  @override
  _AddMoneyScreenState createState() => _AddMoneyScreenState();
}
class _AddMoneyScreenState extends State<AddMoneyScreen> {
  
  TextEditingController amountController = TextEditingController();
  String selectedPaymentMethod = 'UPI Payment';
  final apiUrl = dotenv.env['FLASK_BACKEND_URL'];
  String balanceError="";
  final storage = const FlutterSecureStorage();
  Timer? _debounce;
  String amountError='';
  double amount = 0.0;
  @override
  void initState() {
    super.initState();
    _fetchBalance(); // Fetch balance when screen loads
  }

  Future<void> _fetchBalance() async
  {
  final userProvider = Provider.of<UserProvider>(context, listen: false);
  int userId = userProvider.userId;
  print("Sending Authorization header: Bearer ${await storage.read(key: 'access_token')}");

  try {
    final response = await http.post(
      Uri.parse('$apiUrl/auth/fetchbalance'),
      headers: {
        'Authorization': 'Bearer ${await storage.read(key: 'access_token')}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({"user_id": userId}),
    );
    print(jsonEncode({"user_id": userId}));
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


  Future<void> _addMoney() async {
  final userProvider = Provider.of<UserProvider>(context, listen: false);
  double? amount = double.tryParse(amountController.text);
  try {
    final response = await http.post(
      Uri.parse('$apiUrl/auth/addmoney'), 
      headers: {
        'Authorization': 'Bearer ${await storage.read(key: 'access_token')}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "user_id": userProvider.userId,
        "amount": amount,
      }),
    );
    
    final responseData = jsonDecode(response.body);
    
    if (response.statusCode == 200) {
      userProvider.updateBalance(responseData['new_balance']);
      if(mounted)
      {
        Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentSuccessScreen(amount: amount, method: selectedPaymentMethod),
        ),
      );
      }
      
    } 
    else if (response.statusCode == 401) 
    {
      // Unauthorized - Try to refresh the token
      bool refreshed = await _refreshToken();
      if (refreshed) {
        // Retry adding money with new token
        return _addMoney();
      } else {
        if(mounted)
        {
          _handleAddMoneyError("Session expired. Please login again.");
          _logoutUser(context);
        }
      }
    } else {
      // Handle other error responses
      String errorMessage = responseData['error'] ?? 'Failed to add money';
      _handleAddMoneyError(errorMessage);
    }
    
  } catch (e) {
    if(mounted)
    {
      _handleAddMoneyError('Network error. Please try again.');
    } 
  }
}

void _handleAddMoneyError(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ),
  );
}
void _validateAmount(String value) {
    setState(() {
      String input = amountController.text;
      
      if (input.isEmpty) {
        amountError = '';
        amount=0.0;
        return;
      }
      
      // Try to parse the input
      double? parsedAmount = double.tryParse(input);
      
      if (parsedAmount == null) {
        amountError = 'Please enter a valid number';
        amount = 0.0;
      } else if (parsedAmount <= 0) {
        amountError = 'Amount must be greater than 0';
        amount = 0.0;
      } else if (parsedAmount > 10000) { // Example max limit
        amountError = 'Maximum amount is \$10,000';
        amount = 0.0;
      } else {
        amountError = '';
        amount = parsedAmount;
      }
    });
  }
void _onAmountChanged(String value) {
  if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
       _validateAmount(value);
});
    }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context,UserProvider,child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('PayNTrack Wallet'),
            backgroundColor: Colors.blue,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Balance', style: TextStyle(fontSize: 18)),
                Text('₹${balanceError==""?UserProvider.balance.toStringAsFixed(2):balanceError}', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Enter amount',
                    border: OutlineInputBorder(),
                    
                  ),
                  onChanged: _onAmountChanged,
                ),
                if (amountError.isNotEmpty)
                Text(amountError, style: const TextStyle(color: Colors.red)),
                SizedBox(height: 16),
                Text('Payment Mode', style: TextStyle(fontSize: 18)),
                Row(
                  children: [
                    Radio(
                      value: 'UPI Payment',
                      groupValue: selectedPaymentMethod,
                      onChanged: (value) {
                        setState(() => selectedPaymentMethod = value.toString());
                      },
                    ),
                    Text('UPI Payment'),
                    Radio(
                      value: 'Net Banking',
                      groupValue: selectedPaymentMethod,
                      onChanged: (value) {
                        setState(() => selectedPaymentMethod = value.toString());
                      },
                    ),
                    Text('Net Banking'),
                  ],
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: (amount>0&&amountError=='')?()=>_addMoney():null,
                  style: ElevatedButton.styleFrom(backgroundColor: (amount>0&&amountError=='')?Colors.blue:Colors.grey),
                  child: Text('Proceed to Add Money'),
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}

class PaymentSuccessScreen extends StatelessWidget {
  final double? amount;
  final String method;

  const PaymentSuccessScreen({super.key, required this.amount, required this.method});

  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pop(context);
    });

    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 100),
            SizedBox(height: 16),
            Text('Payment Successful!', style: TextStyle(color: Colors.white, fontSize: 24)),
            Text('₹$amount added via $method', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}