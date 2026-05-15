// vera_components.dart — Vera design system: terminal/HUD shared primitives
// Design tokens: bg #000000, primary #03F263, fonts: Space Grotesk + JetBrains Mono

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vehicle_predictive_maintenance_app/app/theme/app_theme.dart';

// ─── Typography helpers ──────────────────────────────────────────────────────

TextStyle vDisplay(
        {double size = 32,
        FontWeight weight = FontWeight.w700,
        Color color = AppTheme.textPrimary,
        double? letterSpacing}) =>
    GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing ?? -0.02 * size,
      height: 1.0,
    );

TextStyle vBody(
        {double size = 13,
        FontWeight weight = FontWeight.w400,
        Color color = AppTheme.textSecondary}) =>
    GoogleFonts.manrope(
      fontSize: size,
      fontWeight: weight,
      color: color,
    );

TextStyle vMono(
        {double size = 10,
        FontWeight weight = FontWeight.w500,
        Color color = AppTheme.textSecondary,
        double letterSpacing = 0.18}) =>
    GoogleFonts.jetBrainsMono(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
    );

// ─── Vera top utility bar ────────────────────────────────────────────────────

class VeraTopBar extends StatelessWidget {
  final String screen;
  final String? stage;
  final Widget? trailing;
  final bool showLive;

  const VeraTopBar({
    super.key,
    required this.screen,
    this.stage,
    this.trailing,
    this.showLive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
        color: Color(0x04000000),
      ),
      child: Row(
        children: [
          const VeraMark(size: 14),
          const SizedBox(width: 8),
          Text('VERA', style: vMono(color: AppTheme.textPrimary, size: 9.5, letterSpacing: 0.18)),
          Text(' · $screen',
              style: vMono(color: AppTheme.textFaint, size: 9.5, letterSpacing: 0.18)),
          const Spacer(),
          if (trailing != null) trailing!
          else if (showLive) ...[
            const VeraLiveDot(),
            const SizedBox(width: 5),
            Text('live', style: vMono(size: 9.5, letterSpacing: 0.18)),
          ] else if (stage != null)
            Text(stage!, style: vMono(size: 9.5, letterSpacing: 0.18)),
        ],
      ),
    );
  }
}

// ─── Vera "V" mark ──────────────────────────────────────────────────────────

class VeraMark extends StatelessWidget {
  final double size;
  final Color color;

  const VeraMark({super.key, this.size = 20, this.color = AppTheme.textPrimary});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _VeraMarkPainter(color: color),
    );
  }
}

class _VeraMarkPainter extends CustomPainter {
  final Color color;
  _VeraMarkPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.1, h * 0.2)
      ..lineTo(w * 0.5, h * 0.82)
      ..lineTo(w * 0.9, h * 0.2);
    canvas.drawPath(path, paint);

    // small dot below V — removed for minimal look
  }

  @override
  bool shouldRepaint(_VeraMarkPainter old) => old.color != color;
}

// ─── Live dot (blinking) ─────────────────────────────────────────────────────

class VeraLiveDot extends StatefulWidget {
  final Color color;
  final double size;

  const VeraLiveDot({
    super.key,
    this.color = AppTheme.primaryColor,
    this.size = 5,
  });

  @override
  State<VeraLiveDot> createState() => _VeraLiveDotState();
}

class _VeraLiveDotState extends State<VeraLiveDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: _anim.value),
          boxShadow: [
            BoxShadow(
                color: widget.color.withValues(alpha: _anim.value * 0.6),
                blurRadius: 6),
          ],
        ),
      ),
    );
  }
}

// ─── Vera Frame (card with [ID] TITLE header) ────────────────────────────────

class VeraFrame extends StatelessWidget {
  final String id;
  final String title;
  final Widget? status;
  final Widget child;
  final EdgeInsets? padding;
  final Color? borderColor;

  const VeraFrame({
    super.key,
    required this.id,
    required this.title,
    this.status,
    required this.child,
    this.padding,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor ?? AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
              color: Color(0x06000000),
            ),
            child: Row(
              children: [
                Text('[$id]',
                    style: vMono(color: AppTheme.textFaint, size: 9, letterSpacing: 0.14)),
                const SizedBox(width: 6),
                Text(title.toUpperCase(),
                    style: vMono(size: 9, color: AppTheme.textFaint, letterSpacing: 0.18)),
                const Spacer(),
                if (status != null) status!,
              ],
            ),
          ),
          Padding(
            padding: padding ?? const EdgeInsets.all(12),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ─── Vera metric tile (smart home style: label top + big value) ────────────────

class VeraMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color? valueColor;

  const VeraMetricTile({
    super.key,
    required this.label,
    required this.value,
    this.unit = '',
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          label,
          style: vMono(size: 9, color: AppTheme.textFaint, letterSpacing: 0.2),
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(children: [
            TextSpan(
              text: value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: valueColor ?? AppTheme.textPrimary,
                height: 1,
              ),
            ),
            if (unit.isNotEmpty)
              TextSpan(
                text: ' $unit',
                style: vMono(size: 10, color: AppTheme.textFaint),
              ),
          ]),
        ),
      ]),
    );
  }
}

// ─── Vera primary button ─────────────────────────────────────────────────────

class VeraButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final bool disabled;
  final bool outline;
  final IconData? icon;

  const VeraButton({
    super.key,
    required this.label,
    this.onTap,
    this.loading = false,
    this.disabled = false,
    this.outline = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final active = !disabled && !loading;
    final bg = outline
        ? Colors.transparent
        : active
            ? AppTheme.primaryColor
            : AppTheme.surface;
    final fg = outline
        ? AppTheme.primaryColor
        : active
            ? Colors.black
            : AppTheme.textSecondary;

    return GestureDetector(
      onTap: active ? onTap : null,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(30),
          border: outline
              ? Border.all(color: AppTheme.primaryColor)
              : disabled
                  ? Border.all(color: AppTheme.borderColor)
                  : null,
          boxShadow: active && !outline
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.25),
                    blurRadius: 16,
                    spreadRadius: -6,
                  ),
                ]
              : null,
        ),
        child: loading
            ? Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: fg, strokeWidth: 2),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon == null)
                    Text('> ', style: vMono(size: 14, color: fg.withValues(alpha: 0.6))),
                  Text(label,
                      style: vMono(
                          size: 13,
                          weight: FontWeight.w700,
                          color: fg,
                          letterSpacing: 0.12)),
                ],
              ),
      ),
    );
  }
}

// ─── Vera prompt field (terminal-style input) ─────────────────────────────────

class VeraPromptField extends StatelessWidget {
  // [id] is kept for API compatibility but no longer rendered visually.
  final String id;
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool focused;

  const VeraPromptField({
    super.key,
    required this.id,
    required this.label,
    required this.controller,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
    this.validator,
    this.focused = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: vMono(size: 9.5, color: AppTheme.textFaint, letterSpacing: 0.12)),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
          cursorColor: AppTheme.primaryColor,
          cursorWidth: 2,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            hintText: label,
            hintStyle: GoogleFonts.manrope(
              fontSize: 14,
              color: AppTheme.textFaint,
            ),
            suffixIcon: suffix != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: suffix,
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(),
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.dangerColor),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.dangerColor),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Vera data line (key: value row) ─────────────────────────────────────────

class VeraDataLine extends StatelessWidget {
  final String k;
  final String v;
  final Color? valueColor;

  const VeraDataLine({
    super.key,
    required this.k,
    required this.v,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(k, style: vMono(size: 10.5, letterSpacing: 0.1)),
          const Spacer(),
          Text(v,
              style: vMono(
                  size: 10.5,
                  weight: FontWeight.w700,
                  color: valueColor ?? AppTheme.textPrimary,
                  letterSpacing: 0.06)),
        ],
      ),
    );
  }
}

// ─── Vera label tag ──────────────────────────────────────────────────────────

class VeraTag extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;

  const VeraTag({
    super.key,
    required this.label,
    this.color = AppTheme.textSecondary,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(3),
        border: filled ? null : Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label.toUpperCase(),
        style: vMono(
            size: 8.5,
            weight: FontWeight.w700,
            color: filled ? Colors.black : color,
            letterSpacing: 0.1),
      ),
    );
  }
}

// ─── Vera corner brackets painter ────────────────────────────────────────────

class VeraCornerBrackets extends StatelessWidget {
  final Color color;
  final double size;
  final Widget child;

  const VeraCornerBrackets({
    super.key,
    this.color = AppTheme.borderStrong,
    this.size = 18,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: CustomPaint(
            painter: _CornerBracketsPainter(color: color, len: size),
          ),
        ),
      ],
    );
  }
}

class _CornerBracketsPainter extends CustomPainter {
  final Color color;
  final double len;

  _CornerBracketsPainter({required this.color, required this.len});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final corners = [
      // top-left
      [Offset(0, len), const Offset(0, 0), Offset(len, 0)],
      // top-right
      [Offset(size.width - len, 0), Offset(size.width, 0), Offset(size.width, len)],
      // bottom-left
      [Offset(0, size.height - len), Offset(0, size.height), Offset(len, size.height)],
      // bottom-right
      [
        Offset(size.width - len, size.height),
        Offset(size.width, size.height),
        Offset(size.width, size.height - len)
      ],
    ];

    for (final pts in corners) {
      final path = Path()
        ..moveTo(pts[0].dx, pts[0].dy)
        ..lineTo(pts[1].dx, pts[1].dy)
        ..lineTo(pts[2].dx, pts[2].dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_CornerBracketsPainter old) => false;
}

// ─── Vera animated ring (for health / probability) ───────────────────────────

class VeraRing extends StatelessWidget {
  final double value;
  final double max;
  final Color color;
  final double size;
  final double strokeWidth;
  final Widget? center;

  const VeraRing({
    super.key,
    required this.value,
    this.max = 100,
    this.color = AppTheme.primaryColor,
    this.size = 80,
    this.strokeWidth = 6,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              value: value,
              max: max,
              color: color,
              strokeWidth: strokeWidth,
            ),
          ),
          if (center != null) center!,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  final double max;
  final Color color;
  final double strokeWidth;

  _RingPainter({
    required this.value,
    required this.max,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi,
      false,
      Paint()
        ..color = color.withValues(alpha: 0.1)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Fill — no blur for minimal look
    final sweepAngle = 2 * math.pi * (value / max);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle.clamp(0, 2 * math.pi),
      false,
      Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color;
}

// ─── Vera segmented control (Iniciar sesión / Crear cuenta) ──────────────────

class VeraSegmented extends StatelessWidget {
  final int active;
  final List<String> items;
  final ValueChanged<int>? onChanged;

  const VeraSegmented({
    super.key,
    required this.active,
    required this.items,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final on = i == active;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged?.call(i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: on ? AppTheme.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Center(
                  child: Text(
                    items[i],
                    style: vMono(
                        size: 11,
                        weight: FontWeight.w600,
                        color: on ? Colors.black : AppTheme.textSecondary,
                        letterSpacing: 0.06),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Vera horizontal divider with label ──────────────────────────────────────

class VeraDivider extends StatelessWidget {
  final String? label;

  const VeraDivider({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    if (label == null) {
      return const Divider(color: AppTheme.borderColor, height: 1);
    }
    return Row(
      children: [
        const Expanded(child: Divider(color: AppTheme.borderColor, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(label!,
              style: vMono(size: 8.5, letterSpacing: 0.2)),
        ),
        const Expanded(child: Divider(color: AppTheme.borderColor, height: 1)),
      ],
    );
  }
}

// ─── Vera satellite metric chip (dashboard corners) ───────────────────────────

class VeraSatellite extends StatelessWidget {
  final String id;
  final String label;
  final String value;
  final String unit;
  final Color? valueColor;

  const VeraSatellite({
    super.key,
    required this.id,
    required this.label,
    required this.value,
    required this.unit,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$id · ${label.toUpperCase()}',
            style: vMono(color: AppTheme.textFaint, size: 8.5, letterSpacing: 0.2)),
        const SizedBox(height: 3),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                  text: value,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: valueColor ?? AppTheme.textPrimary,
                    height: 1,
                  )),
              TextSpan(
                  text: ' $unit',
                  style: vMono(size: 9, color: AppTheme.textFaint)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Vera status banner ───────────────────────────────────────────────────────

class VeraStatusBanner extends StatelessWidget {
  final String label;
  final Color color;
  final String? subtitle;

  const VeraStatusBanner({
    super.key,
    required this.label,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(4),
        color: color.withValues(alpha: 0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subtitle != null)
            Text(subtitle!,
                style: vMono(size: 9, letterSpacing: 0.2)),
          Text(
            label,
            style: vMono(
              size: 11,
              weight: FontWeight.w600,
              color: color,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Vera car silhouette SVG ──────────────────────────────────────────────────

class VeraCarSvg extends StatelessWidget {
  final Color color;
  final double width;

  const VeraCarSvg({
    super.key,
    this.color = AppTheme.textPrimary,
    this.width = 200,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, width * 0.6),
      painter: _CarSvgPainter(color: color),
    );
  }
}

class _CarSvgPainter extends CustomPainter {
  final Color color;
  _CarSvgPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // shadow ellipse
    final shadowPaint = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.88), width: w * 0.8, height: h * 0.1), shadowPaint);

    // body
    final bodyGrad = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFF1A1A1A), const Color(0xFF0A0A0A)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, h * 0.3, w, h * 0.6));

    final bodyPath = Path()
      ..moveTo(w * 0.11, h * 0.78)
      ..quadraticBezierTo(w * 0.11, h * 0.58, w * 0.25, h * 0.54)
      ..lineTo(w * 0.35, h * 0.34)
      ..quadraticBezierTo(w * 0.4, h * 0.27, w * 0.48, h * 0.27)
      ..lineTo(w * 0.67, h * 0.27)
      ..quadraticBezierTo(w * 0.75, h * 0.27, w * 0.8, h * 0.34)
      ..lineTo(w * 0.88, h * 0.54)
      ..quadraticBezierTo(w * 0.93, h * 0.58, w * 0.93, h * 0.78)
      ..close();
    canvas.drawPath(bodyPath, bodyGrad);

    // body stroke
    final strokePaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(bodyPath, strokePaint);

    // windshield
    final glassPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.85);
    final glassPath = Path()
      ..moveTo(w * 0.29, h * 0.56)
      ..lineTo(w * 0.37, h * 0.38)
      ..quadraticBezierTo(w * 0.41, h * 0.32, w * 0.48, h * 0.32)
      ..lineTo(w * 0.66, h * 0.32)
      ..quadraticBezierTo(w * 0.73, h * 0.32, w * 0.77, h * 0.38)
      ..lineTo(w * 0.84, h * 0.56)
      ..close();
    canvas.drawPath(glassPath, glassPaint);
    canvas.drawPath(glassPath,
        Paint()..color = color.withValues(alpha: 0.3)..strokeWidth = 0.8..style = PaintingStyle.stroke);

    // headlight
    final hPaint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.16, h * 0.72), width: w * 0.07, height: h * 0.05), hPaint);

    // wheels
    final wheelPaint = Paint()..color = Colors.black;
    final rimPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final innerPaint = Paint()..color = const Color(0xFF1A1A1A);

    for (final cx in [w * 0.32, w * 0.71]) {
      canvas.drawCircle(Offset(cx, h * 0.84), w * 0.1, wheelPaint);
      canvas.drawCircle(Offset(cx, h * 0.84), w * 0.1, rimPaint);
      canvas.drawCircle(Offset(cx, h * 0.84), w * 0.05, innerPaint);
    }
  }

  @override
  bool shouldRepaint(_CarSvgPainter old) => old.color != color;
}

// ─── Vera timeline node (history) ────────────────────────────────────────────

class VeraTimelineNode extends StatelessWidget {
  final String status; // 'ok' | 'warn' | 'danger'
  final String title;
  final String date;
  final String time;
  final String summary;
  final double prob;
  final bool isFirst;
  final bool isLast;

  const VeraTimelineNode({
    super.key,
    required this.status,
    required this.title,
    required this.date,
    required this.time,
    required this.summary,
    required this.prob,
    this.isFirst = false,
    this.isLast = false,
  });

  Color get _color => status == 'ok'
      ? AppTheme.primaryColor
      : status == 'warn'
          ? AppTheme.warningColor
          : AppTheme.dangerColor;

  String get _short => status == 'ok' ? 'NORMAL' : status == 'warn' ? 'WARN' : 'CRIT';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date label
          SizedBox(
            width: 42,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(date,
                    style: vMono(
                        size: 11,
                        weight: FontWeight.w700,
                        color: isFirst ? AppTheme.primaryColor : AppTheme.textPrimary,
                        letterSpacing: 0.04)),
                Text(time,
                    style: vMono(size: 9, letterSpacing: 0.1)),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Rail + dot
          Column(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _color,
                  boxShadow: [
                    BoxShadow(
                        color: _color.withValues(alpha: 0.5), blurRadius: 10)
                  ],
                ),
                child: Center(
                  child: status == 'ok'
                      ? const Icon(Icons.check_rounded,
                          size: 10, color: Color(0xFF001a08))
                      : Text(
                          status == 'warn' ? '!' : '×',
                          style: TextStyle(
                              color: status == 'warn'
                                  ? const Color(0xFF3a2200)
                                  : const Color(0xFF3a0000),
                              fontSize: 11,
                              fontWeight: FontWeight.w800),
                        ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 1,
                  height: 50,
                  color: AppTheme.borderColor,
                ),
            ],
          ),

          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VeraTag(label: _short, color: _color),
                const SizedBox(height: 6),
                Text(title,
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 3),
                Text(summary,
                    style: vMono(size: 10.5, letterSpacing: 0.06)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('p(anom.)',
                        style: vMono(size: 9, letterSpacing: 0.16)),
                    const Spacer(),
                    Text(
                      '${prob.toStringAsFixed(0)}%',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _color),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
