import 'package:flutter/material.dart';
import 'package:my_app/screens/batch_screen.dart';
import 'package:my_app/screens/demo_screen.dart';
import 'package:my_app/screens/teacher_screen.dart';
import 'package:my_app/screens/dashboard_screen.dart';
import 'package:my_app/screens/role_selection_screen.dart';

class RoleBasedDrawer extends StatelessWidget {
  final String role;
  final GlobalKey<ScaffoldState> scaffoldKey;

  const RoleBasedDrawer({
    Key? key,
    required this.role,
    required this.scaffoldKey,
  }) : super(key: key);

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => RoleSelectionScreen()),
                  (route) => false,
                );
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
       
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
          children: [
            // User Info Header
            Container(
              padding: const EdgeInsets.fromLTRB(16,40,16 ,16),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.black87,
               
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(
                      role.toLowerCase() == 'admin' ? Icons.admin_panel_settings : Icons.person,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          role.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Text(
                          'Welcome back!',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Teacher Role Menu
            if (role.toLowerCase() == 'teacher') ...[
              ListTile(
                leading: const Icon(Icons.group),
                title: const Text('Batches'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BatchScreen(userRole: role)
                    ),
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
                    MaterialPageRoute(
                      builder: (_) => DemoScreen(userRole: role)
                    ),
                  );
                },
              ),
            ] 
            // Admin Role Menu
            else if (role.toLowerCase() == 'admin') ...[
              ListTile(
                leading: const Icon(Icons.dashboard),
                title: const Text('Dashboard'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DashboardPage(userRole: role)
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('Teachers'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TeacherScreen(userRole: role)
                    ),
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
                    MaterialPageRoute(
                      builder: (_) => DemoScreen(userRole: role)
                    ),
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
                    MaterialPageRoute(
                      builder: (_) => BatchScreen(userRole: role)
                    ),
                  );
                },
              ),
            ]
            // Student Role Menu
            else if (role.toLowerCase() == 'student') ...[
              ListTile(
                leading: const Icon(Icons.group),
                title: const Text('My Batches'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BatchScreen(userRole: role)
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text('Class Schedule'),
                onTap: () {
                  Navigator.pop(context);
                  // Add your schedule screen navigation here
                },
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profile'),
                onTap: () {
                  Navigator.pop(context);
                  // Add your profile screen navigation here
                },
              ),
            ]
            // Default/Guest Menu
            else ...[
              ListTile(
                leading: const Icon(Icons.group),
                title: const Text('Available Batches'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BatchScreen(userRole: role)
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('About'),
                onTap: () {
                  Navigator.pop(context);
                  // Add your about screen navigation here
                },
              ),
            ],
            
        
          ],
        ),
      ),
    );
  }
}