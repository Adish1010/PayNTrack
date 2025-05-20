import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/personal_home.dart';
import 'package:frontend/screens/signup_screen.dart';
import 'package:provider/provider.dart';
Future<void> main() async {
  await dotenv.load(fileName: ".env");
  
  runApp(ChangeNotifierProvider(
      create: (context) => UserProvider(),
      child: MyApp(),));
}


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final storage = FlutterSecureStorage();
  String initialRoute = '/login';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      String? accessToken = await storage.read(key: 'access_token');
      setState(() {
        initialRoute = (accessToken == null || accessToken.isEmpty) ? '/login' : '/home';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      routes: {
        '/signup': (context) => RegistrationFlow(),
        '/login': (context) => LoginPage(),
        '/home': (context) => HomeScreen(),
      },
    );
  }
}