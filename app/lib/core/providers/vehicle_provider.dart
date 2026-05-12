import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vehicle_predictive_maintenance_app/core/models/user_vehicle.dart';

class VehicleProvider with ChangeNotifier {
  UserVehicle? _vehicle;

  UserVehicle? get vehicle => _vehicle;
  bool get hasVehicle => _vehicle != null;

  VehicleProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('selected_vehicle');
    if (raw != null) {
      try {
        _vehicle = UserVehicle.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> setVehicle(UserVehicle v) async {
    _vehicle = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_vehicle', jsonEncode(v.toJson()));
    notifyListeners();
  }

  Future<void> clearVehicle() async {
    _vehicle = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selected_vehicle');
    notifyListeners();
  }
}
