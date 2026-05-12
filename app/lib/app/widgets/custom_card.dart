import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:vehicle_predictive_maintenance_app/app/theme/app_theme.dart';

/// Tarjeta con efecto glassmorphism y glow sutil estilo dashboard premium.
class CustomCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final List<BoxShadow>? shadows;
  final Gradient? gradient;

  const CustomCard({
    super.key,
    required this.child,
    this.borderColor,
    this.backgroundColor,
    this.padding,
    this.borderRadius = 20,
    this.shadows,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadows ?? AppTheme.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: gradient,
              color: gradient == null
                  ? (backgroundColor ?? AppTheme.surface.withValues(alpha: 0.9))
                  : null,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor ?? AppTheme.borderColor,
                width: 1,
              ),
            ),
            child: Padding(
              padding: padding ?? const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta con borde de color de acento (para estados de alerta)
class AccentCard extends StatelessWidget {
  final Widget child;
  final Color accentColor;
  final EdgeInsetsGeometry? padding;

  const AccentCard({
    super.key,
    required this.child,
    required this.accentColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      borderColor: accentColor.withValues(alpha: 0.4),
      shadows: AppTheme.glowShadow(accentColor, intensity: 0.15),
      padding: padding,
      child: child,
    );
  }
}
