import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vehicle_predictive_maintenance_app/app/theme/app_theme.dart';
import 'package:vehicle_predictive_maintenance_app/app/widgets/vera_components.dart';
import 'package:vehicle_predictive_maintenance_app/core/providers/history_provider.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  List<_TrendPoint> _buildTrend(List<Map<String, dynamic>> records) {
    final dailyHealth = <String, List<double>>{};
    for (final r in records) {
      final ts = DateTime.tryParse(r['timestamp']?.toString() ?? '');
      if (ts == null) continue;
      final key = DateFormat('yyyy-MM-dd').format(ts);
      final prob = ((r['probability'] ?? 0.0) as num).toDouble();
      final health = ((r['health'] as num?)?.toDouble() ?? ((1 - prob) * 100)).clamp(0, 100).toDouble();
      dailyHealth.putIfAbsent(key, () => []).add(health);
    }
    final pts = dailyHealth.entries.map((e) {
      final avg = e.value.reduce((a, b) => a + b) / e.value.length;
      return _TrendPoint(date: DateTime.parse(e.key), label: DateFormat('dd/MM').format(DateTime.parse(e.key)), health: avg);
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
    return pts.length > 7 ? pts.sublist(pts.length - 7) : pts;
  }

  @override
  Widget build(BuildContext context) {
    final historyProvider = context.watch<HistoryProvider>();
    final records = historyProvider.records;
    final trend = _buildTrend(records);
    final spots = trend.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.health))
        .toList();

    final okCount = records.where((r) => ((r['probability'] as num?)?.toDouble() ?? 0) < 0.40).length;
    final warnCount = records.where((r) {
      final p = ((r['probability'] as num?)?.toDouble() ?? 0);
      return p >= 0.40 && p < 0.65;
    }).length;
    final critCount = records.where((r) => ((r['probability'] as num?)?.toDouble() ?? 0) >= 0.65).length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(children: [

          // ── Top bar ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.borderColor))),
            child: Row(children: [
              const VeraMark(size: 14),
              const SizedBox(width: 8),
              Text('VERA', style: vMono(color: AppTheme.textPrimary, size: 9.5, letterSpacing: 0.18)),
              Text(' · historial', style: vMono(size: 9.5, letterSpacing: 0.18)),
              const Spacer(),
              Text('${records.length} registros', style: vMono(size: 9.5)),
            ]),
          ),

          Expanded(
            child: records.isEmpty
                ? _EmptyState()
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                      // ── Header ─────────────────────────────────────────────
                      Text('HISTORIAL.',
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: 28, fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary, height: 1)),
                      const SizedBox(height: 10),

                      // ── Summary badges ─────────────────────────────────────
                      Row(children: [
                        _SummaryBadge(count: okCount, label: 'ok', color: AppTheme.successColor),
                        const SizedBox(width: 8),
                        _SummaryBadge(count: warnCount, label: 'warn', color: AppTheme.warningColor),
                        const SizedBox(width: 8),
                        _SummaryBadge(count: critCount, label: 'crit', color: AppTheme.dangerColor),
                        const Spacer(),
                        Text('total: ${records.length}', style: vMono(size: 9.5, letterSpacing: 0.18)),
                      ]),

                      const SizedBox(height: 16),

                      // ── Trend chart ────────────────────────────────────────
                      if (trend.isNotEmpty)
                        VeraFrame(
                          id: 'trend.7d',
                          title: 'tendencia de salud',
                          status: Text('últimos 7 días', style: vMono(size: 9)),
                          child: SizedBox(
                            height: 130,
                            child: LineChart(LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (_) => FlLine(
                                    color: AppTheme.borderColor, strokeWidth: 1),
                              ),
                              borderData: FlBorderData(show: false),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(sideTitles: SideTitles(
                                  showTitles: true, reservedSize: 28,
                                  getTitlesWidget: (v, _) => Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Text('${v.toInt()}', style: vMono(size: 8)),
                                  ),
                                )),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(sideTitles: SideTitles(
                                  showTitles: true, reservedSize: 20,
                                  getTitlesWidget: (v, _) {
                                    final i = v.toInt();
                                    if (i < 0 || i >= trend.length) return const SizedBox();
                                    return Text(trend[i].label, style: vMono(size: 8));
                                  },
                                )),
                              ),
                              minY: 0, maxY: 100,
                              lineBarsData: [
                                LineChartBarData(
                                  spots: spots,
                                  isCurved: true,
                                  color: AppTheme.textSecondary,
                                  barWidth: 1.5,
                                  dotData: FlDotData(
                                    getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                                        radius: 2.5,
                                        color: AppTheme.textPrimary,
                                        strokeWidth: 0,
                                        strokeColor: Colors.transparent),
                                  ),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.white.withValues(alpha: 0.06),
                                        Colors.white.withValues(alpha: 0.0),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // ── Timeline ───────────────────────────────────────────
                      Row(children: [
                        Text('[ timeline ]', style: vMono(color: AppTheme.textFaint, size: 9, letterSpacing: 0.18)),
                        const Spacer(),
                        Text('${records.length} entradas', style: vMono(size: 9)),
                      ]),
                      const SizedBox(height: 10),

                      for (var i = 0; i < records.length; i++) ...[
                        _HistoryTimelineItem(
                          record: records[records.length - 1 - i],
                          index: records.length - 1 - i,
                          isLast: i == records.length - 1,
                        ),
                      ],
                    ]),
                  ),
          ),
        ]),
      ),
    );
  }
}

// ─── Summary badge ────────────────────────────────────────────────────────────

class _SummaryBadge extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  const _SummaryBadge({required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: RichText(
        text: TextSpan(children: [
          TextSpan(text: '$count', style: vMono(size: 13, weight: FontWeight.w700, color: color)),
          TextSpan(text: ' $label', style: vMono(size: 9, color: color.withValues(alpha: 0.8))),
        ]),
      ),
    );
  }
}

// ─── Timeline item ────────────────────────────────────────────────────────────

class _HistoryTimelineItem extends StatelessWidget {
  final Map<String, dynamic> record;
  final int index;
  final bool isLast;

  const _HistoryTimelineItem({required this.record, required this.index, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final ts = DateTime.tryParse(record['timestamp']?.toString() ?? '');
    final prob = ((record['probability'] as num?)?.toDouble() ?? 0.0);
    final health = ((record['health'] as num?)?.toDouble() ?? ((1 - prob) * 100)).clamp(0, 100).toDouble();
    final anomaly = record['anomaly'] == true || record['anomaly'] == 'true';
    final mode = record['mode']?.toString() ?? 'demo';

    final statusColor = prob >= 0.65
        ? AppTheme.dangerColor
        : prob >= 0.40
            ? AppTheme.warningColor
            : AppTheme.successColor;
    final statusLabel = prob >= 0.65 ? 'crítico' : prob >= 0.40 ? 'alerta' : 'ok';

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Date rail
      SizedBox(
        width: 52,
        child: Column(children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor,
                boxShadow: [BoxShadow(color: statusColor.withValues(alpha: 0.5), blurRadius: 6)]),
          ),
          if (!isLast)
            Container(width: 1, height: 90, color: AppTheme.borderColor),
        ]),
      ),

      // Content card
      Expanded(
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(
                ts != null ? DateFormat('dd MMM · HH:mm', 'es').format(ts) : 'sin fecha',
                style: vMono(color: AppTheme.textSecondary, size: 9.5, letterSpacing: 0.18),
              ),
              const Spacer(),
              VeraTag(label: statusLabel.toUpperCase(), color: statusColor),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                VeraDataLine(k: 'prob', v: '${(prob * 100).toStringAsFixed(1)}%', valueColor: statusColor),
                VeraDataLine(k: 'salud', v: '${health.toInt()}%'),
                VeraDataLine(k: 'anomalía', v: anomaly ? 'sí' : 'no',
                    valueColor: anomaly ? AppTheme.dangerColor : AppTheme.successColor),
              ])),
              VeraRing(
                value: health, max: 100, color: statusColor,
                size: 50, strokeWidth: 4,
                center: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('${health.toInt()}', style: GoogleFonts.spaceGrotesk(
                      fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary, height: 1)),
                  Text('%', style: vMono(size: 7, color: AppTheme.textFaint)),
                ]),
              ),
            ]),
            VeraDataLine(k: 'modo', v: mode),
          ]),
        ),
      ),
    ]);
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('[ historial ]', style: vMono(color: AppTheme.textFaint, size: 9, letterSpacing: 0.18)),
        const SizedBox(height: 12),
        Text('SIN REGISTROS.', style: GoogleFonts.spaceGrotesk(
            fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.textFaint)),
        const SizedBox(height: 8),
        Text('realiza tu primer análisis', style: vMono(size: 11, letterSpacing: 0.18)),
      ]),
    );
  }
}

// ─── Data models ─────────────────────────────────────────────────────────────

class _TrendPoint {
  final DateTime date;
  final String label;
  final double health;
  const _TrendPoint({required this.date, required this.label, required this.health});
}
