import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vehicle_predictive_maintenance_app/core/constants/app_constants.dart';
import 'package:vehicle_predictive_maintenance_app/core/enums/app_enums.dart';

class AppProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  AppMode _appMode = AppMode.demo;
  String _serverIp = AppConstants.defaultIp;
  String _serverPort = AppConstants.defaultPort;
  bool _isConnected = false;

  AppProvider() {
    _load();
  }

  ThemeMode get themeMode => _themeMode;
  AppMode get appMode => _appMode;
  String get serverIp => _serverIp;
  String get serverPort => _serverPort;
  bool get isConnected => _isConnected;

  String get baseUrl => 'http://$_serverIp:$_serverPort';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _appMode = (prefs.getString('appMode') ?? 'demo') == 'production'
        ? AppMode.production
        : AppMode.demo;
    _serverIp = prefs.getString('serverIp') ?? AppConstants.defaultIp;
    _serverPort = prefs.getString('serverPort') ?? AppConstants.defaultPort;
    _isConnected = prefs.getBool('isConnected') ?? false;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('appMode', _appMode.name);
    await prefs.setString('serverIp', _serverIp);
    await prefs.setString('serverPort', _serverPort);
    await prefs.setBool('isConnected', _isConnected);
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  Future<void> setAppMode(AppMode mode) async {
    _appMode = mode;
    await _save();
    notifyListeners();
  }

  Future<void> setServer(String ip, String port) async {
    _serverIp = ip;
    _serverPort = port;
    await _save();
    notifyListeners();
  }

  Future<void> setConnection(bool value) async {
    _isConnected = value;
    await _save();
    notifyListeners();
  }
}
