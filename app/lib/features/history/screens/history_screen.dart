import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:vehicle_predictive_maintenance_app/app/theme/app_theme.dart';
import 'package:vehicle_predictive_maintenance_app/services/history_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryService _historyService = HistoryService();
  List<Map<String, dynamic>> _records = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _historyService.loadHistory();
    if (!mounted) return;
    setState(() => _records = items);
  }

  @override
  Widget build(BuildContext context) {
    final trend = _records.take(7).toList().reversed.toList();
    final spots = trend
        .asMap()
        .entries
        .map(
          (e) => FlSpot(
            e.key.toDouble(),
            ((1 - ((e.value['probability'] ?? 0.0) as num).toDouble()) * 100).clamp(0, 100).toDouble(),
          ),
        )
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Tendencia de salud (7 dias)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: const FlTitlesData(show: false),
              minY: 0,
              maxY: 100,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: AppTheme.primaryColor,
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Diagnosticos guardados', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        const SizedBox(height: 8),
        if (_records.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('Aun no hay registros guardados.'),
          )
        else
          ..._records.map((record) {
            final p = ((record['probability'] ?? 0.0) as num).toDouble();
            final anomaly = (record['anomaly'] ?? false) as bool;
            final color = anomaly ? AppTheme.dangerColor : AppTheme.successColor;
            final date = DateTime.tryParse(record['timestamp']?.toString() ?? '') ?? DateTime.now();

            return Card(
              child: ListTile(
                leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.2), child: Icon(Icons.timeline, color: color)),
                title: Text(anomaly ? 'Alerta detectada' : 'Sin anomalia'),
                subtitle: Text('${DateFormat('dd/MM/yyyy HH:mm').format(date)} - ${(p * 100).toStringAsFixed(1)}%'),
              ),
            );
          }),
      ],
    );
  }
}
