import 'package:flutter/material.dart';
import 'package:my_app/screens/batch_screen.dart';

import 'package:my_app/screens/teacher_screen.dart';
import 'package:my_app/screens/navBar.dart';
import 'package:my_app/role_base_drawer/role_base_drawer.dart'; // <-- import this

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // 🔐 Role (this can be fetched from login/session later)
  String userRole = 'admin';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,

      // ✅ Use RoleBasedDrawer here
      drawer: RoleBasedDrawer(
        role: userRole,
        scaffoldKey: _scaffoldKey,
      ),

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: NavBar(
          title: 'Dashboard',
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
          onLogoutTap: () {
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        ),
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
          // Add Teacher logic here
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
