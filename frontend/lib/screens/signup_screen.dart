// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend/components/my_button.dart';
import 'package:frontend/components/mytextfield.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';


class RegistrationFlow extends StatefulWidget {
  const RegistrationFlow({super.key});
  @override
  _RegistrationFlowState createState() => _RegistrationFlowState();
}

class _RegistrationFlowState extends State<RegistrationFlow> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final storage = const FlutterSecureStorage();
  // Controllers for user input
  final TextEditingController emailController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController(); // Personal
  final TextEditingController merchantNameController = TextEditingController(); // Business
  final TextEditingController businessNameController = TextEditingController(); // Business
  final TextEditingController locationController = TextEditingController(); // Business
  final TextEditingController pinController = TextEditingController();
  final TextEditingController confirmPinController = TextEditingController();
  // Validation state
  String emailError = '';
  String mobileError = '';
  String passwordError = '';
  String confirmPasswordError = '';
  String fullNameError = ''; // Personal
  String merchantNameError = ''; // Business
  String businessNameError = ''; // Business
  String locationError = ''; // Business
  String pinError='';
  String confirmPinError='';
  bool isEmailValid = false;
  bool isMobileValid = false;
  bool isPasswordValid = false;
  bool isConfirmPasswordValid = false;
  bool isFullNameValid = false; // Personal
  bool isMerchantNameValid = false; // Business
  bool isBusinessNameValid = false; // Business
  bool isLocationValid = false; // Business
  bool isPinValid = false;
  bool isConfirmPinValid = false;
  // Dropdown selections
  String? selectedJobTitle; // Personal
  String? selectedBusinessCategory; // Business
  bool isJobTitleValid = false; // Personal
  bool isBusinessCategoryValid = false; // Business
  final List<String> jobTitles = ['Engineer', 'Teacher', 'Student', 'Doctor', 'Other'];
  final List<String> businessCategories = ['Retail', 'Food & Beverage', 'Services', 'Technology', 'Other'];

  // User type selection
  UserType? _selectedType;

  // Debouncing for validation
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    emailController.dispose();
    mobileController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    fullNameController.dispose();
    merchantNameController.dispose();
    businessNameController.dispose();
    locationController.dispose();
    pinController.dispose();
    confirmPinController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void nextStep() {
    if (_currentStep < 4) {
      setState(() {
        _currentStep++;
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.ease,
        );
      });
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.ease,
        );
      });
    }
  }

  // Validation methods
  void _onEmailChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        if (RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          emailError = '';
          isEmailValid = true;
        } else {
          emailError = 'Enter a valid email (e.g., user@example.com)';
          isEmailValid = false;
        }
      });
    });
  }

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
        // Re-validate confirm password if it exists
        if (confirmPasswordController.text.isNotEmpty) {
          _onConfirmPasswordChanged(confirmPasswordController.text);
        }
      });
    });
  }

  void _onConfirmPasswordChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        if (value == passwordController.text) {
          confirmPasswordError = '';
          isConfirmPasswordValid = true;
        } else {
          confirmPasswordError = 'Passwords do not match';
          isConfirmPasswordValid = false;
        }
      });
    });
  }

  void _onFullNameChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        if (value.trim().isNotEmpty) {
          fullNameError = '';
          isFullNameValid = true;
        } else {
          fullNameError = 'Full name is required';
          isFullNameValid = false;
        }
      });
    });
  }

  void _onMerchantNameChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        if (value.trim().isNotEmpty) {
          merchantNameError = '';
          isMerchantNameValid = true;
        } else {
          merchantNameError = 'Merchant name is required';
          isMerchantNameValid = false;
        }
      });
    });
  }

  void _onBusinessNameChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        if (value.trim().isNotEmpty) {
          businessNameError = '';
          isBusinessNameValid = true;
        } else {
          businessNameError = 'Business name is required';
          isBusinessNameValid = false;
        }
      });
    });
  }

  void _onLocationChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        if (value.trim().isNotEmpty) {
          locationError = '';
          isLocationValid = true;
        } else {
          locationError = 'Location is required';
          isLocationValid = false;
        }
      });
    });
  }

  void _onPinChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        if (value.length == 4 && RegExp(r'^\d{4}$').hasMatch(value)) {
          pinError = '';
          isPinValid = true;
        } else {
          pinError = 'PIN must be 4 digits';
          isPinValid = false;
        }
      });
    });
  }
  
  void _onConfirmPinChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        if (value == pinController.text) {
          confirmPinError = '';
          isConfirmPinValid = true;
        } else {
          confirmPinError = 'PINs do not match';
          isConfirmPinValid = false;
        }
      });
    });
  }
  
  void _resetForm() {
    setState(() {
      emailController.clear();
      mobileController.clear();
      passwordController.clear();
      confirmPasswordController.clear();
      fullNameController.clear();
      merchantNameController.clear();
      businessNameController.clear();
      locationController.clear();
      pinController.clear();
      confirmPinController.clear();

      emailError = '';
      mobileError = '';
      passwordError = '';
      confirmPasswordError = '';
      fullNameError = '';
      merchantNameError = '';
      businessNameError = '';
      locationError = '';
      pinError = '';
      confirmPinError = '';
      isEmailValid = false;
      isMobileValid = false;
      isPasswordValid = false;
      isConfirmPasswordValid = false;
      isFullNameValid = false;
      isMerchantNameValid = false;
      isBusinessNameValid = false;
      isLocationValid = false;
      isPinValid = false;
      isConfirmPinValid = false;

      selectedJobTitle = null;
      selectedBusinessCategory = null;
      isJobTitleValid = false;
      isBusinessCategoryValid = false;

      _selectedType = null;

      _currentStep = 0;
    });
    _pageController.jumpToPage(0);
  }
  void _submitForm() async{
   final apiUrl = dotenv.env['FLASK_BACKEND_URL'];
   final response = await http.post(
    Uri.parse('$apiUrl/auth/signup'),
    headers: {
    'Content-Type': 'application/json', 
  },
    body: jsonEncode({
        'usertype': _selectedType.toString().split('.').last,
        'email': emailController.text,
        'mobile_no': mobileController.text,
        'password': passwordController.text,
        'pin': pinController.text,
        if (_selectedType == UserType.personal) ...{
          'full_name': fullNameController.text,
          'job_title': selectedJobTitle,
        } else ...{
          'merchant_name': merchantNameController.text,
          'business_name': businessNameController.text,
          'business_category': selectedBusinessCategory,
          'location': locationController.text,
        },
      }),
    );
    final responseData = jsonDecode(response.body);
    if (response.statusCode == 201) {
      
      final access_token = responseData['access_token'];
      final refresh_token = responseData['refresh_token'];
    
      await storage.write(key: 'access_token', value: access_token);
      await storage.write(key: 'refresh_token', value: refresh_token);
      await storage.write(key : 'user_id', value: responseData['user_id'].toString());
      await storage.write(key : 'user_name', value: responseData['user_name']);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.setUserId(responseData['user_id']); 
      userProvider.setUserName(responseData['user_name']);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration Successful')),
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
      await Future.delayed(const Duration(seconds: 2));
      _resetForm();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context,UserProvider,child) {
        return Scaffold(
          backgroundColor: Colors.grey[300],
          
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStep1(), // User type selection
                    _buildStep2(), // Common details
                    _buildStep3(), // Type-specific details
                    _buildStep4(), //Pin Generation
                    _buildStep5() // Confirmation
                  ],
                ),
              ),
            ),
          ),
        );
      }
    );
  }

  // Step 1: Select User Type
  // Step 1: Select User Type
  Widget _buildStep1() {
    return SingleChildScrollView(

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 150),
    
           Text(
            'Register - Step ${_currentStep + 1} / 5',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 25),
          Text(
            'Select User Type',
            style: TextStyle(color: Colors.grey[700], fontSize: 16),
          ),
          const SizedBox(height: 25),
          // Personal Card
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedType = UserType.personal;
              });
            },
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.grey[300]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 40, color: Colors.blue),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Personal',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'For individual users',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.check_circle,
                      color: _selectedType == UserType.personal ? Colors.blue : Colors.transparent,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Business Card
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedType = UserType.business;
              });
            },
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.grey[300]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.business, size: 40, color: Colors.blue),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Business',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'For merchants and businesses',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.check_circle,
                      color: _selectedType == UserType.business ? Colors.blue : Colors.transparent,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 25),
          MyButton(
            onTap: _selectedType != null ? nextStep : null,
            enabled: _selectedType != null,
            text:"Next",
          ),
          const SizedBox(height: 50),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account?',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text(
                  'Login',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  // Step 2: Common Details (Email, Mobile, Password, Confirm Password)
  Widget _buildStep2() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 50),
          Text(
            'Register - Step ${_currentStep + 1} / 4',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 25),
          Text(
            'Enter Your Details',
            style: TextStyle(color: Colors.grey[700], fontSize: 16),
          ),
          const SizedBox(height: 25),
          MyTextField(
            controller: emailController,
            hintText: 'Email',
            obscureText: false,
            prefixIcon: const Icon(Icons.email),
            onChanged: _onEmailChanged,
          ),
          if (emailError.isNotEmpty)
            Text(emailError, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 10),
          MyTextField(
            controller: mobileController,
            hintText: 'Mobile Number',
            obscureText: false,
            prefixIcon: const Icon(Icons.phone),
            onChanged: _onMobileChanged,
            max_length: 10,
          ),
          if (mobileError.isNotEmpty)
            Text(mobileError, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 10),
          MyTextField(
            controller: passwordController,
            hintText: 'Password',
            obscureText: true,
            prefixIcon: const Icon(Icons.lock),
            onChanged: _onPasswordChanged,
          ),
          if (passwordError.isNotEmpty)
            Text(passwordError, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 10),
          MyTextField(
            controller: confirmPasswordController,
            hintText: 'Confirm Password',
            obscureText: true,
            prefixIcon: const Icon(Icons.lock),
            onChanged: _onConfirmPasswordChanged,
            max_length: passwordController.toString().length ,
          ),
          if (confirmPasswordError.isNotEmpty)
            Text(confirmPasswordError, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: previousStep,
                child: const Text('Back'),
              ),
              MyButton(
                onTap: isEmailValid && isMobileValid && isPasswordValid && isConfirmPasswordValid
                    ? nextStep
                    : null,
                enabled: isEmailValid && isMobileValid && isPasswordValid && isConfirmPasswordValid,
                text:"Next",
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Step 3: Type-Specific Details
  Widget _buildStep3() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 50),
          Text(
            'Register - Step ${_currentStep + 1} / 4',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 25),
          Text(
            _selectedType == UserType.personal ? 'Personal Details' : 'Business Details',
            style: TextStyle(color: Colors.grey[700], fontSize: 16),
          ),
          const SizedBox(height: 25),
          if (_selectedType == UserType.personal) ...[
            MyTextField(
              controller: fullNameController,
              hintText: 'Full Name',
              obscureText: false,
              prefixIcon: const Icon(Icons.person),
              onChanged: _onFullNameChanged,
            ),
            if (fullNameError.isNotEmpty)
              Text(fullNameError, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedJobTitle,
              hint: const Text('Select Job Title'),
              items: jobTitles.map((String title) {
                return DropdownMenuItem<String>(
                  value: title,
                  child: Text(title),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedJobTitle = value;
                  isJobTitleValid = value != null;
                });
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.work),
              ),
            ),
            if (!isJobTitleValid && selectedJobTitle == null)
              const Text('Job title is required', style: TextStyle(color: Colors.red)),
          ] else ...[
            MyTextField(
              controller: merchantNameController,
              hintText: 'Merchant Name',
              obscureText: false,
              prefixIcon: const Icon(Icons.person),
              onChanged: _onMerchantNameChanged,
            ),
            if (merchantNameError.isNotEmpty)
              Text(merchantNameError, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 10),
            MyTextField(
              controller: businessNameController,
              hintText: 'Business Name',
              obscureText: false,
              prefixIcon: const Icon(Icons.business),
              onChanged: _onBusinessNameChanged,
            ),
            if (businessNameError.isNotEmpty)
              Text(businessNameError, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedBusinessCategory,
              hint: const Text('Select Business Category'),
              items: businessCategories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedBusinessCategory = value;
                  isBusinessCategoryValid = value != null;
                });
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
            ),
            if (!isBusinessCategoryValid && selectedBusinessCategory == null)
              const Text('Business category is required', style: TextStyle(color: Colors.red)),
            const SizedBox(height: 10),
            MyTextField(
              controller: locationController,
              hintText: 'Location',
              obscureText: false,
              prefixIcon: const Icon(Icons.location_on),
              onChanged: _onLocationChanged,
            ),
            if (locationError.isNotEmpty)
              Text(locationError, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: previousStep,
                child: const Text('Back'),
              ),
              MyButton(
                onTap: _selectedType == UserType.personal
                    ? (isFullNameValid && isJobTitleValid ? nextStep : null)
                    : (isMerchantNameValid && isBusinessNameValid && isBusinessCategoryValid && isLocationValid ? nextStep : null),
                enabled: _selectedType == UserType.personal
                    ? (isFullNameValid && isJobTitleValid)
                    : (isMerchantNameValid && isBusinessNameValid && isBusinessCategoryValid && isLocationValid),
                    text:"Next",
              ),
            ],
          ),
        ],
      ),
    );
  }
  // Step 4: PIN Setup (New)
  Widget _buildStep4() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 50),
          Text(
            'Register - Step ${_currentStep + 1} / 5', // Updated to 5 steps
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 25),
          Text(
            'Set Up Your PIN',
            style: TextStyle(color: Colors.grey[700], fontSize: 16),
          ),
          const SizedBox(height: 25),
          MyTextField(
            controller: pinController,
            hintText: 'Enter 4-digit PIN',
            obscureText: true,
            prefixIcon: const Icon(Icons.lock),
            onChanged: _onPinChanged,
            max_length: 4,
            keyboardType: TextInputType.number,
          ),
          if (pinError.isNotEmpty)
            Text(pinError, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 10),
          MyTextField(
            controller: confirmPinController,
            hintText: 'Confirm 4-digit PIN',
            obscureText: true,
            prefixIcon: const Icon(Icons.lock),
            onChanged: _onConfirmPinChanged,
            max_length: 4,
            keyboardType: TextInputType.number,
          ),
          if (confirmPinError.isNotEmpty)
            Text(confirmPinError, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 25),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: previousStep,
                child: const Text('Back'),
              ),
              MyButton(
                onTap: isPinValid ? nextStep : null,
                enabled: isPinValid,
                text: "Next",
              ),
            ],
          ),
        ],
      ),
    );
  }
  // Step 4: Confirmation
  Widget _buildStep5() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 50),
        Text(
          'Register - Step ${_currentStep + 1} / 5',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 25),
        Text(
          'Confirm Your Details',
          style: TextStyle(color: Colors.grey[700], fontSize: 16),
        ),
        const SizedBox(height: 25),
        Text('User Type: ${_selectedType.toString().split('.').last}'),
        Text('Email: ${emailController.text}'),
        Text('Mobile: ${mobileController.text}'),
        const SizedBox(height: 10),
        if (_selectedType == UserType.personal) ...[
          Text('Full Name: ${fullNameController.text}'),
          Text('Job Title: $selectedJobTitle'),
        ] else ...[
          Text('Merchant Name: ${merchantNameController.text}'),
          Text('Business Name: ${businessNameController.text}'),
          Text('Business Category: $selectedBusinessCategory'),
          Text('Location: ${locationController.text}'),
        ],
        const SizedBox(height: 25),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: previousStep,
              child: const Text('Back'),
            ),
            MyButton(
              onTap: _submitForm,
              enabled: true,
              text : "Sign Up"
            ),
          ],
        ),
      ],
    );
  }
}

enum UserType { personal, business }