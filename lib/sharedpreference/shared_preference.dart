import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SharedPrefHelper {
  // Keys for storing data
  static const String _tokenKey = 'token';
  static const String _userNameKey = 'userName';
  static const String _batchNameKey = 'batchName';
  static const String _batchStartTimeKey = 'batchStartTime';
  static const String _batchEndTimeKey = 'batchEndTime';
  static const String _roomNameKey = 'roomName';
  static const String _userIdKey = 'userId';
  static const String _loginKey = 'loggedIn';
  static const String _configOverwriteKey = 'configOverwrite';
  static const String _userDetailsKey = 'userDetails';

  // Save user data in SharedPreferences
  static Future<void> saveUserData({
    required String token,
    required String userName,
    required String batchName,
    required String batchStartTime,
    required String batchEndTime,
    required String roomName,
    required String userId,
    required bool loggedIn,
    required Map<String, dynamic> configOverwrite,
    required Map<String, dynamic> userDetails,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userNameKey, userName);
    await prefs.setString(_batchNameKey, batchName);
    await prefs.setString(_batchStartTimeKey, batchStartTime);
    await prefs.setString(_batchEndTimeKey, batchEndTime);
    await prefs.setString(_roomNameKey, roomName);
    await prefs.setString(_userIdKey, userId);
    await prefs.setBool(_loginKey, loggedIn);
    await prefs.setString(_configOverwriteKey, jsonEncode(configOverwrite)); // Save as JSON
    await prefs.setString(_userDetailsKey, jsonEncode(userDetails)); // Save as JSON
  }


  static Future<Map<String, dynamic>> getUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return {
      'token': prefs.getString(_tokenKey),
      'userName': prefs.getString(_userNameKey),
      'batchName': prefs.getString(_batchNameKey),
      'batchStartTime': prefs.getString(_batchStartTimeKey),
      'batchEndTime': prefs.getString(_batchEndTimeKey),
      'roomName': prefs.getString(_roomNameKey),
      'userId': prefs.getString(_userIdKey),
      'loggedIn': prefs.getBool(_loginKey) ?? false,
      'configOverwrite': prefs.getString(_configOverwriteKey) != null
          ? jsonDecode(prefs.getString(_configOverwriteKey)!) // Decode JSON string
          : null,
      'userDetails': prefs.getString(_userDetailsKey) != null
          ? jsonDecode(prefs.getString(_userDetailsKey)!) // Decode JSON string
          : null,
    };
  }


  // Clear all stored data
  static Future<void> clearUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_batchNameKey);
    await prefs.remove(_batchStartTimeKey);
    await prefs.remove(_batchEndTimeKey);
    await prefs.remove(_roomNameKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_loginKey);
    await prefs.remove(_configOverwriteKey);
    await prefs.remove(_userDetailsKey);
  }
}



// import 'package:shared_preferences/shared_preferences.dart';
//
// class SharedPrefHelper {
//   // Keys for storing data
//   static const String _tokenKey = 'token';
//   static const String _userNameKey = 'userName';
//   static const String _batchNameKey = 'batchName';
//   static const String _batchStartTimeKey = 'batchStartTime';
//   static const String _batchEndTimeKey = 'batchEndTime';
//   static const String _roomNameKey = 'roomName';
//   static const String _userIdKey = 'userId';
//   static const String _loginKey = 'loggedIn'; // Changed to a String key
//
//   // Save data in SharedPreferences
//   static Future<void> saveUserData({
//     required String token,
//     required String userName,
//     required String batchName,
//     required String batchStartTime,
//     required String batchEndTime,
//     required String roomName,
//     required String userId,
//     required bool loggedIn,
//   }) async {
//     final SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.setString(_tokenKey, token);
//     await prefs.setString(_userNameKey, userName);
//     await prefs.setString(_batchNameKey, batchName);
//     await prefs.setString(_batchStartTimeKey, batchStartTime);
//     await prefs.setString(_batchEndTimeKey, batchEndTime);
//     await prefs.setString(_roomNameKey, roomName);
//     await prefs.setString(_userIdKey, userId);
//     await prefs.setBool(_loginKey, loggedIn); // Corrected to use the String key
//   }
//
//   // Retrieve data from SharedPreferences
//   static Future<Map<String, dynamic>> getUserData() async {
//     final SharedPreferences prefs = await SharedPreferences.getInstance();
//     return {
//       'token': prefs.getString(_tokenKey),
//       'userName': prefs.getString(_userNameKey),
//       'batchName': prefs.getString(_batchNameKey),
//       'batchStartTime': prefs.getString(_batchStartTimeKey),
//       'batchEndTime': prefs.getString(_batchEndTimeKey),
//       'roomName': prefs.getString(_roomNameKey),
//       'userId': prefs.getString(_userIdKey),
//       'loggedIn': prefs.getBool(_loginKey) ?? false, // Handle null case
//     };
//   }
//
//   // Clear all stored data
//   static Future<void> clearUserData() async {
//     final SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.remove(_tokenKey);
//     await prefs.remove(_userNameKey);
//     await prefs.remove(_batchNameKey);
//     await prefs.remove(_batchStartTimeKey);
//     await prefs.remove(_batchEndTimeKey);
//     await prefs.remove(_roomNameKey);
//     await prefs.remove(_userIdKey);
//     await prefs.remove(_loginKey);
//   }
// }
