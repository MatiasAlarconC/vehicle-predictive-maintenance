import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:vehicle_predictive_maintenance_app/app/theme/app_theme.dart';
import 'package:vehicle_predictive_maintenance_app/app/widgets/custom_card.dart';
import 'package:vehicle_predictive_maintenance_app/core/enums/app_enums.dart';
import 'package:vehicle_predictive_maintenance_app/core/providers/app_provider.dart';
import 'package:vehicle_predictive_maintenance_app/core/providers/diagnostics_provider.dart';
import 'package:vehicle_predictive_maintenance_app/core/providers/history_provider.dart';
import 'package:vehicle_predictive_maintenance_app/core/providers/prediction_provider.dart';
import 'package:vehicle_predictive_maintenance_app/features/prediction/widgets/explanation_widget.dart';
import 'package:vehicle_predictive_maintenance_app/models/prediction_response.dart';

class PredictionScreen extends StatefulWidget {
  const PredictionScreen({super.key});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  @override
  void initState() {
    super.initState();
    // Dispara la predicción automáticamente usando la última lectura OBD
    WidgetsBinding.instance.addPostFrameCallback((_) => _runPrediction());
  }

  void _runPrediction() {
    final diagnostics = context.read<DiagnosticsProvider>();
    final appProvider = context.read<AppProvider>();
    final predictionProvider = context.read<PredictionProvider>();
    final reading = diagnostics.latestReading;

    if (reading == null) return;

    predictionProvider.predictFromReading(
      reading,
      appProvider.appMode,
      baseUrl: appProvider.baseUrl,
      onFallbackToDemo: () async {
        await appProvider.fallbackToDemo();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Consumer<PredictionProvider>(
        builder: (context, provider, _) {
          switch (provider.status) {
            case PredictionStatus.loading:
              return const _LoadingView();
            case PredictionStatus.success:
              return _ResultView(response: provider.predictionResponse!);
            case PredictionStatus.error:
              return _ErrorView(
                message: provider.errorMessage ?? 'Error desconocido',
                onRetry: _runPrediction,
              );
            case PredictionStatus.initial:
              return const _LoadingView();
          }
        },
      ),
    );
  }
}

// ── Loading ────────────────────────────────────────────────────────────────────

class _LoadingView extends StatefulWidget {
  const _LoadingView();

  @override
  State<_LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<_LoadingView>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _rotAnim;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
    _rotAnim = Tween<double>(begin: 0, end: 2 * math.pi).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _rotAnim,
                    builder: (_, __) => Transform.rotate(
                      angle: _rotAnim.value,
                      child: CustomPaint(
                        size: const Size(140, 140),
                        painter: _ScanRingPainter(color: AppTheme.primaryColor),
                      ),
                    ),
                  ),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.surface,
                      boxShadow: AppTheme.glowShadow(AppTheme.primaryColor),
                    ),
                    child: const Icon(
                      Icons.psychology_rounded,
                      color: AppTheme.primaryColor,
                      size: 36,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'ANALIZANDO',
              style: GoogleFonts.rajdhani(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Procesando datos con modelo XGBoost...',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 200,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  minHeight: 3,
                  backgroundColor: AppTheme.borderColor,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanRingPainter extends CustomPainter {
  final Color color;
  _ScanRingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      math.pi * 1.5,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Result ─────────────────────────────────────────────────────────────────────

class _ResultView extends StatelessWidget {
  final PredictionResponse response;
  const _ResultView({required this.response});

  Color get _stateColor {
    if (response.probability >= 0.65) return AppTheme.dangerColor;
    if (response.probability >= 0.40) return AppTheme.warningColor;
    return AppTheme.successColor;
  }

  String get _stateLabel {
    if (response.probability >= 0.65) return 'ANOMALÍA CRÍTICA';
    if (response.probability >= 0.40) return 'ALERTA';
    return 'SISTEMA NORMAL';
  }

  IconData get _stateIcon {
    if (response.probability >= 0.65) return Icons.dangerous_rounded;
    if (response.probability >= 0.40) return Icons.warning_amber_rounded;
    return Icons.verified_rounded;
  }

  Future<void> _saveToHistory(BuildContext context) async {
    final diagnostics = context.read<DiagnosticsProvider>();
    final appProvider = context.read<AppProvider>();

    await context.read<HistoryProvider>().saveRecord({
      'timestamp': DateTime.now().toIso8601String(),
      'anomaly': response.anomaly,
      'probability': response.probability,
      'health': diagnostics.vehicleHealth,
      'mode': appProvider.appMode.name,
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Diagnóstico guardado en historial'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _stateColor;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _ResultHeader(
            color: color,
            icon: _stateIcon,
            label: _stateLabel,
            probability: response.probability,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 8),

              // Medidor circular de probabilidad
              CustomCard(
                borderColor: color.withValues(alpha: 0.3),
                shadows: AppTheme.glowShadow(color, intensity: 0.12),
                child: Column(
                  children: [
                    _ProbabilityMeter(
                        probability: response.probability, color: color),
                    const SizedBox(height: 12),
                    Text(
                      'PROBABILIDAD DE ANOMALÍA',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 2,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Explicación XAI
              CustomCard(
                child: ExplanationWidget(explanation: response.explanation),
              ),

              const SizedBox(height: 20),

              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _saveToHistory(context),
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: AppTheme.glowShadow(AppTheme.primaryColor,
                              intensity: 0.3),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.save_rounded,
                                color: Colors.black, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'GUARDAR',
                              style: TextStyle(
                                fontFamily: 'Rajdhani',
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context.read<PredictionProvider>().reset(),
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: const Border.fromBorderSide(
                            BorderSide(color: AppTheme.borderColor),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.refresh_rounded,
                                color: AppTheme.primaryColor, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'REPETIR',
                              style: TextStyle(
                                fontFamily: 'Rajdhani',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryColor,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _ResultHeader extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final double probability;

  const _ResultHeader({
    required this.color,
    required this.icon,
    required this.label,
    required this.probability,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        bottom: 28,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.12),
            AppTheme.background,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          // Back button
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => context.go('/dashboard'),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: const Border.fromBorderSide(
                    BorderSide(color: AppTheme.borderColor),
                  ),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppTheme.textPrimary, size: 16),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Icono grande con glow
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
              border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
              boxShadow: AppTheme.glowShadow(color, intensity: 0.3),
            ),
            child: Icon(icon, color: color, size: 38),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: GoogleFonts.rajdhani(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Resultado del análisis ML',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ProbabilityMeter extends StatelessWidget {
  final double probability;
  final Color color;
  const _ProbabilityMeter({required this.probability, required this.color});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: probability),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) {
        return SizedBox(
          width: 160,
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(160, 160),
                painter: _ProbArcPainter(progress: v, color: color),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(v * 100).toStringAsFixed(1)}',
                    style: GoogleFonts.rajdhani(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: color,
                      height: 1,
                    ),
                  ),
                  Text(
                    '%',
                    style: GoogleFonts.rajdhani(
                      fontSize: 16,
                      color: color.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProbArcPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ProbArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const startAngle = -math.pi / 2;
    const sweepAngle = 2 * math.pi;

    final trackPaint = Paint()
      ..color = AppTheme.borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    canvas.drawCircle(center, radius, trackPaint);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * progress,
      false,
      progressPaint,
    );

    // Glow tip
    if (progress > 0) {
      final endAngle = startAngle + sweepAngle * progress;
      final tipX = center.dx + radius * math.cos(endAngle);
      final tipY = center.dy + radius * math.sin(endAngle);
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(Offset(tipX, tipY), 7, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ProbArcPainter old) =>
      old.progress != progress || old.color != color;
}

// ── Error ──────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.dangerColor.withValues(alpha: 0.1),
                ),
                child: const Icon(Icons.error_outline_rounded,
                    color: AppTheme.dangerColor, size: 48),
              ),
              const SizedBox(height: 24),
              Text(
                'Error en el análisis',
                style: GoogleFonts.rajdhani(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
