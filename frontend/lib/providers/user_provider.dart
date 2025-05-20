import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  late int _userId; // Using late keyword
  String _userName = '';
  double _balance = 0.0;
  bool _isBalanceLoaded = false; // To track if balance has been fetched
  
  int get userId => _userId;
  String get userName => _userName;
  double get balance => _balance;
  bool get isBalanceLoaded => _isBalanceLoaded;
  
  void setUserId(int id) {
    _userId = id;
    notifyListeners();
  }
  
  void setUserName(String name) {
    _userName = name;
    notifyListeners();
  }
  
  void setBalance(double balance) {
    _balance = balance;
    _isBalanceLoaded = true;
    notifyListeners();
  }
  
  void updateBalance(double newBalance) {
    _balance = newBalance;
    notifyListeners();
  }
  
  void clearUserData() {
    _userId = 0;
    _userName = '';
    _balance = 0.0;
    _isBalanceLoaded = false;
    notifyListeners();
  }
}