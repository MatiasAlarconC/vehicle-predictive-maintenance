import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vehicle_predictive_maintenance_app/app/theme/app_theme.dart';
import 'package:vehicle_predictive_maintenance_app/app/widgets/vera_components.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressCtrl;
  late AnimationController _ringCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _progressAnim;
  late Animation<double> _fadeAnim;

  static const _lines = [
    _BootLine('init  ', 'firmware v1.0.0 build 2046', 0),
    _BootLine('auth  ', 'device signature ok', 220),
    _BootLine('obd-ii', 'handshake 192.168.4.1', 520),
    _BootLine('model ', 'load XGBoost + RF', 920),
    _BootLine('lime  ', 'prime explainability', 1320),
    _BootLine('ready ', 'awaiting telemetry…', 1720),
  ];
  final List<bool> _visible = List.filled(6, false);

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
    _progressAnim = Tween<double>(begin: 0, end: 0.72).animate(_progressCtrl);
    _ringCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = Tween<double>(begin: 1, end: 0)
        .animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn));
    _progressCtrl.forward();
    for (var i = 0; i < _lines.length; i++) {
      Future.delayed(Duration(milliseconds: _lines[i].delayMs), () {
        if (mounted) setState(() => _visible[i] = true);
      });
    }
    _navigate();
  }

  void _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2900));
    if (!mounted) return;
    await _fadeCtrl.forward();
    if (mounted) context.go('/dashboard');
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    _ringCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: _SplashBgPainter())),
          SafeArea(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── Top bar ─────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppTheme.borderColor))),
                child: Row(children: [
                  const VeraLiveDot(),
                  const SizedBox(width: 6),
                  Text('VERA', style: vMono(color: AppTheme.textPrimary, size: 9.5, letterSpacing: 0.18)),
                  Text('  v1.0.0', style: vMono(size: 9.5, letterSpacing: 0.18)),
                  const Spacer(),
                  Text('stage 02 / boot', style: vMono(size: 9.5, letterSpacing: 0.18)),
                ]),
              ),

              // ── Hero row ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 32, 22, 0),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: 120, height: 120, child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _ringCtrl,
                        builder: (_, __) => CustomPaint(
                          size: const Size(120, 120),
                          painter: _SplashRingPainter(t: _ringCtrl.value),
                        ),
                      ),
                      const VeraMark(size: 52, color: AppTheme.textPrimary),
                    ],
                  )),
                  const SizedBox(width: 18),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('ESID-VERA-2046', style: vMono(size: 9, letterSpacing: 0.18)),
                    const SizedBox(height: 6),
                    Text('VERA', style: GoogleFonts.spaceGrotesk(
                      fontSize: 50, fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary, letterSpacing: 3, height: 0.9,
                    )),
                    const SizedBox(height: 8),
                    Text('VEHICLE DIAGNOSTICS\n+ ML ENSEMBLE',
                        style: vMono(size: 10, color: AppTheme.primaryColor, letterSpacing: 0.24)),
                  ])),
                ]),
              ),

              // ── Boot log ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
                child: VeraFrame(
                  id: 'boot.log',
                  title: 'initialisation sequence',
                  status: AnimatedBuilder(
                    animation: _progressAnim,
                    builder: (_, __) => Text(
                      '${(_progressAnim.value * 100).toInt()}%',
                      style: vMono(color: AppTheme.primaryColor, size: 9),
                    ),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(_lines.length, (i) {
                      if (!_visible[i]) return const SizedBox.shrink();
                      final isLast = i == _lines.length - 1 ||
                          (i < _lines.length - 1 && !_visible[i + 1]);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(children: [
                          Text('[${_lines[i].tag}]',
                              style: vMono(color: AppTheme.primaryColor, size: 10.5, weight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_lines[i].text,
                              style: vMono(size: 10.5, color: AppTheme.textSecondary, letterSpacing: 0.04))),
                          if (isLast)
                            _BlinkCursor()
                          else
                            Text('ok', style: vMono(color: AppTheme.textFaint, size: 10.5)),
                        ]),
                      );
                    }),
                  ),
                ),
              ),

              // ── Progress ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
                child: Column(children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('initialising', style: vMono(size: 9, letterSpacing: 0.16)),
                      AnimatedBuilder(
                        animation: _ringCtrl,
                        builder: (_, __) => Text(
                          'frame: ${(_ringCtrl.value * 1696).toInt().toString().padLeft(4, '0')}',
                          style: vMono(size: 9, letterSpacing: 0.16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: AnimatedBuilder(
                      animation: _progressAnim,
                      builder: (_, __) => LinearProgressIndicator(
                        value: _progressAnim.value,
                        minHeight: 4,
                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      ),
                    ),
                  ),
                ]),
              ),

              const Spacer(),
              const _TickerBar(),
              const SizedBox(height: 16),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _BootLine {
  final String tag;
  final String text;
  final int delayMs;
  const _BootLine(this.tag, this.text, this.delayMs);
}

// ─── Blink cursor ─────────────────────────────────────────────────────────────
class _BlinkCursor extends StatefulWidget {
  @override
  State<_BlinkCursor> createState() => _BlinkCursorState();
}
class _BlinkCursorState extends State<_BlinkCursor> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Text('█',
        style: vMono(color: AppTheme.primaryColor.withValues(alpha: _ctrl.value), size: 10.5)),
    );
  }
}

// ─── Ticker bar ───────────────────────────────────────────────────────────────
class _TickerBar extends StatefulWidget {
  const _TickerBar();
  @override
  State<_TickerBar> createState() => _TickerBarState();
}
class _TickerBarState extends State<_TickerBar> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    const items = 'BUF 36/40  ·  CPU 12%  ·  RATE 10 Hz  ·  TLM 12 ch  ·  PI 04 · arm64  ·  DATA 184 ms';
    return Container(
      height: 28,
      decoration: const BoxDecoration(
          border: Border.symmetric(horizontal: BorderSide(color: AppTheme.borderColor))),
      clipBehavior: Clip.hardEdge,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Transform.translate(
          offset: Offset(-_ctrl.value * 400, 0),
          child: Row(children: [
            for (var i = 0; i < 3; i++)
              Padding(padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(items, style: vMono(size: 9, letterSpacing: 0.18))),
          ]),
        ),
      ),
    );
  }
}

// ─── Painters ─────────────────────────────────────────────────────────────────
class _SplashBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // pure black — no background wash
  }
  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

class _SplashRingPainter extends CustomPainter {
  final double t;
  _SplashRingPainter({required this.t});
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r1 = size.width / 2 - 4;
    final r2 = size.width / 2 - 16;
    // outer arc
    canvas.drawArc(Rect.fromCircle(center: c, radius: r1),
      -math.pi / 2 + t * 2 * math.pi, math.pi * 0.5, false,
      Paint()..color = AppTheme.primaryColor.withValues(alpha: 0.9)
        ..strokeWidth = 2..style = PaintingStyle.stroke..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    // inner arc
    canvas.drawArc(Rect.fromCircle(center: c, radius: r2),
      -math.pi / 2 - t * 2 * math.pi * 0.7, math.pi * 0.6, false,
      Paint()..color = AppTheme.primaryDim.withValues(alpha: 0.7)
        ..strokeWidth = 1.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    // tick marks
    for (var i = 0; i < 60; i++) {
      final angle = i / 60 * 2 * math.pi;
      final isMajor = i % 5 == 0;
      final outer = c + Offset(math.cos(angle) * (r1 - 1), math.sin(angle) * (r1 - 1));
      final inner = c + Offset(math.cos(angle) * (r1 - (isMajor ? 8 : 5)), math.sin(angle) * (r1 - (isMajor ? 8 : 5)));
      canvas.drawLine(outer, inner, Paint()..color = AppTheme.primaryColor.withValues(alpha: isMajor ? 0.5 : 0.18)..strokeWidth = 1);
    }
    // orbital dot
    final dotAngle = -math.pi / 2 + t * 2 * math.pi;
    final dotPos = c + Offset(math.cos(dotAngle) * r1, math.sin(dotAngle) * r1);
    canvas.drawCircle(dotPos, 4, Paint()..color = AppTheme.primaryColor..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    canvas.drawCircle(dotPos, 3.5, Paint()..color = AppTheme.primaryColor);
  }
  @override
  bool shouldRepaint(_SplashRingPainter old) => old.t != t;
}
