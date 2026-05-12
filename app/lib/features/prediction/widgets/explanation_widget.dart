import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vehicle_predictive_maintenance_app/app/theme/app_theme.dart';
import 'package:vehicle_predictive_maintenance_app/models/prediction_response.dart';

/// Widget de explicabilidad XAI (LIME/SHAP) con diseño premium.
class ExplanationWidget extends StatefulWidget {
  final List<ExplanationItem> explanation;

  const ExplanationWidget({super.key, required this.explanation});

  @override
  State<ExplanationWidget> createState() => _ExplanationWidgetState();
}

class _ExplanationWidgetState extends State<ExplanationWidget> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final shown = _expanded
        ? widget.explanation
        : widget.explanation.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.lightbulb_outline_rounded,
                  color: AppTheme.primaryColor, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿POR QUÉ ESTE RESULTADO?',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  'Explicación LIME del modelo',
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Barras de contribución
        ...shown.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return _ExplanationBar(
            item: item,
            rank: index + 1,
            delay: Duration(milliseconds: index * 150),
          );
        }),

        // Toggle expandir
        if (widget.explanation.length > 3)
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: const Border.fromBorderSide(
                  BorderSide(color: AppTheme.borderColor),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: AppTheme.primaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _expanded ? 'Ver menos' : 'Ver análisis completo',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ExplanationBar extends StatefulWidget {
  final ExplanationItem item;
  final int rank;
  final Duration delay;

  const _ExplanationBar({
    required this.item,
    required this.rank,
    required this.delay,
  });

  @override
  State<_ExplanationBar> createState() => _ExplanationBarState();
}

class _ExplanationBarState extends State<_ExplanationBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final riskUp = widget.item.direction == 'aumenta riesgo';
    final color = riskUp ? AppTheme.dangerColor : AppTheme.successColor;
    final percent =
        (widget.item.contribution * 100).clamp(0, 100).toDouble();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Número de ranking
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${widget.rank}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.item.variable.replaceAll('_', ' '),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  riskUp ? '↑ riesgo' : '↓ riesgo',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AnimatedBuilder(
                  animation: _anim,
                  builder: (_, __) => ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_anim.value * percent / 100).clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: AppTheme.borderColor,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${percent.toStringAsFixed(1)}%',
                style: GoogleFonts.rajdhani(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.item.variable}: contribuye ${percent.toStringAsFixed(1)}% a esta ${riskUp ? 'alerta' : 'estabilidad'}',
            style: const TextStyle(
                fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
