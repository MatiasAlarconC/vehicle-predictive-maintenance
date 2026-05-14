import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:vehicle_predictive_maintenance_app/app/theme/app_theme.dart';
import 'package:vehicle_predictive_maintenance_app/core/models/user_vehicle.dart';
import 'package:vehicle_predictive_maintenance_app/core/providers/auth_provider.dart';
import 'package:vehicle_predictive_maintenance_app/core/providers/vehicle_provider.dart';
import 'package:vehicle_predictive_maintenance_app/services/car_image_service.dart';

class CarSelectionScreen extends StatefulWidget {
  const CarSelectionScreen({super.key});

  @override
  State<CarSelectionScreen> createState() => _CarSelectionScreenState();
}

class _CarSelectionScreenState extends State<CarSelectionScreen> {
  CarMake? _selectedMake;
  CarModelEntry? _selectedModel;
  int _selectedYear = DateTime.now().year - 2;
  VehicleColor _selectedColor = VehicleColor.midnightBlack;
  bool _saving = false;

  final _makeCtrl = TextEditingController();
  final _makeFocus = FocusNode();
  bool _showMakeList = false;
  List<CarMake> _filteredMakes = [];

  final _modelCtrl = TextEditingController();
  final _modelFocus = FocusNode();
  bool _showModelList = false;
  List<CarModelEntry> _filteredModels = [];

  @override
  void initState() {
    super.initState();
    _makeFocus.addListener(() {
      if (!_makeFocus.hasFocus && mounted) {
        Future.delayed(const Duration(milliseconds: 150),
            () { if (mounted) setState(() => _showMakeList = false); });
      }
    });
    _modelFocus.addListener(() {
      if (!_modelFocus.hasFocus && mounted) {
        Future.delayed(const Duration(milliseconds: 150),
            () { if (mounted) setState(() => _showModelList = false); });
      }
    });
  }

  @override
  void dispose() {
    _makeCtrl.dispose();
    _makeFocus.dispose();
    _modelCtrl.dispose();
    _modelFocus.dispose();
    super.dispose();
  }

  void _onMakeChanged(String q) {
    final query = q.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredMakes = [];
        _showMakeList = false;
      } else {
        _filteredMakes = kCarCatalog
            .where((m) => m.name.toLowerCase().contains(query))
            .toList();
        _showMakeList = true;
      }
      if (_selectedMake != null &&
          _selectedMake!.name.toLowerCase() != query) {
        _selectedMake = null;
        _selectedModel = null;
        _modelCtrl.clear();
        _filteredModels = [];
        _showModelList = false;
      }
    });
  }

  void _selectMake(CarMake make) {
    setState(() {
      _selectedMake = make;
      _selectedModel = null;
      _makeCtrl.text = make.name;
      _filteredMakes = [];
      _showMakeList = false;
      _modelCtrl.clear();
      _filteredModels = [];
      _showModelList = false;
    });
    _makeFocus.unfocus();
  }

  void _onModelChanged(String q) {
    if (_selectedMake == null) return;
    final query = q.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredModels = [];
        _showModelList = false;
      } else {
        _filteredModels = _selectedMake!.models
            .where((m) => m.name.toLowerCase().contains(query))
            .toList();
        _showModelList = true;
      }
      if (_selectedModel != null &&
          _selectedModel!.name.toLowerCase() != query) {
        _selectedModel = null;
      }
    });
  }

  void _selectModel(CarModelEntry model) {
    setState(() {
      _selectedModel = model;
      _modelCtrl.text = model.name;
      _filteredModels = [];
      _showModelList = false;
    });
    _modelFocus.unfocus();
  }

  Future<void> _confirm() async {
    if (_selectedMake == null || _selectedModel == null) return;
    setState(() => _saving = true);
    final vehicle = UserVehicle(
      make: _selectedMake!.name,
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
    final firstName = context.read<AuthProvider>().firstName;
    final hasSelection = _selectedMake != null && _selectedModel != null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hola, $firstName',
                      style: const TextStyle(
                          fontSize: 14, color: AppTheme.textSecondary)),
                  const SizedBox(height: 4),
                  const Text('¿Cuál es tu\nvehículo?',
                      style: TextStyle(
                        fontFamily: 'Rajdhani',
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        height: 1.1,
                      )),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _CarPreview(
              color: _selectedColor,
              bodyType: _selectedModel?.bodyType ?? CarBodyType.sedan,
              make: _selectedMake?.name ?? '—',
              model: _selectedModel?.name ?? '—',
              year: _selectedYear,
              hasSelection: hasSelection,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel('MARCA'),
                    const SizedBox(height: 8),
                    _SearchField(
                      controller: _makeCtrl,
                      focusNode: _makeFocus,
                      hint: 'Escribe una marca (ej: Toyota, BMW...)',
                      onChanged: _onMakeChanged,
                      onClear: () {
                        _makeCtrl.clear();
                        _onMakeChanged('');
                        setState(() {
                          _selectedMake = null;
                          _selectedModel = null;
                          _modelCtrl.clear();
                        });
                      },
                    ),
                    if (_showMakeList && _filteredMakes.isNotEmpty)
                      _DropdownList(
                        items: _filteredMakes.map((m) => m.name).toList(),
                        onSelect: (name) => _selectMake(
                            kCarCatalog.firstWhere((m) => m.name == name)),
                      ),
                    if (_showMakeList && _filteredMakes.isEmpty)
                      _EmptyList('No se encontró ninguna marca'),

                    if (_selectedMake != null) ...[
                      const SizedBox(height: 20),
                      _SectionLabel('MODELO'),
                      const SizedBox(height: 8),
                      _SearchField(
                        controller: _modelCtrl,
                        focusNode: _modelFocus,
                        hint: 'Escribe un modelo (ej: Corolla, X5...)',
                        onChanged: _onModelChanged,
                        onClear: () {
                          _modelCtrl.clear();
                          _onModelChanged('');
                          setState(() => _selectedModel = null);
                        },
                      ),
                      if (_showModelList && _filteredModels.isNotEmpty)
                        _DropdownList(
                          items: _filteredModels.map((m) => m.name).toList(),
                          onSelect: (name) => _selectModel(
                              _selectedMake!.models
                                  .firstWhere((m) => m.name == name)),
                        ),
                      if (_showModelList && _filteredModels.isEmpty)
                        _EmptyList('No se encontró ese modelo'),
                    ],

                    if (hasSelection) ...[
                      const SizedBox(height: 20),
                      Row(children: [
                        _SectionLabel('AÑO'),
                        const Spacer(),
                        Text('$_selectedYear',
                            style: const TextStyle(
                              fontFamily: 'Rajdhani',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryColor,
                            )),
                      ]),
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
                      _SectionLabel('COLOR'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: VehicleColor.values.map((c) {
                          final sel = _selectedColor == c;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedColor = c),
                            child: Column(children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: c.color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: sel
                                        ? AppTheme.primaryColor
                                        : Colors.transparent,
                                    width: 2.5,
                                  ),
                                  boxShadow: sel
                                      ? [BoxShadow(
                                          color: c.color.withValues(alpha: 0.5),
                                          blurRadius: 10)]
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(c.label.split(' ').first,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: sel
                                        ? AppTheme.primaryColor
                                        : AppTheme.textSecondary,
                                  )),
                            ]),
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: GestureDetector(
                        onTap: !hasSelection || _saving ? null : _confirm,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            gradient: hasSelection
                                ? AppTheme.primaryGradient
                                : null,
                            color: !hasSelection ? AppTheme.surface : null,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: hasSelection
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
                                        color: Colors.black))
                                : Text('CONFIRMAR VEHÍCULO',
                                    style: TextStyle(
                                      fontFamily: 'Rajdhani',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: hasSelection
                                          ? Colors.black
                                          : AppTheme.textSecondary,
                                      letterSpacing: 2,
                                    )),
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
}

// ── Componentes ────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppTheme.textSecondary,
        letterSpacing: 2,
      ));
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        prefixIcon: const Icon(Icons.search_rounded,
            color: AppTheme.textSecondary, size: 20),
        suffixIcon: controller.text.isNotEmpty
            ? GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close_rounded,
                    color: AppTheme.textSecondary, size: 18))
            : null,
        filled: true,
        fillColor: AppTheme.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.borderColor)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.borderColor)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppTheme.primaryColor, width: 1.5)),
      ),
    );
  }
}

class _DropdownList extends StatelessWidget {
  final List<String> items;
  final ValueChanged<String> onSelect;

  const _DropdownList({required this.items, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: items.length,
        itemBuilder: (_, i) {
          final isLast = i == items.length - 1;
          return GestureDetector(
            onTap: () => onSelect(items[i]),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : const Border(
                        bottom: BorderSide(
                            color: AppTheme.borderColor, width: 0.5)),
              ),
              child: Text(items[i],
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  )),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyList extends StatelessWidget {
  final String message;
  const _EmptyList(this.message);
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 4),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Text(message,
            style: const TextStyle(
                fontSize: 13, color: AppTheme.textSecondary)),
      );
}

// ── Car Preview ────────────────────────────────────────────────────────────────

class _CarPreview extends StatelessWidget {
  final VehicleColor color;
  final CarBodyType bodyType;
  final String make;
  final String model;
  final int year;
  final bool hasSelection;

  const _CarPreview({
    required this.color,
    required this.bodyType,
    required this.make,
    required this.model,
    required this.year,
    required this.hasSelection,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = hasSelection
        ? CarImageService.buildUrl(make: make, model: model, year: year)
        : null;

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
        border: Border.all(color: color.color.withValues(alpha: 0.25)),
      ),
      child: Stack(children: [
        if (imageUrl != null)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 210,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(right: Radius.circular(20)),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _FallbackCar(color: color.color, bodyType: bodyType),
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: AppTheme.primaryColor),
                    ),
                  );
                },
              ),
            ),
          )
        else
          Positioned(
            right: 16,
            top: 20,
            child: _FallbackCar(color: color.color, bodyType: bodyType),
          ),
        Positioned(
          left: 20,
          bottom: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasSelection ? make.toUpperCase() : 'SELECCIONA',
                style: const TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  letterSpacing: 3,
                ),
              ),
              Text(
                hasSelection ? model : 'tu auto',
                style: const TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  height: 1,
                ),
              ),
              if (hasSelection)
                Text('$year',
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary)),
            ],
          ),
        ),
      ]),
    );
  }
}

class _FallbackCar extends StatelessWidget {
  final Color color;
  final CarBodyType bodyType;
  const _FallbackCar({required this.color, required this.bodyType});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 180,
        height: 100,
        child: CustomPaint(
            painter: _CarSilhouettePainter(
                bodyColor: color, bodyType: bodyType)),
      );
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
    final glow = Paint()
      ..color = bodyColor.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawOval(
        Rect.fromLTWH(w * 0.1, h * 0.82, w * 0.8, h * 0.14), glow);
    final body = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.fill;
    final hi = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    switch (bodyType) {
      case CarBodyType.suv:
        _drawSuv(canvas, w, h, body, hi);
      case CarBodyType.coupe:
        _drawCoupe(canvas, w, h, body, hi);
      case CarBodyType.truck:
        _drawTruck(canvas, w, h, body, hi);
      case CarBodyType.sedan:
        _drawSedan(canvas, w, h, body, hi);
    }
  }

  void _drawSedan(Canvas canvas, double w, double h, Paint b, Paint hi) {
    canvas.drawPath(
        Path()
          ..moveTo(w * 0.05, h * 0.72)
          ..lineTo(w * 0.05, h * 0.60)
          ..lineTo(w * 0.12, h * 0.56)
          ..cubicTo(
              w * 0.20, h * 0.54, w * 0.26, h * 0.34, w * 0.34, h * 0.28)
          ..cubicTo(
              w * 0.45, h * 0.22, w * 0.60, h * 0.22, w * 0.68, h * 0.28)
          ..cubicTo(
              w * 0.76, h * 0.34, w * 0.82, h * 0.52, w * 0.86, h * 0.56)
          ..lineTo(w * 0.95, h * 0.60)
          ..lineTo(w * 0.95, h * 0.72)
          ..close(),
        b);
    canvas.drawPath(
        Path()
          ..moveTo(w * 0.27, h * 0.38)
          ..cubicTo(
              w * 0.30, h * 0.30, w * 0.38, h * 0.26, w * 0.46, h * 0.26)
          ..lineTo(w * 0.46, h * 0.44)
          ..cubicTo(
              w * 0.38, h * 0.44, w * 0.30, h * 0.42, w * 0.27, h * 0.38)
          ..close(),
        hi);
    _wheels(canvas, w, h, w * 0.22, w * 0.75);
  }

  void _drawSuv(Canvas canvas, double w, double h, Paint b, Paint hi) {
    canvas.drawPath(
        Path()
          ..moveTo(w * 0.04, h * 0.74)
          ..lineTo(w * 0.04, h * 0.58)
          ..lineTo(w * 0.10, h * 0.54)
          ..lineTo(w * 0.16, h * 0.28)
          ..lineTo(w * 0.84, h * 0.28)
          ..lineTo(w * 0.90, h * 0.54)
          ..lineTo(w * 0.96, h * 0.58)
          ..lineTo(w * 0.96, h * 0.74)
          ..close(),
        b);
    canvas.drawPath(
        Path()
          ..moveTo(w * 0.18, h * 0.50)
          ..lineTo(w * 0.20, h * 0.32)
          ..lineTo(w * 0.46, h * 0.32)
          ..lineTo(w * 0.46, h * 0.50)
          ..close(),
        hi);
    _wheels(canvas, w, h, w * 0.22, w * 0.76);
  }

  void _drawCoupe(Canvas canvas, double w, double h, Paint b, Paint hi) {
    canvas.drawPath(
        Path()
          ..moveTo(w * 0.05, h * 0.74)
          ..lineTo(w * 0.05, h * 0.62)
          ..lineTo(w * 0.14, h * 0.58)
          ..cubicTo(
              w * 0.22, h * 0.54, w * 0.30, h * 0.26, w * 0.42, h * 0.22)
          ..cubicTo(
              w * 0.58, h * 0.18, w * 0.72, h * 0.22, w * 0.78, h * 0.30)
          ..cubicTo(
              w * 0.84, h * 0.40, w * 0.88, h * 0.54, w * 0.92, h * 0.58)
          ..lineTo(w * 0.95, h * 0.62)
          ..lineTo(w * 0.95, h * 0.74)
          ..close(),
        b);
    canvas.drawPath(
        Path()
          ..moveTo(w * 0.28, h * 0.42)
          ..cubicTo(
              w * 0.32, h * 0.28, w * 0.42, h * 0.26, w * 0.50, h * 0.26)
          ..lineTo(w * 0.48, h * 0.46)
          ..close(),
        hi);
    _wheels(canvas, w, h, w * 0.20, w * 0.76);
  }

  void _drawTruck(Canvas canvas, double w, double h, Paint b, Paint hi) {
    canvas.drawPath(
        Path()
          ..moveTo(w * 0.04, h * 0.74)
          ..lineTo(w * 0.04, h * 0.50)
          ..lineTo(w * 0.10, h * 0.46)
          ..lineTo(w * 0.14, h * 0.26)
          ..lineTo(w * 0.50, h * 0.26)
          ..lineTo(w * 0.54, h * 0.46)
          ..lineTo(w * 0.54, h * 0.74)
          ..close(),
        b);
    canvas.drawRRect(
        RRect.fromRectAndCorners(
            Rect.fromLTWH(w * 0.54, h * 0.40, w * 0.42, h * 0.34),
            topRight: const Radius.circular(4),
            bottomRight: const Radius.circular(4)),
        b);
    canvas.drawPath(
        Path()
          ..moveTo(w * 0.15, h * 0.44)
          ..lineTo(w * 0.17, h * 0.30)
          ..lineTo(w * 0.46, h * 0.30)
          ..lineTo(w * 0.48, h * 0.44)
          ..close(),
        hi);
    _wheels(canvas, w, h, w * 0.20, w * 0.72);
  }

  void _wheels(Canvas canvas, double w, double h, double x1, double x2) {
    final wPaint = Paint()
      ..color = const Color(0xFF212121)
      ..style = PaintingStyle.fill;
    final rPaint = Paint()
      ..color = const Color(0xFF9E9E9E)
      ..style = PaintingStyle.fill;
    for (final x in [x1, x2]) {
      canvas.drawCircle(Offset(x, h * 0.76), h * 0.16, wPaint);
      canvas.drawCircle(Offset(x, h * 0.76), h * 0.08, rPaint);
    }
  }

  @override
  bool shouldRepaint(_CarSilhouettePainter old) =>
      old.bodyColor != bodyColor || old.bodyType != bodyType;
}
