import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.black87,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.white),
        onPressed: onMenuTap ?? () {
          Scaffold.of(context).openDrawer(); // Open drawer by default
        },
        iconSize: 32,
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(minWidth: 60, minHeight: 60),
      ),
      title: Row(
        children: [
          Image.asset(
            'assests/images/apt-connect-logo.png', // fixed typo: 'assests' to 'assets'
            width: 80,
            height: 80,
          ),
          const SizedBox(width: 10),
         
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: onLogoutTap ?? () {},
          iconSize: 32,
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(minWidth: 60, minHeight: 60),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
