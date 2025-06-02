import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final String role; // teacher or admin

  const HomePage({Key? key, required this.role}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home - $role'),
      ),
      body: Center(
        child: Text(
          'Welcome, $role!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
