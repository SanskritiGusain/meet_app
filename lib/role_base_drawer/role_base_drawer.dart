import 'package:flutter/material.dart';
import 'package:my_app/screens/batch_screen.dart';
import 'package:my_app/screens/demo_screen.dart';
import 'package:my_app/screens/teacher_screen.dart';
import 'package:my_app/screens/dashboard_screen.dart';

class RoleBasedDrawer extends StatelessWidget {
  final String role;
  final GlobalKey<ScaffoldState> scaffoldKey;

  const RoleBasedDrawer({
    Key? key,
    required this.role,
    required this.scaffoldKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color(0xFFEFEFEF),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 50, 0, 10),
          children: [
            if (role == 'teacher') ...[
              ListTile(
                leading: const Icon(Icons.group),
                title: const Text('Batches'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const BatchScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.play_circle_fill),
                title: const Text('Demo'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const DemoScreen()),
                  );
                },
              ),
            ] else if (role == 'admin') ...[
                 ListTile(
                leading: const Icon(Icons.people),
                title: const Text('Dashboard'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to Teacher Screen here
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const DashboardPage()), // Make sure you import TeacherScreen
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('Teachers'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to Teacher Screen here
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const TeacherScreen()), // Make sure you import TeacherScreen
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.play_circle_fill),
                title: const Text('Demo'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const DemoScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.group),
                title: const Text('Batches'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const BatchScreen()),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

