import 'package:flutter/material.dart';
import 'package:vehicle_predictive_maintenance_app/services/history_service.dart';

class HistoryProvider with ChangeNotifier {
  final HistoryService _historyService = HistoryService();

  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;

  List<Map<String, dynamic>> get records => List.unmodifiable(_records);
  bool get isLoading => _isLoading;

  Future<void> loadHistory() async {
    _isLoading = true;
    notifyListeners();

    _records = await _historyService.loadHistory();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveRecord(Map<String, dynamic> record) async {
    await _historyService.saveRecord(record);
    _records = [record, ..._records].take(100).toList();
    notifyListeners();
  }
}
