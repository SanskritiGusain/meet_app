import 'package:flutter/material.dart';



class UserProvider extends ChangeNotifier {
  String? _token;
  String? _roomName;
  String? _startTime;
  String? _endTime;
  Map<String, dynamic>? _user;
  Map<String, Object?>? _configOverrides;

  String? get token => _token;
  String? get roomName => _roomName;
  String? get startTime => _startTime;
  String? get endTime => _endTime;
  Map<String, dynamic>? get user => _user;
  Map<String, Object?>? get configOverrides => _configOverrides;

  void setUserData(String token, Map<String, dynamic> user, String roomName,String startTime,String endTime, Map<String, Object?>? configOverrides) {
    _token = token;
    _user = user;
    _startTime = startTime;
    _endTime = endTime;
    _roomName = roomName;
    _configOverrides = configOverrides;
    notifyListeners();  // Notify listeners about the change
  }

  void clearUserData() {
    _token = null;
    _user = null;
    _startTime = null;
    _endTime = null;
    _roomName = null;
    _configOverrides = null;
    notifyListeners();
  }
}