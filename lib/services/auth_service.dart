// 1. Create auth_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _roleKey = 'user_role';
  static const String _expiryKey = 'token_expiry';
  static const String _loggedInKey = 'loggedIn';
  static const String _userDataKey = 'user_data';
  
  // Save authentication data after successful login
  static Future<void> saveAuthData({
    required String token,
    required String role,
    required Map<String, dynamic> userData,
    int expiryHours = 24, // Default 24 hours
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final expiryTime = DateTime.now().add(Duration(hours: expiryHours));
    
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_roleKey, role);
    await prefs.setString(_expiryKey, expiryTime.toIso8601String());
    await prefs.setBool(_loggedInKey, true);
    await prefs.setString(_userDataKey, jsonEncode(userData));
  }
  
  // Get stored token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
  
  // Get stored role
  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }
  
  // Get stored user data
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userDataKey);
    if (userDataString != null) {
      return jsonDecode(userDataString);
    }
    return null;
  }
  
  // Check if token is valid (not expired)
  static Future<bool> isTokenValid() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final expiryString = prefs.getString(_expiryKey);
    final isLoggedIn = prefs.getBool(_loggedInKey) ?? false;
    
    if (!isLoggedIn || token == null || expiryString == null) return false;
    
    final expiryTime = DateTime.parse(expiryString);
    return DateTime.now().isBefore(expiryTime);
  }
  
  // Clear all auth data (logout)
  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_expiryKey);
    await prefs.setBool(_loggedInKey, false);
    await prefs.remove(_userDataKey);
  }
  
  // Check authentication status
  static Future<AuthStatus> checkAuthStatus() async {
    final isValid = await isTokenValid();
    if (!isValid) {
      await clearAuthData(); // Clear expired token
      return AuthStatus.notAuthenticated;
    }
    
    final role = await getRole();
    if (role?.toLowerCase() == 'teacher') {
      return AuthStatus.teacherAuthenticated;
    } else if (role?.toLowerCase() == 'admin') {
      return AuthStatus.adminAuthenticated;
    }
    
    return AuthStatus.notAuthenticated;
  }
}

enum AuthStatus {
  notAuthenticated,
  teacherAuthenticated,
  adminAuthenticated,
}