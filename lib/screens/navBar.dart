import 'package:flutter/material.dart';

class NavBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuTap;
  final VoidCallback? onLogoutTap;

  const NavBar({
    Key? key,
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
        onPressed: onMenuTap ?? () {},
        iconSize: 32,
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
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed:  onLogoutTap ?? () {},
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
