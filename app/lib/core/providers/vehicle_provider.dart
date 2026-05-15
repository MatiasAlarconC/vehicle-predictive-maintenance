import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vehicle_predictive_maintenance_app/core/models/user_vehicle.dart';

class VehicleProvider with ChangeNotifier {
  List<UserVehicle> _garage = [];
  int _activeIndex = 0;

  List<UserVehicle> get garage => List.unmodifiable(_garage);
  UserVehicle? get vehicle => _garage.isNotEmpty ? _garage[_activeIndex] : null;
  bool get hasVehicle => _garage.isNotEmpty;
  int get activeIndex => _activeIndex;

  VehicleProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    // Migrate legacy single-vehicle data
    final legacy = prefs.getString('selected_vehicle');
    if (legacy != null) {
      try {
        final v = UserVehicle.fromJson(jsonDecode(legacy) as Map<String, dynamic>);
        _garage = [v];
        await prefs.setString('garage_vehicles', jsonEncode([v.toJson()]));
        await prefs.setInt('active_vehicle_index', 0);
        await prefs.remove('selected_vehicle');
      } catch (_) {}
    } else {
      final raw = prefs.getString('garage_vehicles');
      if (raw != null) {
        try {
          final list = jsonDecode(raw) as List;
          _garage = list
              .map((e) => UserVehicle.fromJson(e as Map<String, dynamic>))
              .toList();
        } catch (_) {}
      }
      _activeIndex = (prefs.getInt('active_vehicle_index') ?? 0)
          .clamp(0, _garage.isEmpty ? 0 : _garage.length - 1);
    }

    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'garage_vehicles', jsonEncode(_garage.map((v) => v.toJson()).toList()));
    await prefs.setInt('active_vehicle_index', _activeIndex);
  }

  /// Add a new vehicle (or update active if first). Makes it the active one.
  Future<void> setVehicle(UserVehicle v) async {
    _garage.add(v);
    _activeIndex = _garage.length - 1;
    await _persist();
    notifyListeners();
  }

  Future<void> setActiveVehicle(int index) async {
    if (index < 0 || index >= _garage.length) return;
    _activeIndex = index;
    await _persist();
    notifyListeners();
  }

  Future<void> removeVehicle(int index) async {
    if (index < 0 || index >= _garage.length) return;
    _garage.removeAt(index);
    _activeIndex = _activeIndex.clamp(0, _garage.isEmpty ? 0 : _garage.length - 1);
    await _persist();
    notifyListeners();
  }

  Future<void> clearVehicle() async {
    _garage = [];
    _activeIndex = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('garage_vehicles');
    await prefs.remove('active_vehicle_index');
    notifyListeners();
  }
}
