import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/screens/role_selection_screen.dart';

class NavBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuTap;
  final VoidCallback? onLogoutTap;
  final String title;

  const NavBar({
    Key? key,
    required this.title,
    this.onMenuTap,
    this.onLogoutTap,
  }) : super(key: key);

  // Enhanced logout method that clears stored data
  Future<void> _performLogout(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clear all stored authentication data
      await prefs.remove('auth_token');
      await prefs.remove('user_id');
      await prefs.remove('user_role');
      await prefs.setBool('is_logged_in', false);
      
      // Clear any other app-specific data if needed
      // await prefs.clear(); // Use this if you want to clear everything
      
    } catch (e) {
      print('Error clearing preferences: $e');
    }
    
    // Navigate to role selection and clear all previous routes
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => RoleSelectionScreen()),
      (route) => false,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Logout',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              fontWeight: FontWeight.w400,
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.grey),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _performLogout(context); // Enhanced logout
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.black87,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.white),
        onPressed: onMenuTap ?? () {
          Scaffold.of(context).openDrawer();
        },
        iconSize: 24,
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(minWidth: 60, minHeight: 60),
      ),
      title: Row(
        children: [
          Image.asset(
            'assests/images/apt-connect-logo.png',
            width: 80,
            height: 80,
          ),
          const SizedBox(width: 10),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: onLogoutTap ?? () => _showLogoutDialog(context),
          iconSize: 24,
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(minWidth: 60, minHeight: 60),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}