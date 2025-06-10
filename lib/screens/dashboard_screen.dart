import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_app/screens/batch_screen.dart';
import 'package:my_app/screens/teacher_screen.dart';
import 'package:my_app/screens/navBar.dart';
import 'package:my_app/role_base_drawer/role_base_drawer.dart';

class DashboardPage extends StatefulWidget {
  final String userRole;
  
  const DashboardPage({
    Key? key, 
    required this.userRole
  }) : super(key: key);
 
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  @override
  Widget build(BuildContext context) {
    bool isAdmin = widget.userRole.toLowerCase() == 'admin';
    
    return PopScope(
      canPop: !isAdmin, // Admin cannot pop normally
      onPopInvoked: (didPop) async {
        if (didPop) return;
        
        if (isAdmin) {
          // Show confirmation dialog for admin
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Exit App'),
              content: const Text('Do you want to close the application?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Exit'),
                ),
              ],
            ),
          );
          
          if (shouldExit == true) {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: RoleBasedDrawer(
          role: widget.userRole,
          scaffoldKey: _scaffoldKey,
        ),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: NavBar(
            title: 'Dashboard',
            onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
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
                    MaterialPageRoute(builder: (_) => TeacherScreen(userRole: widget.userRole)),
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
                    MaterialPageRoute(builder: (_) => BatchScreen(userRole: widget.userRole)),
                  );
                },
              ),
            ],
          ),
        ),
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