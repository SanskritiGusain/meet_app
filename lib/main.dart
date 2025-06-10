// main.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/screens/role_selection_screen.dart';
import 'package:my_app/splash_screen.dart';
import 'package:my_app/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:my_app/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool isLoggedIn = await checkIfLoggedIn();
  runApp(
    ChangeNotifierProvider<UserProvider>(
      create: (context) => UserProvider(),
      child: MyApp(isLoggedIn: isLoggedIn),
    ),
  );
}

Future<bool> checkIfLoggedIn() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool("loggedIn") ?? false;
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'APT App',
      theme: AppTheme.lightTheme, 
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => SplashScreen(isLoggedIn: isLoggedIn),
        '/role-select': (context) => RoleSelectionScreen(),
        // Add other routes as needed
      },
    );
  }
}