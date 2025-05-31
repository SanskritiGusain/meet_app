import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';

class ToastUtils {
  // Global method to show a toast message
  static void showToast({
    required String message,
    Color backgroundColor = Colors.black, // Default background color
    Color textColor = Colors.white, // Default text color
    Toast toastLength = Toast.LENGTH_SHORT, // Default toast length
    ToastGravity gravity = ToastGravity.TOP, // Default position
  }) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: toastLength,
      gravity: gravity,
      timeInSecForIosWeb: 1,
      backgroundColor: backgroundColor,
      textColor: textColor,
      fontSize: 16.0,
    );
  }
}
