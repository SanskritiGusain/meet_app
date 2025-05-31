import 'package:flutter/material.dart';

// Define your custom colors here
class AppColors {
  static const Color logoColor = Color(0xFF56B280);
  static const Color linksColor = Color(0xFF1D252C);
  static const Color buttonColor = Color(0xFF5BC08A);
  static const Color cardColor = Color(0xFFF3F3F3);
  static const Color secondaryColor = Color(0xFF0B254B);
  static const Color textColor = Color(0xFF777777);
  static const Color overlayColor = Color(0xff00ff0066);
  static const Color textFieldColor = Color(0xffFAFAFA);
  static const Color bannerColor = Color.fromARGB(255, 243, 242, 242);

  // Add more custom colors as needed
}

class AppHeadings {
  static TextStyle heading1(BuildContext context) {
    return TextStyle(
      fontSize: MediaQuery.of(context).size.width > 600 ? 45 : 30,
      color: Colors.white,
      fontWeight: FontWeight.bold,
    );
  }

  static TextStyle heading2(BuildContext context) {
    return TextStyle(
      fontSize: MediaQuery.of(context).size.width > 600 ? 35 : 30,
      color: AppColors.secondaryColor,
      fontWeight: FontWeight.bold,
    );
  }
}