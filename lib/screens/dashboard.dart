import 'package:flutter/material.dart';
import 'package:my_app/screens/batch_screen.dart';
import 'package:my_app/screens/demo_page.dart';
import 'package:my_app/screens/teacher_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              Container(
                height: kToolbarHeight,
                color: Colors.black87,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Image.asset('assests/images/apt-connect-logo.png', height: 32),
                    const SizedBox(width: 25),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    _drawerTile(
                      context,
                      icon: Icons.dashboard,
                      label: 'Dashboard',
                      onTap: () {
                        Navigator.pop(context); // Stay on current
                      },
                    ),
                    _drawerTile(
                      context,
                      icon: Icons.people,
                      label: 'Teachers',
                      destination: const TeacherScreen(),
                    ),
                    _drawerTile(
                      context,
                      icon: Icons.visibility,
                      label: 'Demo',
                      destination: const DemoScreen(),
                    ),
                    _drawerTile(
                      context,
                      icon: Icons.view_list,
                      label: 'Batches',
                      destination: const BatchScreen(),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("© 2025 meet", style: TextStyle(fontSize: 12)),
              )
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assests/images/apt-connect-logo.png',
              height: 32,
            ),
            const SizedBox(width: 12),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildDashboardCard(
              context,
              label: 'Teachers',
              color: Colors.orange.shade100,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TeacherScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildDashboardCard(
              context,
              label: 'Batches',
              color: Colors.purple.shade100,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BatchScreen()),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // You can replace this with navigation to an Edit screen
         
        },
        tooltip: 'Add Teacher',
        backgroundColor: const Color.fromARGB(255, 32, 32, 31),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Icon(Icons.add, size: 35, color: Colors.white),
      ),
    );
  }

  Widget _drawerTile(BuildContext context,
      {required IconData icon,
      required String label,
      Widget? destination,
      VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, size: 24),
      title: Text(label, style: const TextStyle(fontSize: 16)),
      onTap: onTap ??
          () {
            Navigator.pop(context);
            if (destination != null) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => destination),
              );
            }
          },
    );
  }

  Widget _buildDashboardCard(BuildContext context,
      {required String label,
      required Color color,
      required VoidCallback onTap}) {
    return Card(
      color: color,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: double.infinity,
          height: 120,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
