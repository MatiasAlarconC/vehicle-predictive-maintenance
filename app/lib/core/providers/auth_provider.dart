import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoggedIn = false;
  String _userName = '';
  String _userEmail = '';

  bool get isLoggedIn => _isLoggedIn;
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get firstName => _userName.split(' ').first;

  AuthProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('auth_logged_in') ?? false;
    _userName = prefs.getString('auth_name') ?? '';
    _userEmail = prefs.getString('auth_email') ?? '';
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (email.isNotEmpty && password.length >= 6) {
      _isLoggedIn = true;
      _userEmail = email;
      _userName = email.split('@').first.replaceAll('.', ' ').replaceAll('_', ' ');
      _userName = _userName.split(' ')
          .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
          .join(' ');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auth_logged_in', true);
      await prefs.setString('auth_name', _userName);
      await prefs.setString('auth_email', _userEmail);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> register(String name, String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (name.isNotEmpty && email.isNotEmpty && password.length >= 6) {
      _isLoggedIn = true;
      _userName = name;
      _userEmail = email;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auth_logged_in', true);
      await prefs.setString('auth_name', _userName);
      await prefs.setString('auth_email', _userEmail);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _userName = '';
    _userEmail = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auth_logged_in', false);
    await prefs.remove('auth_name');
    await prefs.remove('auth_email');
    notifyListeners();
  }
}
