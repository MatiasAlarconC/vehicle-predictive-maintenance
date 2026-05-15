import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:vehicle_predictive_maintenance_app/app/theme/app_theme.dart';
import 'package:vehicle_predictive_maintenance_app/app/widgets/vera_components.dart';
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
      onFallbackToDemo: () async { await appProvider.fallbackToDemo(); },
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
            case PredictionStatus.initial:
              return const _LoadingView();
            case PredictionStatus.success:
              return _ResultView(response: provider.predictionResponse!, onRetry: _runPrediction);
            case PredictionStatus.error:
              return _ErrorView(message: provider.errorMessage ?? 'Error desconocido', onRetry: _runPrediction);
          }
        },
      ),
    );
  }
}

// ─── Loading view ─────────────────────────────────────────────────────────────

class _LoadingView extends StatefulWidget {
  const _LoadingView();
  @override
  State<_LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<_LoadingView> with TickerProviderStateMixin {
  late AnimationController _ringCtrl;
  late AnimationController _blinkCtrl;
  final List<String> _steps = const [
    '[data] cargando lectura obd-ii',
    '[pre]  normalizando features',
    '[mdl]  ejecutando xgboost',
    '[mdl]  ejecutando random-forest',
    '[xai]  calculando lime explainer',
    '[out]  generando resultado',
  ];
  int _doneSteps = 0;

  @override
  void initState() {
    super.initState();
    _ringCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _blinkCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
    _scheduleSteps();
  }

  void _scheduleSteps() {
    for (var i = 0; i < _steps.length; i++) {
      Future.delayed(Duration(milliseconds: 300 + i * 340), () {
        if (mounted) setState(() => _doneSteps = i + 1);
      });
    }
  }

  @override
  void dispose() { _ringCtrl.dispose(); _blinkCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(children: [
        // Top bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.borderColor))),
          child: Row(children: [
            const VeraMark(size: 14),
            const SizedBox(width: 8),
            Text('VERA', style: vMono(color: AppTheme.textPrimary, size: 9.5, letterSpacing: 0.18)),
            Text(' · ia · inference', style: vMono(size: 9.5, letterSpacing: 0.18)),
            const Spacer(),
            const VeraLiveDot(),
            const SizedBox(width: 5),
            Text('procesando…', style: vMono(size: 9.5)),
          ]),
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Hero
              Center(
                child: Column(children: [
                  // Spinning ring + VeraMark center
                  SizedBox(
                    width: 120, height: 120,
                    child: Stack(alignment: Alignment.center, children: [
                      AnimatedBuilder(
                        animation: _ringCtrl,
                        builder: (_, __) => Transform.rotate(
                          angle: _ringCtrl.value * 2 * math.pi,
                          child: CustomPaint(
                            size: const Size(120, 120),
                            painter: _ScanRingPainter(),
                          ),
                        ),
                      ),
                      // Inner ring (counter-rotate)
                      AnimatedBuilder(
                        animation: _ringCtrl,
                        builder: (_, __) => Transform.rotate(
                          angle: -_ringCtrl.value * 2 * math.pi * 0.7,
                          child: CustomPaint(
                            size: const Size(90, 90),
                            painter: _ScanRingPainter(radius: 40, alpha: 0.25),
                          ),
                        ),
                      ),
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.surface,
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: const Center(child: VeraMark(size: 18)),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  RichText(
                    text: TextSpan(children: [
                      TextSpan(
                        text: 'ANALIZANDO',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 28, fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary, height: 1),
                      ),
                      WidgetSpan(child: AnimatedBuilder(
                        animation: _blinkCtrl,
                        builder: (_, __) => Text(
                          '_',
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: 28, fontWeight: FontWeight.w700,
                              color: _blinkCtrl.value > 0.5 ? AppTheme.primaryColor : Colors.transparent, height: 1),
                        ),
                      )),
                    ]),
                  ),
                  const SizedBox(height: 6),
                  Text('modelo xgboost + random forest',
                      style: vMono(size: 10, letterSpacing: 0.18)),
                ]),
              ),

              const SizedBox(height: 28),

              // Pipeline execution log
              VeraFrame(
                id: 'exec.log',
                title: 'execution pipeline',
                status: Text('${_doneSteps}/${_steps.length}', style: vMono(color: AppTheme.textFaint, size: 9)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(_steps.length, (i) {
                    final done = i < _doneSteps;
                    final active = i == _doneSteps;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(children: [
                        Text(
                          _steps[i],
                          style: vMono(
                            size: 10.5,
                            color: done ? AppTheme.textPrimary : AppTheme.textFaint,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const Spacer(),
                        if (done)
                          Text('ok', style: vMono(size: 10.5, color: AppTheme.primaryColor))
                        else if (active)
                          AnimatedBuilder(
                            animation: _blinkCtrl,
                            builder: (_, __) => Text('█',
                                style: vMono(size: 10.5,
                                    color: _blinkCtrl.value > 0.5 ? AppTheme.primaryColor : Colors.transparent)),
                          )
                        else
                          Text('--', style: vMono(size: 10.5, color: AppTheme.textFaint)),
                      ]),
                    );
                  }),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _ScanRingPainter extends CustomPainter {
  final double radius;
  final double alpha;
  const _ScanRingPainter({this.radius = 56, this.alpha = 0.5});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0, math.pi * 1.6, false,
      Paint()
        ..color = AppTheme.primaryColor.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 1.7, math.pi * 0.3, false,
      Paint()
        ..color = AppTheme.primaryColor.withValues(alpha: alpha * 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─── Result view ──────────────────────────────────────────────────────────────

class _ResultView extends StatelessWidget {
  final PredictionResponse response;
  final VoidCallback onRetry;
  const _ResultView({required this.response, required this.onRetry});

  Color get _color => response.probability >= 0.65
      ? AppTheme.dangerColor
      : response.probability >= 0.40
          ? AppTheme.warningColor
          : AppTheme.successColor;

  String get _stateId => response.probability >= 0.65
      ? 'anomalía crítica'
      : response.probability >= 0.40
          ? 'alerta'
          : 'sistema normal';

  String get _stateTitle => response.probability >= 0.65
      ? 'ANOMALÍA CRÍTICA.'
      : response.probability >= 0.40
          ? 'REVISAR PRONTO.'
          : 'TODO NORMAL.';

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Diagnóstico guardado en historial',
            style: vMono(color: Colors.black, size: 12)),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    final pct = response.probability;

    return SafeArea(
      child: Column(children: [
        // Top bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            border: const Border(bottom: BorderSide(color: AppTheme.borderColor)),
            color: color.withValues(alpha: 0.04),
          ),
          child: Row(children: [
            const VeraMark(size: 14),
            const SizedBox(width: 8),
            Text('VERA', style: vMono(color: AppTheme.textPrimary, size: 9.5, letterSpacing: 0.18)),
            Text(' · resultado · ia', style: vMono(size: 9.5, letterSpacing: 0.18)),
            const Spacer(),
            GestureDetector(
              onTap: () => context.go('/dashboard'),
              child: Text('cockpit →', style: vMono(size: 9.5, color: AppTheme.textSecondary, letterSpacing: 0.18)),
            ),
          ]),
        ),

        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // ── State hero ────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.06),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      'resultado · $_stateId',
                      style: vMono(size: 9, letterSpacing: 0.18),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _stateTitle,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 26, fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ])),
                  VeraRing(
                    value: pct,
                    max: 1.0,
                    color: color,
                    size: 80,
                    strokeWidth: 6,
                    center: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(
                        '${(pct * 100).toInt()}%',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 20, fontWeight: FontWeight.w700, color: color, height: 1),
                      ),
                      Text('prob', style: vMono(size: 8, color: AppTheme.textFaint)),
                    ]),
                  ),
                ]),
              ),

              const SizedBox(height: 14),

              // ── Probability bar breakdown ─────────────────────────────────
              VeraFrame(
                id: 'prob.dist',
                title: 'distribución de probabilidad',
                status: VeraTag(label: '${(pct * 100).toInt()}%', color: color),
                child: Column(children: [
                  VeraDataLine(k: 'anomalía detectada', v: response.anomaly ? 'sí' : 'no',
                      valueColor: response.anomaly ? AppTheme.dangerColor : AppTheme.successColor),
                  VeraDataLine(k: 'probabilidad', v: '${(pct * 100).toStringAsFixed(1)}%',
                      valueColor: color),
                  const SizedBox(height: 8),
                  _ProbBar(value: pct, color: color),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('0 · normal', style: vMono(size: 9, color: AppTheme.textFaint)),
                      Text('50 · alerta', style: vMono(size: 9, color: AppTheme.warningColor)),
                      Text('100 · crítico', style: vMono(size: 9, color: AppTheme.dangerColor)),
                    ],
                  ),
                ]),
              ),

              const SizedBox(height: 14),

              // ── XAI Explanation ───────────────────────────────────────────
              VeraFrame(
                id: 'xai.lime',
                title: 'explicabilidad xai',
                status: VeraTag(label: 'LIME'),
                child: ExplanationWidget(explanation: response.explanation),
              ),

              const SizedBox(height: 20),

              // ── Action buttons ────────────────────────────────────────────
              Row(children: [
                Expanded(child: GestureDetector(
                  onTap: () => _saveToHistory(context),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.20), blurRadius: 12, spreadRadius: -6)],
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.save_rounded, color: Colors.black, size: 16),
                      const SizedBox(width: 8),
                      Text('GUARDAR', style: vMono(size: 12, weight: FontWeight.w700, color: Colors.black, letterSpacing: 0.12)),
                    ]),
                  ),
                )),
                const SizedBox(width: 10),
                Expanded(child: GestureDetector(
                  onTap: () {
                    context.read<PredictionProvider>().reset();
                    onRetry();
                  },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: AppTheme.borderStrong),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary, size: 16),
                      const SizedBox(width: 8),
                      Text('REPETIR', style: vMono(size: 12, weight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 0.12)),
                    ]),
                  ),
                )),
              ]),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _ProbBar extends StatelessWidget {
  final double value;
  final Color color;
  const _ProbBar({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6,
      decoration: BoxDecoration(color: AppTheme.borderColor, borderRadius: BorderRadius.circular(3)),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)],
          ),
        ),
      ),
    );
  }
}

// ─── Error view ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.borderColor))),
          child: Row(children: [
            const VeraMark(size: 14),
            const SizedBox(width: 8),
            Text('VERA', style: vMono(color: AppTheme.textPrimary, size: 9.5)),
            Text(' · error', style: vMono(size: 9.5, color: AppTheme.dangerColor)),
            const Spacer(),
            GestureDetector(
              onTap: () => context.go('/dashboard'),
              child: Text('volver →', style: vMono(size: 9.5, color: AppTheme.textSecondary)),
            ),
          ]),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('ERROR.', style: GoogleFonts.spaceGrotesk(
                  fontSize: 32, fontWeight: FontWeight.w700,
                  color: AppTheme.dangerColor)),
              const SizedBox(height: 12),
              VeraFrame(
                id: 'err.msg',
                title: 'error detail',
                child: Text(message, style: vMono(size: 11, color: AppTheme.dangerColor, letterSpacing: 0.1)),
              ),
              const SizedBox(height: 20),
              VeraButton(label: 'REINTENTAR', onTap: onRetry),
            ]),
          ),
        ),
      ]),
    );
  }
}
