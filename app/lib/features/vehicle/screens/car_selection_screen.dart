import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:vehicle_predictive_maintenance_app/app/theme/app_theme.dart';
import 'package:vehicle_predictive_maintenance_app/core/models/user_vehicle.dart';
import 'package:vehicle_predictive_maintenance_app/core/providers/auth_provider.dart';
import 'package:vehicle_predictive_maintenance_app/core/providers/vehicle_provider.dart';

class CarSelectionScreen extends StatefulWidget {
  const CarSelectionScreen({super.key});

  @override
  State<CarSelectionScreen> createState() => _CarSelectionScreenState();
}

class _CarSelectionScreenState extends State<CarSelectionScreen> {
  int _selectedMakeIdx = 0;
  CarModelEntry? _selectedModel;
  int _selectedYear = DateTime.now().year - 2;
  VehicleColor _selectedColor = VehicleColor.midnightBlack;
  bool _saving = false;

  CarMake get _currentMake => kCarCatalog[_selectedMakeIdx];

  Future<void> _confirm() async {
    if (_selectedModel == null) return;
    setState(() => _saving = true);
    final vehicle = UserVehicle(
      make: _currentMake.name,
      model: _selectedModel!.name,
      year: _selectedYear,
      color: _selectedColor,
      bodyType: _selectedModel!.bodyType,
    );
    await context.read<VehicleProvider>().setVehicle(vehicle);
    if (!mounted) return;
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola, ${auth.firstName}',
                    style: const TextStyle(
                        fontSize: 14, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '¿Cuál es tu\nvehículo?',
                    style: TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Selecciona tu auto para personalizar la experiencia',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Car preview
            _CarPreview(
              color: _selectedColor,
              bodyType: _selectedModel?.bodyType ?? CarBodyType.sedan,
              make: _currentMake.name,
              model: _selectedModel?.name ?? '—',
              year: _selectedYear,
            ),

            const SizedBox(height: 20),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand selection
                    const Text(
                      'MARCA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: kCarCatalog.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (ctx, i) {
                          final selected = i == _selectedMakeIdx;
                          return GestureDetector(
                            onTap: () => setState(() {
                              _selectedMakeIdx = i;
                              _selectedModel = null;
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 0),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppTheme.primaryColor
                                    : AppTheme.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: selected
                                      ? AppTheme.primaryColor
                                      : AppTheme.borderColor,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  kCarCatalog[i].name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: selected
                                        ? Colors.black
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Model selection
                    const Text(
                      'MODELO',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _currentMake.models.map((m) {
                        final selected = _selectedModel?.name == m.name;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedModel = m),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppTheme.primaryColor.withValues(alpha: 0.15)
                                  : AppTheme.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected
                                    ? AppTheme.primaryColor
                                    : AppTheme.borderColor,
                                width: selected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _bodyTypeIcon(m.bodyType),
                                  size: 14,
                                  color: selected
                                      ? AppTheme.primaryColor
                                      : AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  m.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: selected
                                        ? AppTheme.primaryColor
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // Year
                    Row(
                      children: [
                        const Text(
                          'AÑO',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary,
                            letterSpacing: 2,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$_selectedYear',
                          style: const TextStyle(
                            fontFamily: 'Rajdhani',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppTheme.primaryColor,
                        inactiveTrackColor:
                            AppTheme.primaryColor.withValues(alpha: 0.15),
                        thumbColor: AppTheme.primaryColor,
                        overlayColor:
                            AppTheme.primaryColor.withValues(alpha: 0.15),
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 8),
                      ),
                      child: Slider(
                        value: _selectedYear.toDouble(),
                        min: 2000,
                        max: DateTime.now().year.toDouble(),
                        divisions: DateTime.now().year - 2000,
                        onChanged: (v) =>
                            setState(() => _selectedYear = v.round()),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Color
                    const Text(
                      'COLOR',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: VehicleColor.values.map((c) {
                        final selected = _selectedColor == c;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = c),
                          child: Column(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: c.color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selected
                                        ? AppTheme.primaryColor
                                        : Colors.transparent,
                                    width: 2.5,
                                  ),
                                  boxShadow: selected
                                      ? [
                                          BoxShadow(
                                            color: c.color
                                                .withValues(alpha: 0.5),
                                            blurRadius: 10,
                                          )
                                        ]
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                c.label.split(' ').first,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: selected
                                      ? AppTheme.primaryColor
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 32),

                    // Confirm button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: GestureDetector(
                        onTap: _selectedModel == null || _saving ? null : _confirm,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            gradient: _selectedModel != null
                                ? AppTheme.primaryGradient
                                : null,
                            color: _selectedModel == null
                                ? AppTheme.surface
                                : null,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: _selectedModel != null
                                ? AppTheme.glowShadow(AppTheme.primaryColor,
                                    intensity: 0.3)
                                : null,
                          ),
                          child: Center(
                            child: _saving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.black),
                                  )
                                : Text(
                                    'CONFIRMAR VEHÍCULO',
                                    style: TextStyle(
                                      fontFamily: 'Rajdhani',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: _selectedModel != null
                                          ? Colors.black
                                          : AppTheme.textSecondary,
                                      letterSpacing: 2,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _bodyTypeIcon(CarBodyType t) {
    switch (t) {
      case CarBodyType.suv:   return Icons.directions_car_filled_rounded;
      case CarBodyType.coupe: return Icons.speed_rounded;
      case CarBodyType.truck: return Icons.local_shipping_rounded;
      case CarBodyType.sedan: return Icons.directions_car_rounded;
    }
  }
}

class _CarPreview extends StatelessWidget {
  final VehicleColor color;
  final CarBodyType bodyType;
  final String make;
  final String model;
  final int year;

  const _CarPreview({
    required this.color,
    required this.bodyType,
    required this.make,
    required this.model,
    required this.year,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            AppTheme.backgroundSecondary,
            color.color.withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
            color: color.color.withValues(alpha: 0.25)),
      ),
      child: Stack(
        children: [
          // Glow blob behind car
          Positioned(
            right: 30,
            top: 20,
            child: Container(
              width: 120,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  color.color.withValues(alpha: 0.25),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          // Car silhouette
          Positioned(
            right: 16,
            top: 20,
            child: SizedBox(
              width: 180,
              height: 100,
              child: CustomPaint(
                painter: _CarSilhouettePainter(
                  bodyColor: color.color,
                  bodyType: bodyType,
                ),
              ),
            ),
          ),
          // Car info
          Positioned(
            left: 20,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  make.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                    letterSpacing: 3,
                  ),
                ),
                Text(
                  model,
                  style: const TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    height: 1,
                  ),
                ),
                Text(
                  '$year',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CarSilhouettePainter extends CustomPainter {
  final Color bodyColor;
  final CarBodyType bodyType;

  const _CarSilhouettePainter(
      {required this.bodyColor, required this.bodyType});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Ground glow
    final glowPaint = Paint()
      ..color = bodyColor.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawOval(
        Rect.fromLTWH(w * 0.1, h * 0.82, w * 0.8, h * 0.14), glowPaint);

    final bodyPaint = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.fill;

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    if (bodyType == CarBodyType.suv) {
      _drawSuv(canvas, w, h, bodyPaint, highlightPaint);
    } else if (bodyType == CarBodyType.coupe) {
      _drawCoupe(canvas, w, h, bodyPaint, highlightPaint);
    } else if (bodyType == CarBodyType.truck) {
      _drawTruck(canvas, w, h, bodyPaint, highlightPaint);
    } else {
      _drawSedan(canvas, w, h, bodyPaint, highlightPaint);
    }
  }

  void _drawSedan(Canvas canvas, double w, double h, Paint body, Paint hi) {
    // Body
    final path = Path()
      ..moveTo(w * 0.05, h * 0.72)
      ..lineTo(w * 0.05, h * 0.60)
      ..lineTo(w * 0.12, h * 0.56)
      ..cubicTo(w * 0.20, h * 0.54, w * 0.26, h * 0.34, w * 0.34, h * 0.28)
      ..cubicTo(w * 0.45, h * 0.22, w * 0.60, h * 0.22, w * 0.68, h * 0.28)
      ..cubicTo(w * 0.76, h * 0.34, w * 0.82, h * 0.52, w * 0.86, h * 0.56)
      ..lineTo(w * 0.95, h * 0.60)
      ..lineTo(w * 0.95, h * 0.72)
      ..close();
    canvas.drawPath(path, body);

    // Windshield highlight
    final windshield = Path()
      ..moveTo(w * 0.27, h * 0.38)
      ..cubicTo(w * 0.30, h * 0.30, w * 0.38, h * 0.26, w * 0.46, h * 0.26)
      ..lineTo(w * 0.46, h * 0.44)
      ..cubicTo(w * 0.38, h * 0.44, w * 0.30, h * 0.42, w * 0.27, h * 0.38)
      ..close();
    canvas.drawPath(windshield, hi);

    _drawWheels(canvas, w, h, w * 0.22, w * 0.75);
  }

  void _drawSuv(Canvas canvas, double w, double h, Paint body, Paint hi) {
    final path = Path()
      ..moveTo(w * 0.04, h * 0.74)
      ..lineTo(w * 0.04, h * 0.58)
      ..lineTo(w * 0.10, h * 0.54)
      ..lineTo(w * 0.16, h * 0.28)
      ..lineTo(w * 0.84, h * 0.28)
      ..lineTo(w * 0.90, h * 0.54)
      ..lineTo(w * 0.96, h * 0.58)
      ..lineTo(w * 0.96, h * 0.74)
      ..close();
    canvas.drawPath(path, body);

    final windshield = Path()
      ..moveTo(w * 0.18, h * 0.52)
      ..lineTo(w * 0.23, h * 0.32)
      ..lineTo(w * 0.44, h * 0.32)
      ..lineTo(w * 0.44, h * 0.52)
      ..close();
    canvas.drawPath(windshield, hi);

    _drawWheels(canvas, w, h, w * 0.22, w * 0.76);
  }

  void _drawCoupe(Canvas canvas, double w, double h, Paint body, Paint hi) {
    final path = Path()
      ..moveTo(w * 0.04, h * 0.72)
      ..lineTo(w * 0.04, h * 0.62)
      ..lineTo(w * 0.14, h * 0.58)
      ..cubicTo(w * 0.22, h * 0.56, w * 0.28, h * 0.28, w * 0.38, h * 0.24)
      ..cubicTo(w * 0.52, h * 0.20, w * 0.66, h * 0.22, w * 0.72, h * 0.28)
      ..cubicTo(w * 0.82, h * 0.40, w * 0.88, h * 0.54, w * 0.90, h * 0.58)
      ..lineTo(w * 0.96, h * 0.62)
      ..lineTo(w * 0.96, h * 0.72)
      ..close();
    canvas.drawPath(path, body);

    final windshield = Path()
      ..moveTo(w * 0.29, h * 0.42)
      ..cubicTo(w * 0.32, h * 0.30, w * 0.40, h * 0.26, w * 0.50, h * 0.26)
      ..lineTo(w * 0.50, h * 0.44)
      ..close();
    canvas.drawPath(windshield, hi);

    _drawWheels(canvas, w, h, w * 0.22, w * 0.76);
  }

  void _drawTruck(Canvas canvas, double w, double h, Paint body, Paint hi) {
    // Cab
    final cab = Path()
      ..moveTo(w * 0.04, h * 0.74)
      ..lineTo(w * 0.04, h * 0.56)
      ..lineTo(w * 0.12, h * 0.52)
      ..lineTo(w * 0.14, h * 0.28)
      ..lineTo(w * 0.50, h * 0.28)
      ..lineTo(w * 0.52, h * 0.52)
      ..lineTo(w * 0.52, h * 0.74)
      ..close();
    canvas.drawPath(cab, body);

    // Bed
    final bed = Path()
      ..moveTo(w * 0.52, h * 0.56)
      ..lineTo(w * 0.96, h * 0.56)
      ..lineTo(w * 0.96, h * 0.74)
      ..lineTo(w * 0.52, h * 0.74)
      ..close();
    canvas.drawPath(bed, body);

    final windshield = Path()
      ..moveTo(w * 0.15, h * 0.50)
      ..lineTo(w * 0.17, h * 0.32)
      ..lineTo(w * 0.46, h * 0.32)
      ..lineTo(w * 0.46, h * 0.50)
      ..close();
    canvas.drawPath(windshield, hi);

    _drawWheels(canvas, w, h, w * 0.22, w * 0.78);
  }

  void _drawWheels(Canvas canvas, double w, double h, double x1, double x2) {
    final wheelPaint = Paint()
      ..color = const Color(0xFF1A1A2E)
      ..style = PaintingStyle.fill;
    final rimPaint = Paint()
      ..color = Colors.grey.shade500
      ..style = PaintingStyle.fill;
    final tireR = w * 0.10;
    final rimR = w * 0.055;
    for (final x in [x1, x2]) {
      canvas.drawCircle(Offset(x, h * 0.76), tireR, wheelPaint);
      canvas.drawCircle(Offset(x, h * 0.76), rimR, rimPaint);
      canvas.drawCircle(Offset(x, h * 0.76), rimR * 0.35,
          Paint()..color = const Color(0xFF1A1A2E));
    }
  }

  @override
  bool shouldRepaint(_CarSilhouettePainter old) =>
      old.bodyColor != bodyColor || old.bodyType != bodyType;
}
