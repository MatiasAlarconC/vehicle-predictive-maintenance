import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:vehicle_predictive_maintenance_app/app/theme/app_theme.dart';
import 'package:vehicle_predictive_maintenance_app/app/widgets/vera_components.dart';
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
  bool _isCustomMake = false;
  bool _isCustomModel = false;
  String? _pickedImagePath;

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
    _makeCtrl.dispose(); _makeFocus.dispose();
    _modelCtrl.dispose(); _modelFocus.dispose();
    super.dispose();
  }

  bool get _hasSelection => _selectedMake != null && _selectedModel != null;

  void _onMakeChanged(String q) {
    final query = q.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredMakes = [];
        _showMakeList = false;
      } else {
        _filteredMakes = kCarCatalog.where((m) => m.name.toLowerCase().contains(query)).toList();
        _showMakeList = true; // always show when text present (custom option visible)
      }
      if (_selectedMake != null && _selectedMake!.name.toLowerCase() != query) {
        _selectedMake = null;
        _isCustomMake = false;
        _selectedModel = null;
        _isCustomModel = false;
        _modelCtrl.clear();
        _filteredModels = [];
        _showModelList = false;
      }
    });
  }

  void _onModelChanged(String q) {
    final query = q.trim().toLowerCase();
    setState(() {
      if (query.isEmpty || _selectedMake == null) {
        _filteredModels = [];
        _showModelList = false;
      } else {
        _filteredModels = _selectedMake!.models
            .where((m) => m.name.toLowerCase().contains(query)).toList();
        // Show list if matches OR custom make (so user can type a custom model)
        _showModelList = _filteredModels.isNotEmpty || _isCustomMake || true;
      }
      if (_selectedModel != null && _selectedModel!.name.toLowerCase() != query) {
        _selectedModel = null;
        _isCustomModel = false;
      }
    });
  }

  void _selectMake(CarMake make) {
    setState(() {
      _selectedMake = make;
      _makeCtrl.text = make.name;
      _isCustomMake = false;
      _showMakeList = false;
      _filteredMakes = [];
      _selectedModel = null;
      _isCustomModel = false;
      _modelCtrl.clear();
      _filteredModels = [];
      _showModelList = false;
    });
    _makeFocus.unfocus();
  }

  void _selectModel(CarModelEntry model) {
    setState(() {
      _selectedModel = model;
      _modelCtrl.text = model.name;
      _isCustomModel = false;
      _showModelList = false;
      _filteredModels = [];
    });
    _modelFocus.unfocus();
  }

  void _selectCustomMake(String name) {
    if (name.isEmpty) return;
    final synth = CarMake(name: name, models: []);
    setState(() {
      _selectedMake = synth;
      _makeCtrl.text = name;
      _isCustomMake = true;
      _showMakeList = false;
      _filteredMakes = [];
      _selectedModel = null;
      _isCustomModel = false;
      _modelCtrl.clear();
      _filteredModels = [];
      _showModelList = false;
    });
    _makeFocus.unfocus();
  }

  void _selectCustomModel(String name) {
    if (name.isEmpty) return;
    final synth = CarModelEntry(name, CarBodyType.sedan);
    setState(() {
      _selectedModel = synth;
      _modelCtrl.text = name;
      _isCustomModel = true;
      _showModelList = false;
      _filteredModels = [];
    });
    _modelFocus.unfocus();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null || !mounted) return;
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'car_img_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final saved = await File(file.path).copy('${appDir.path}/$fileName');
    if (mounted) setState(() => _pickedImagePath = saved.path);
  }

  Future<void> _confirm() async {
    if (!_hasSelection || _saving) return;
    setState(() => _saving = true);
    try {
      final vehicle = UserVehicle(
        make: _selectedMake!.name,
        model: _selectedModel!.name,
        year: _selectedYear,
        color: _selectedColor,
        bodyType: _selectedModel!.bodyType,
        customImagePath: _pickedImagePath,
      );
      await context.read<VehicleProvider>().setVehicle(vehicle);
      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al guardar: $e', style: vMono(color: Colors.white, size: 12)),
          backgroundColor: AppTheme.dangerColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstName = context.watch<AuthProvider>().firstName;
    final vehicleProvider = context.watch<VehicleProvider>();
    final hasVehicle = vehicleProvider.hasVehicle;
    final step = !_hasSelection ? 0 : 3;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Stack(children: [
          // faint grid bg
          Positioned.fill(child: CustomPaint(painter: _VehicleBgPainter())),
          Column(children: [
            // ── Top bar ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
              decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppTheme.borderColor))),
              child: Row(children: [
                // Back button (only when accessed from dashboard)
                if (hasVehicle) ...[
                  GestureDetector(
                    onTap: () => context.go('/dashboard'),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 14, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(width: 10),
                ],
                const VeraMark(size: 14),
                const SizedBox(width: 8),
                Text('VERA', style: vMono(color: AppTheme.textPrimary, size: 9.5, letterSpacing: 0.18)),
                Text(' · configuración', style: vMono(size: 9.5, letterSpacing: 0.18)),
                const Spacer(),
                Text('stage 04 · vehículo', style: vMono(size: 9.5, letterSpacing: 0.18)),
              ]),
            ),

            Expanded(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // ── Greeting ──────────────────────────────────────────
                    Text(
                      firstName.isNotEmpty ? 'hola, $firstName' : 'hola',
                      style: vMono(color: AppTheme.primaryColor, size: 9.5, letterSpacing: 0.18),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          text: hasVehicle ? 'Tu garage' : '¿Cuál es tu vehículo',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 26, fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary, height: 1.0,
                          ),
                        ),
                        TextSpan(
                          text: hasVehicle ? '_' : '?',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 26, fontWeight: FontWeight.w700,
                            color: AppTheme.primaryColor, height: 1.0,
                          ),
                        ),
                      ]),
                    ),

                    // ── Garage: show existing cars ─────────────────────────
                    if (hasVehicle) ...[
                      const SizedBox(height: 16),
                      ...List.generate(vehicleProvider.garage.length, (i) {
                        final v = vehicleProvider.garage[i];
                        final isActive = i == vehicleProvider.activeIndex;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GestureDetector(
                            onTap: () {
                              vehicleProvider.setActiveVehicle(i);
                              context.go('/dashboard');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isActive ? AppTheme.primaryColor.withValues(alpha: 0.08) : AppTheme.surface,
                                border: Border.all(
                                  color: isActive ? AppTheme.primaryColor : AppTheme.borderColor,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(children: [
                                Container(
                                  width: 8, height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isActive ? AppTheme.primaryColor : AppTheme.borderColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(
                                      '${v.make} ${v.model}',
                                      style: vMono(size: 13, weight: FontWeight.w600, color: AppTheme.textPrimary),
                                    ),
                                    Text(
                                      '${v.year} · ${v.color.label}',
                                      style: vMono(size: 10, color: AppTheme.textFaint),
                                    ),
                                  ]),
                                ),
                                if (isActive)
                                  Text('activo', style: vMono(size: 9.5, color: AppTheme.primaryColor))
                                else
                                  GestureDetector(
                                    onTap: () => vehicleProvider.removeVehicle(i),
                                    child: const Icon(Icons.close_rounded,
                                        size: 16, color: AppTheme.textFaint),
                                  ),
                              ]),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      const VeraDivider(label: 'añadir otro vehículo'),
                    ],

                    const SizedBox(height: 16),

                    // ── Hero car zone ─────────────────────────────────────
                    _VehicleHero(
                      make: _selectedMake?.name,
                      model: _selectedModel?.name,
                      year: _hasSelection ? _selectedYear : null,
                      color: _hasSelection ? _selectedColor : null,
                      customImagePath: _pickedImagePath,
                    ),

                    const SizedBox(height: 16),

                    // ── Config summary (when filled) ──────────────────────
                    if (_hasSelection) ...[
                      VeraFrame(
                        id: 'cfg.vehicle',
                        title: 'parámetros',
                        status: const VeraTag(label: '4/4 ✓'),
                        child: Column(children: [
                          VeraDataLine(k: 'marca', v: _selectedMake!.name),
                          VeraDataLine(k: 'modelo', v: _selectedModel!.name),
                          VeraDataLine(k: 'año', v: '$_selectedYear'),
                          VeraDataLine(k: 'color', v: _selectedColor.label),
                        ]),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // ── Brand frame ───────────────────────────────────────
                    VeraFrame(
                      id: 'brand',
                      title: 'select manufacturer',
                      status: Text('${kCarCatalog.length} marcas', style: vMono(size: 9)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        // Quick chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(children: [
                            for (final brand in kCarCatalog.take(6))
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () => _selectMake(brand),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: _selectedMake?.name == brand.name
                                            ? AppTheme.primaryColor
                                            : AppTheme.borderColor,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                      color: _selectedMake?.name == brand.name
                                          ? AppTheme.primaryColor.withValues(alpha: 0.12)
                                          : Colors.transparent,
                                    ),
                                    child: Text(
                                      brand.name.toUpperCase(),
                                      style: vMono(
                                        size: 10.5,
                                        weight: FontWeight.w600,
                                        color: _selectedMake?.name == brand.name
                                            ? AppTheme.primaryColor
                                            : AppTheme.textSecondary,
                                        letterSpacing: 0.08,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ]),
                        ),
                        const SizedBox(height: 10),
                        // Search field
                        _VeraSearchField(
                          id: 'MAR-01',
                          hint: 'Escribe una marca…',
                          controller: _makeCtrl,
                          focusNode: _makeFocus,
                          onChanged: _onMakeChanged,
                        ),
                        if (_showMakeList && _makeCtrl.text.trim().isNotEmpty) ...
                          [
                            if (_filteredMakes.isNotEmpty)
                              _DropdownList(
                                items: _filteredMakes.map((m) => m.name).toList(),
                                onSelect: (name) => _selectMake(kCarCatalog.firstWhere((m) => m.name == name)),
                              ),
                            if (!kCarCatalog.any((m) => m.name.toLowerCase() == _makeCtrl.text.trim().toLowerCase()))
                              _CustomOptionRow(
                                text: _makeCtrl.text.trim(),
                                label: 'marca',
                                onTap: () => _selectCustomMake(_makeCtrl.text.trim()),
                              ),
                          ],
                      ]),
                    ),

                    const SizedBox(height: 12),

                    // ── Model frame (only when make selected) ─────────────
                    if (_selectedMake != null)
                      VeraFrame(
                        id: 'model',
                        title: 'select model',
                        status: Text('${_selectedMake!.models.length} modelos', style: vMono(size: 9)),
                        child: Column(children: [
                          _VeraSearchField(
                            id: 'MOD-01',
                            hint: 'Buscar modelo…',
                            controller: _modelCtrl,
                            focusNode: _modelFocus,
                            onChanged: _onModelChanged,
                          ),
                          if (_showModelList && _modelCtrl.text.trim().isNotEmpty) ...
                            [
                              if (_filteredModels.isNotEmpty)
                                _DropdownList(
                                  items: _filteredModels.map((m) => m.name).toList(),
                                  onSelect: (name) => _selectModel(
                                    _selectedMake!.models.firstWhere((m) => m.name == name)),
                                ),
                              if (!(_selectedMake?.models ?? []).any((m) => m.name.toLowerCase() == _modelCtrl.text.trim().toLowerCase()))
                                _CustomOptionRow(
                                  text: _modelCtrl.text.trim(),
                                  label: 'modelo',
                                  onTap: () => _selectCustomModel(_modelCtrl.text.trim()),
                                ),
                            ],
                        ]),
                      ),

                    // ── Year slider (when both selected) ─────────────────
                    if (_hasSelection) ...[
                      const SizedBox(height: 12),
                      VeraFrame(
                        id: 'year',
                        title: 'año de fabricación',
                        status: Text(
                          '$_selectedYear',
                          style: vMono(color: AppTheme.primaryColor, size: 13, weight: FontWeight.w700),
                        ),
                        child: _YearTrack(
                          value: _selectedYear,
                          min: 2000,
                          max: DateTime.now().year + 1,
                          onChanged: (v) => setState(() => _selectedYear = v),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Color picker ────────────────────────────────────
                      VeraFrame(
                        id: 'color',
                        title: 'color exterior',
                        status: Text(_selectedColor.label, style: vMono(size: 9)),
                        child: _ColorRow(
                          selected: _selectedColor,
                          onSelect: (c) => setState(() => _selectedColor = c),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Image picker (optional) ─────────────────────────
                      VeraFrame(
                        id: 'image',
                        title: 'imagen del vehículo',
                        status: Text(
                          _pickedImagePath != null ? '✓ personalizada' : 'CDN auto',
                          style: vMono(size: 9, color: _pickedImagePath != null ? AppTheme.primaryColor : AppTheme.textFaint),
                        ),
                        child: Column(children: [
                          if (_pickedImagePath != null) ...[  
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.file(
                                File(_pickedImagePath!),
                                height: 100,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          Row(children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  height: 38,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppTheme.borderColor),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    const Icon(Icons.photo_library_outlined,
                                        color: AppTheme.textSecondary, size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      _pickedImagePath != null ? 'cambiar imagen' : 'seleccionar imagen',
                                      style: vMono(size: 11, color: AppTheme.textSecondary),
                                    ),
                                  ]),
                                ),
                              ),
                            ),
                            if (_pickedImagePath != null) ...[  
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => setState(() => _pickedImagePath = null),
                                child: Container(
                                  height: 38, width: 38,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppTheme.borderColor),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(Icons.close_rounded,
                                      color: AppTheme.textFaint, size: 14),
                                ),
                              ),
                            ],
                          ]),
                        ]),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // ── Confirm button ────────────────────────────────────
                    VeraButton(
                      label: 'CONFIRMAR VEHÍCULO',
                      disabled: !_hasSelection,
                      loading: _saving,
                      onTap: _confirm,
                    ),

                    const SizedBox(height: 16),

                    // ── Step indicator ────────────────────────────────────
                    _ConfigStepper(step: step),
                  ]),
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ─── Vehicle hero with corner brackets & annotations ─────────────────────────

class _VehicleHero extends StatelessWidget {
  final String? make;
  final String? model;
  final int? year;
  final VehicleColor? color;
  final String? customImagePath;

  const _VehicleHero({this.make, this.model, this.year, this.color, this.customImagePath});

  bool get _filled => make != null && model != null;

  @override
  Widget build(BuildContext context) {
    final imgUrl = _filled && year != null && customImagePath == null
        ? CarImageService.buildUrl(make: make!, model: model!, year: year!)
        : null;

    return VeraCornerBrackets(
      color: AppTheme.primaryColor.withValues(alpha: 0.5),
      size: 20,
      child: Container(
        height: 190,
        decoration: BoxDecoration(
          color: AppTheme.surface.withValues(alpha: 0.6),
          border: Border.all(color: AppTheme.borderColor),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Stack(children: [
          // Car image or silhouette
          Center(
            child: _filled
                ? (customImagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.file(
                          File(customImagePath!),
                          height: 140,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const VeraCarSvg(width: 180),
                        ),
                      )
                    : imgUrl != null
                        ? Image.network(
                            imgUrl,
                            height: 140,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) {
                              final fallback = CarImageService.buildBrandFallbackUrl(make: make!, year: year!);
                              if (fallback != null) {
                                return Image.network(
                                  fallback,
                                  height: 140,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const VeraCarSvg(width: 180),
                                );
                              }
                              return const VeraCarSvg(width: 180);
                            },
                          )
                        : const VeraCarSvg(width: 180))
                : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const VeraCarSvg(width: 150),
                    const SizedBox(height: 8),
                    Text('aún sin vehículo',
                        style: vMono(size: 10, letterSpacing: 0.2)),
                  ]),
          ),

          // Annotation markers (when filled)
          if (_filled) ...[
            _Annotation(label: 'marca', value: make!, side: false, y: 20),
            _Annotation(label: 'modelo', value: model!, side: true, y: 20),
            if (year != null)
              _Annotation(label: 'año', value: '$year', side: false, y: 75),
            if (color != null)
              _Annotation(label: 'color', value: color!.label, side: true, y: 75),
          ],

          // HUD labels
          Positioned(
            top: 8, left: 10,
            child: Text(
              _filled ? 'pre-set · ${model ?? ''}' : 'select model',
              style: vMono(size: 8.5, letterSpacing: 0.16),
            ),
          ),
          Positioned(
            bottom: 8, right: 10,
            child: Text(
              'VEH-PVW-${_filled ? '01' : '00'}',
              style: vMono(size: 8.5, letterSpacing: 0.16),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Annotation extends StatelessWidget {
  final String label;
  final String value;
  final bool side; // false=left, true=right
  final double y;

  const _Annotation({required this.label, required this.value, required this.side, required this.y});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: y,
      left: side ? null : 8,
      right: side ? 8 : null,
      child: Column(
        crossAxisAlignment: side ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(children: [
            if (!side) ...[
              Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primaryColor)),
              const SizedBox(width: 4),
            ],
            Text(label, style: vMono(size: 8, letterSpacing: 0.18)),
            if (side) ...[
              const SizedBox(width: 4),
              Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primaryColor)),
            ],
          ]),
          Text(value, style: vMono(size: 11, weight: FontWeight.w700, color: AppTheme.primaryColor, letterSpacing: 0.06)),
        ],
      ),
    );
  }
}

// ─── Search field ─────────────────────────────────────────────────────────────

class _VeraSearchField extends StatelessWidget {
  final String id;
  final String hint;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _VeraSearchField({
    required this.id,
    required this.hint,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      style: vMono(size: 12, weight: FontWeight.w500, color: AppTheme.textPrimary),
      cursorColor: AppTheme.primaryColor,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        hintText: hint,
        hintStyle: vMono(size: 12, color: AppTheme.textFaint),
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 12, right: 8),
          child: Icon(Icons.search_rounded, color: AppTheme.textFaint, size: 16),
        ),
        prefixIconConstraints: const BoxConstraints(),
        suffixIcon: controller.text.isNotEmpty
            ? GestureDetector(
                onTap: () { controller.clear(); onChanged(''); },
                child: const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.close_rounded, color: AppTheme.textFaint, size: 16),
                ),
              )
            : null,
        suffixIconConstraints: const BoxConstraints(),
        filled: true,
        fillColor: AppTheme.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: AppTheme.borderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: AppTheme.borderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: AppTheme.primaryColor)),
      ),
    );
  }
}

// ─── Dropdown list ────────────────────────────────────────────────────────────

class _DropdownList extends StatelessWidget {
  final List<String> items;
  final ValueChanged<String> onSelect;

  const _DropdownList({required this.items, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.borderColor),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => onSelect(items[i]),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Text(items[i],
                style: vMono(size: 12, weight: FontWeight.w500, color: AppTheme.textPrimary)),
          ),
        ),
      ),
    );
  }
}

// ─── Year track slider ────────────────────────────────────────────────────────

class _YearTrack extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _YearTrack({required this.value, required this.min, required this.max, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 3,
          activeTrackColor: AppTheme.primaryColor,
          inactiveTrackColor: AppTheme.borderColor,
          thumbColor: AppTheme.primaryColor,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          overlayColor: AppTheme.primaryColor.withValues(alpha: 0.15),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        ),
        child: Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          onChanged: (v) => onChanged(v.toInt()),
        ),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$min', style: vMono(size: 9)),
          Text('$max', style: vMono(size: 9)),
        ],
      ),
    ]);
  }
}

// ─── Color row ────────────────────────────────────────────────────────────────

class _ColorRow extends StatelessWidget {
  final VehicleColor selected;
  final ValueChanged<VehicleColor> onSelect;

  const _ColorRow({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: VehicleColor.values.map((c) {
        final isSelected = c == selected;
        return GestureDetector(
          onTap: () => onSelect(c),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: c.color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.4), blurRadius: 8)]
                    : null,
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 4),
            Text(
              c.label.substring(0, 3).toUpperCase(),
              style: vMono(size: 8, letterSpacing: 0.08),
            ),
          ]),
        );
      }).toList(),
    );
  }
}

// ─── Step indicator ───────────────────────────────────────────────────────────

class _ConfigStepper extends StatelessWidget {
  final int step;
  const _ConfigStepper({required this.step});

  static const _steps = ['MARCA', 'MODELO', 'AÑO', 'COLOR'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_steps.length, (i) {
        final active = i <= step;
        return Row(children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 16, height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? AppTheme.primaryColor : AppTheme.borderColor,
              ),
              child: Center(
                child: Text(
                  '${i + 1}',
                  style: vMono(size: 8, weight: FontWeight.w700,
                      color: active ? Colors.black : AppTheme.textFaint),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(_steps[i],
                style: vMono(
                    size: 8.5,
                    letterSpacing: 0.1,
                    color: active ? AppTheme.primaryColor : AppTheme.textFaint)),
          ]),
          if (i < _steps.length - 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Container(width: 12, height: 1, color: AppTheme.borderColor),
            ),
        ]);
      }),
    );
  }
}

// ─── Background grid ──────────────────────────────────────────────────────────

class _VehicleBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 0.5;
    const step = 36.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─── Custom option row ───────────────────────────────────────────────────

class _CustomOptionRow extends StatelessWidget {
  final String text;
  final String label;
  final VoidCallback onTap;

  const _CustomOptionRow({
    required this.text,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.06),
          border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(children: [
          const Icon(Icons.add_rounded, color: AppTheme.primaryColor, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: 'Usar "⁨$text⁩" como ',
                  style: vMono(size: 11, color: AppTheme.textSecondary),
                ),
                TextSpan(
                  text: label,
                  style: vMono(size: 11, weight: FontWeight.w700, color: AppTheme.primaryColor),
                ),
                TextSpan(
                  text: ' personalizado',
                  style: vMono(size: 11, color: AppTheme.textSecondary),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
