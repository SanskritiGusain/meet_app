
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:my_app/screens/role_selection_screen.dart';
class SplashScreen extends StatefulWidget {
  final bool isLoggedIn;
  const SplashScreen({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  

  @override
  void initState() {
    super.initState();
    
    
    // Navigate after 3 seconds
    Timer(Duration(seconds: 3), () {
      _navigateToNextScreen();
    });
  }

  void _navigateToNextScreen() {
    if (widget.isLoggedIn) {
      // Navigate to dashboard/home screen if logged in
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => RoleSelectionScreen()), // Replace with your dashboard
        (Route<dynamic> route) => false,
      );
    } else {
      // Navigate to role selection if not logged in
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => RoleSelectionScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }


 @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedOpacity(
        opacity: 1.0,
        duration: Duration(seconds: 6),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assests/images/splash_image.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}