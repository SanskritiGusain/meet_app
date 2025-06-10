// Create this file as lib/utils/session_manager.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

class SessionManager {
  static const String _authTokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userRoleKey = 'user_role';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _loginTimestampKey = 'login_timestamp';
  
  // Session timeout in hours (adjust as needed)
  static const int sessionTimeoutHours = 24;

  /// Check if user session is valid
  static Future<bool> isSessionValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if user was logged in
      bool isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
      if (!isLoggedIn) return false;
      
      // Check session timeout
      int? loginTimestamp = prefs.getInt(_loginTimestampKey);
      if (loginTimestamp != null) {
        int currentTime = DateTime.now().millisecondsSinceEpoch;
        int timeDifference = currentTime - loginTimestamp;
        int hoursDifference = (timeDifference / (1000 * 60 * 60)).round();
        
        if (hoursDifference > sessionTimeoutHours) {
          await clearSession();
          return false;
        }
      }
      
      // Check if token exists
      String? token = getAuthToken();
      String? userRole = getUserRole();
      
      if (token == null || userRole == null) {
        await clearSession();
        return false;
      }
      
      // Validate token with server (optional, comment out if not needed)
      // bool isTokenValid = await validateTokenWithServer(token, userRole);
      // if (!isTokenValid) {
      //   await clearSession();
      //   return false;
      // }
      
      return true;
    } catch (e) {
      print('Session validation error: $e');
      await clearSession();
      return false;
    }
  }

  /// Validate token with server
  static Future<bool> validateTokenWithServer(String token, String userRole) async {
    try {
      String url;
      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      
      // Choose validation endpoint based on role
      if (userRole.toLowerCase() == 'admin') {
        url = 'https://meet-api.apt.shiksha/api/Admins/profile'; // Use profile endpoint to validate
      } else {
        url = 'https://meet-api.apt.shiksha/api/remoteMethods/profile'; // Use profile endpoint to validate
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(Duration(seconds: 10));
      
      return response.statusCode == 200;
    } catch (e) {
      print('Token validation error: $e');
      return false;
    }
  }

  /// Get stored auth token
  static String? getAuthToken() {
    // Note: This is synchronous, for async use getAuthTokenAsync()
    return null; // Use getAuthTokenAsync() instead
  }

  /// Get stored auth token (async)
  static Future<String?> getAuthTokenAsync() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_authTokenKey);
  }

  /// Get stored user role
  static String? getUserRole() {
    // Note: This is synchronous, for async use getUserRoleAsync()
    return null; // Use getUserRoleAsync() instead
  }

  /// Get stored user role (async)
  static Future<String?> getUserRoleAsync() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }

  /// Get stored user ID
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  /// Clear user session
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authTokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userRoleKey);
    await prefs.remove(_loginTimestampKey);
    await prefs.setBool(_isLoggedInKey, false);
  }

  /// Save user session
  static Future<void> saveSession({
    required String token,
    required String userId,
    required String userRole,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authTokenKey, token);
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_userRoleKey, userRole);
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setInt(_loginTimestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Logout and clear session
  static Future<void> logout(BuildContext context) async {
    await clearSession();
    
    // Navigate to role selection screen
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/role-select',
      (Route<dynamic> route) => false,
    );
  }

  /// Check if session is expired based on timestamp
  static Future<bool> isSessionExpired() async {
    final prefs = await SharedPreferences.getInstance();
    int? loginTimestamp = prefs.getInt(_loginTimestampKey);
    
    if (loginTimestamp == null) return true;
    
    int currentTime = DateTime.now().millisecondsSinceEpoch;
    int timeDifference = currentTime - loginTimestamp;
    int hoursDifference = (timeDifference / (1000 * 60 * 60)).round();
    
    return hoursDifference > sessionTimeoutHours;
  }

  /// Refresh session timestamp
  static Future<void> refreshSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_loginTimestampKey, DateTime.now().millisecondsSinceEpoch);
  }
}