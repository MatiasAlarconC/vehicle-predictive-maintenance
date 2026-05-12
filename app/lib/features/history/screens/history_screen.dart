import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:vehicle_predictive_maintenance_app/app/theme/app_theme.dart';
import 'package:vehicle_predictive_maintenance_app/app/widgets/custom_card.dart';
import 'package:vehicle_predictive_maintenance_app/services/history_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryService _historyService = HistoryService();
  List<Map<String, dynamic>> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _historyService.loadHistory();
    if (!mounted) return;
    setState(() {
      _records = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final trend = _records.take(7).toList().reversed.toList();
    final spots = trend.asMap().entries.map((e) {
      final p = ((e.value['probability'] ?? 0.0) as num).toDouble();
      return FlSpot(e.key.toDouble(), ((1 - p) * 100).clamp(0, 100));
    }).toList();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _HistoryHeader(count: _records.length),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Gráfico de tendencia
              if (_records.isNotEmpty) ...[
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.trending_up_rounded,
                                color: AppTheme.primaryColor, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Text('TENDENCIA DE SALUD',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textSecondary,
                                letterSpacing: 1.5,
                              )),
                          const Spacer(),
                          Text('Últimos 7 días',
                              style: const TextStyle(
                                  fontSize: 11, color: AppTheme.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 140,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (_) => FlLine(
                                color: AppTheme.borderColor.withValues(alpha: 0.5),
                                strokeWidth: 1,
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 32,
                                  interval: 50,
                                  getTitlesWidget: (v, _) => Text(
                                    '${v.toInt()}%',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.textSecondary),
                                  ),
                                ),
                              ),
                              rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                            ),
                            minY: 0,
                            maxY: 100,
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots.isEmpty
                                    ? [const FlSpot(0, 80)]
                                    : spots,
                                isCurved: true,
                                color: AppTheme.primaryColor,
                                barWidth: 3,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter: (_, __, ___, ____) =>
                                      FlDotCirclePainter(
                                    radius: 3,
                                    color: AppTheme.primaryColor,
                                    strokeWidth: 0,
                                    strokeColor: Colors.transparent,
                                  ),
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.primaryColor.withValues(alpha: 0.2),
                                      Colors.transparent,
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Lista de registros
              Text(
                'DIAGNÓSTICOS GUARDADOS',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),

              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                      strokeWidth: 2,
                    ),
                  ),
                )
              else if (_records.isEmpty)
                _EmptyState()
              else
                ..._records.asMap().entries.map((entry) {
                  return _HistoryCard(
                    record: entry.value,
                    index: entry.key,
                  );
                }),
            ]),
          ),
        ),
      ],
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  final int count;
  const _HistoryHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.backgroundSecondary, AppTheme.background],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HISTORIAL',
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: 3,
                ),
              ),
              Text(
                'Diagnósticos anteriores',
                style: TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              '$count registros',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> record;
  final int index;

  const _HistoryCard({required this.record, required this.index});

  @override
  Widget build(BuildContext context) {
    final p = ((record['probability'] ?? 0.0) as num).toDouble();
    final date = DateTime.tryParse(record['timestamp']?.toString() ?? '') ??
        DateTime.now();

    Color color;
    String label;
    IconData icon;

    if (p >= 0.65) {
      color = AppTheme.dangerColor;
      label = 'Anomalía Crítica';
      icon = Icons.dangerous_rounded;
    } else if (p >= 0.40) {
      color = AppTheme.warningColor;
      label = 'Alerta';
      icon = Icons.warning_amber_rounded;
    } else {
      color = AppTheme.successColor;
      label = 'Sistema Normal';
      icon = Icons.verified_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icono de estado
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.rajdhani(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('dd MMM yyyy · HH:mm').format(date),
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            // Probabilidad
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${(p * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.rajdhani(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  'prob.',
                  style: const TextStyle(
                      fontSize: 10, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surface,
                border: const Border.fromBorderSide(
                    BorderSide(color: AppTheme.borderColor)),
              ),
              child: const Icon(Icons.history_toggle_off_rounded,
                  color: AppTheme.textSecondary, size: 40),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sin registros aún',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Los diagnósticos guardados\naparecerán aquí',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
