import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:vehicle_predictive_maintenance_app/app/theme/app_theme.dart';
import 'package:vehicle_predictive_maintenance_app/app/widgets/vera_components.dart';
import 'package:vehicle_predictive_maintenance_app/core/providers/auth_provider.dart';
import 'package:vehicle_predictive_maintenance_app/core/providers/diagnostics_provider.dart';
import 'package:vehicle_predictive_maintenance_app/core/providers/vehicle_provider.dart';
import 'package:vehicle_predictive_maintenance_app/features/dashboard/widgets/main_chart.dart';
import 'package:vehicle_predictive_maintenance_app/services/car_image_service.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final diagnostics = context.watch<DiagnosticsProvider>();
    final vehicle = context.watch<VehicleProvider>().vehicle;
    final firstName = context.watch<AuthProvider>().firstName;
    final reading = diagnostics.latestReading;
    final health = diagnostics.vehicleHealth;

    final rpm    = reading?.rpm         ?? 900;
    final temp   = reading?.engineTemp  ?? 88.0;
    final voltage = reading?.voltage    ?? 12.7;
    final speed  = reading?.speed       ?? 0;

    final statusLabel = health >= 85 ? 'TODO BIEN'
        : health >= 60 ? 'REVISAR PRONTO'
        : 'ATENCIÓN';
    final statusColor = health >= 85 ? AppTheme.successColor
        : health >= 60 ? AppTheme.warningColor
        : AppTheme.dangerColor;

    return SafeArea(
      child: Column(children: [
      // ── Top utility bar ──────────────────────────────────────────────
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppTheme.borderColor))),
        child: Row(children: [
          const VeraMark(size: 14),
          const SizedBox(width: 8),
          Text('VERA', style: vMono(color: AppTheme.textPrimary, size: 9.5, letterSpacing: 0.18)),
          Text(' · cockpit', style: vMono(size: 9.5, color: AppTheme.textFaint, letterSpacing: 0.18)),
          const Spacer(),
          const VeraLiveDot(),
          const SizedBox(width: 5),
          Text('live', style: vMono(size: 9.5, letterSpacing: 0.18)),
          Text('  ·  ', style: vMono(size: 9.5, color: AppTheme.textFaint)),
          GestureDetector(
            onTap: () => context.go('/select-vehicle'),
            child: const Icon(Icons.garage_outlined, size: 18, color: AppTheme.textFaint),
          ),
        ]),
      ),

      Expanded(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Hero: greeting + large health ring ─────────────────────
            _HeroSection(
              health: health,
              rpm: rpm,
              temp: temp,
              speed: speed,
              voltage: voltage,
              firstName: firstName.isNotEmpty ? firstName : null,
              vehicleName: vehicle != null ? '${vehicle.make} ${vehicle.model}' : null,
              carMake: vehicle?.make,
              carModel: vehicle?.model,
              carYear: vehicle?.year,              customImagePath: vehicle?.customImagePath,              statusLabel: statusLabel,
              statusColor: statusColor,
            ),

            // ── CTA button ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: _AnalyzeButton(onTap: () => context.go('/predict')),
            ),

            // ── Temperature chart ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Temperatura', style: GoogleFonts.spaceGrotesk(
                    fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                Text('en tiempo real', style: vMono(size: 9, color: AppTheme.textFaint, letterSpacing: 0.1)),
                const SizedBox(height: 14),
                MainChart(readings: diagnostics.readings),
              ]),
            ),
          ]),
        ),
      ),
    ]),
    );
  }
}

// ─── Hero section: greeting + health ring + metric tiles ─────────────────────

class _HeroSection extends StatelessWidget {
  final double health, rpm, temp, speed, voltage;
  final String? firstName;
  final String? vehicleName;
  final String? carMake;
  final String? carModel;
  final int? carYear;
  final String? customImagePath;
  final String statusLabel;
  final Color statusColor;

  const _HeroSection({
    required this.health,
    required this.rpm,
    required this.temp,
    required this.speed,
    required this.voltage,
    this.firstName,
    this.vehicleName,
    this.carMake,
    this.carModel,
    this.carYear,
    this.customImagePath,
    required this.statusLabel,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Greeting
        if (firstName != null) ...[
          Text(
            firstName!,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 30, fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary, height: 1,
            ),
          ),
          Text(
            vehicleName ?? 'Buenos días',
            style: vMono(size: 10, color: AppTheme.textFaint, letterSpacing: 0.1),
          ),
          const SizedBox(height: 20),
        ] else
          const SizedBox(height: 8),

        // Car image panel
        if (carMake != null && carModel != null)
          _CarImagePanel(
            make: carMake!,
            model: carModel!,
            year: carYear ?? DateTime.now().year - 2,
            vehicleName: vehicleName,
            customImagePath: customImagePath,
          ),

        const SizedBox(height: 20),
        Center(
          child: Column(children: [
            VeraRing(
              value: health,
              max: 100,
              color: statusColor,
              size: 148,
              strokeWidth: 6,
              center: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  '${health.toInt()}',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 46, fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary, height: 1,
                  ),
                ),
                Text('salud',
                    style: vMono(size: 8, color: AppTheme.textFaint, letterSpacing: 0.2)),
              ]),
            ),
            const SizedBox(height: 14),
            // Status row below ring (like "91 Calls · 86.3% Done · 179 SMS" in Notivo)
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 5, height: 5,
                decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
              ),
              const SizedBox(width: 6),
              Text(
                statusLabel,
                style: vMono(size: 10, color: statusColor, weight: FontWeight.w600, letterSpacing: 0.15),
              ),
              if (vehicleName != null && firstName != null) ...[
                Text('  ·  ', style: vMono(size: 10, color: AppTheme.textFaint)),
                Text(vehicleName!, style: vMono(size: 10, color: AppTheme.textFaint)),
              ],
            ]),
          ]),
        ),

        const SizedBox(height: 28),

        // 2×2 metric grid — smart home style tiles
        Row(children: [
          Expanded(child: VeraMetricTile(
            label: 'RPM',
            value: rpm.toInt().toString(),
          )),
          const SizedBox(width: 8),
          Expanded(child: VeraMetricTile(
            label: 'Velocidad',
            value: speed.toInt().toString(),
            unit: 'km/h',
          )),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: VeraMetricTile(
            label: 'Temperatura',
            value: '${temp.toInt()}°',
            valueColor: temp > 100 ? AppTheme.dangerColor : null,
          )),
          const SizedBox(width: 8),
          Expanded(child: VeraMetricTile(
            label: 'Batería',
            value: voltage.toStringAsFixed(1),
            unit: 'V',
          )),
        ]),
      ]),
    );
  }
}

// ─── Analyze CTA button ───────────────────────────────────────────────────────

class _AnalyzeButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AnalyzeButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white, width: 1),
        ),
        child: Center(
          child: Text('ANALIZAR',
              style: vMono(size: 13, weight: FontWeight.w700, color: Colors.white, letterSpacing: 0.12)),
        ),
      ),
    );
  }
}

// ─── Car image panel ──────────────────────────────────────────────────────────

class _CarImagePanel extends StatelessWidget {
  final String make, model;
  final int year;
  final String? vehicleName;
  final String? customImagePath;

  const _CarImagePanel({
    required this.make,
    required this.model,
    required this.year,
    this.vehicleName,
    this.customImagePath,
  });

  @override
  Widget build(BuildContext context) {
    final url = customImagePath == null
        ? CarImageService.buildUrl(make: make, model: model, year: year)
        : null;
    return Container(
      margin: const EdgeInsets.only(top: 4),
      height: 170,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(children: [
          // Car image fills the container
          Positioned.fill(
            child: customImagePath != null
                ? Image.file(
                    File(customImagePath!),
                    fit: BoxFit.cover,
                    alignment: const Alignment(0.0, 0.6),
                    errorBuilder: (_, __, ___) => _brandFallback(),
                  )
                : Image.network(
                    url!,
                    fit: BoxFit.cover,
                    alignment: const Alignment(0.0, 0.6),
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return Center(
                        child: SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5, color: AppTheme.textFaint,
                            value: progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) {
                      final fallback = CarImageService.buildBrandFallbackUrl(make: make, year: year);
                      if (fallback != null && fallback != url) {
                        return Image.network(
                          fallback,
                          fit: BoxFit.cover,
                          alignment: const Alignment(0.0, 0.6),
                          errorBuilder: (_, __, ___) => _brandFallback(),
                        );
                      }
                      return _brandFallback();
                    },
                  ),
          ),
          // Top gradient overlay for label readability
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.surface.withValues(alpha: 0.95),
                    AppTheme.surface.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          // Bottom gradient overlay
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppTheme.background.withValues(alpha: 0.9),
                    AppTheme.background.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          // Top-left label
          Positioned(
            top: 10, left: 14,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                '${make.toUpperCase()} $model'.toUpperCase(),
                style: vMono(size: 10.5, weight: FontWeight.w700,
                    color: AppTheme.textPrimary, letterSpacing: 0.12),
              ),
              Text(
                '$year · en garaje',
                style: vMono(size: 9, color: AppTheme.textFaint, letterSpacing: 0.1),
              ),
            ]),
          ),
          // Bottom-right corner badge
          Positioned(
            bottom: 8, right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.12),
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.4)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'ACTIVO',
                style: vMono(size: 8.5, color: AppTheme.primaryColor,
                    weight: FontWeight.w600, letterSpacing: 0.1),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _brandFallback() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.directions_car_outlined,
          color: AppTheme.textFaint, size: 36),
      const SizedBox(height: 6),
      Text('$make $model',
          style: vMono(size: 9, color: AppTheme.textFaint, letterSpacing: 0.1)),
    ]),
  );
}
