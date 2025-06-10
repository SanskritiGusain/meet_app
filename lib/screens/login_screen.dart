import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/screens/batch_screen.dart';
import 'package:my_app/screens/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  final String role; // 'teacher' or 'admin'
  const LoginScreen({Key? key, required this.role}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

Future<void> _login() async {
  final loginId = _loginIdController.text.trim();
  final password = _passwordController.text;
  
  if (loginId.isEmpty || password.isEmpty) {
    setState(() {
      _error = "Login ID and Password are required.";
    });
    return;
  }

  setState(() {
    _loading = true;
    _error = null;
  });

  try {
    String url;
    Map<String, dynamic> body;
 
    if (widget.role.toLowerCase() == 'admin') {
      url = 'https://meet-api.apt.shiksha/api/Admins/login';
      body = {
        "username": loginId,
        "password": password,
      };
    } else {
      url = 'https://meet-api.apt.shiksha/api/remoteMethods/login';
      body = {
        "loginId": loginId,
        "password": password,
        "type": widget.role,
      };
    }

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 &&
        (data['message']?.toLowerCase().contains('success') ?? false || data['id'] != null)) {
      
      // Store authentication data
      final prefs = await SharedPreferences.getInstance();
      
      // Store token (check different possible token fields)
      String? token = data['token'] ?? data['accessToken'] ?? data['authToken'];
      if (token != null) {
        await prefs.setString('auth_token', token);
      } else if (data['id'] != null) {
        // If no token field, use ID as temporary token
        await prefs.setString('auth_token', data['id'].toString());
      }
      
      // Store user information
      if (data['id'] != null) {
        await prefs.setString('user_id', data['id'].toString());
      }
      
      await prefs.setString('user_role', widget.role);
      await prefs.setBool('is_logged_in', true);
      
      // Store login timestamp for session management
      await prefs.setInt('login_timestamp', DateTime.now().millisecondsSinceEpoch);
      
      // Navigate to respective screens
      if (widget.role.toLowerCase() == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DashboardPage(userRole: widget.role)
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BatchScreen(userRole: widget.role)
          ),
        );
      }
    } else {
      setState(() {
        _error = data['message'] ?? "Invalid login credentials.";
      });
    }
  } catch (e) {
    setState(() => _error = "Login failed: $e");
  } finally {
    setState(() => _loading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 253, 250, 250),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assests/images/apt-connect-logo.png',
                height: 30,
              ),
              SizedBox(height: 30),
              Text(
                "Login To Start Class",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 20),
              TextField(
                style: TextStyle(fontSize: 16),
                controller: _loginIdController,
                decoration: InputDecoration(
                  labelText: "Login ID *",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12), 
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: "Password *",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12), 
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      _error!, 
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              SizedBox(height: 50),
              _loading
                  ? CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Color.fromARGB(255, 253, 250, 250),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _login,
                        child: Text("ENTER"),
                      ),
                    ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}