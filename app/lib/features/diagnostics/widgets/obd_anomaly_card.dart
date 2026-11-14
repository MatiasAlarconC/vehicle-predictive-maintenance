import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vehicle_predictive_maintenance_app/app/theme/app_theme.dart';
import 'package:vehicle_predictive_maintenance_app/app/widgets/vera_components.dart';
import 'package:vehicle_predictive_maintenance_app/core/providers/diagnostics_provider.dart';

/// Conexión con el adaptador ELM327 y estado del detector de anomalías que
/// se ejecuta en el teléfono.
class ObdAnomalyCard extends StatelessWidget {
  const ObdAnomalyCard({super.key});

  @override
  Widget build(BuildContext context) {
    final d = context.watch<DiagnosticsProvider>();
    final a = d.latestAnomaly;
    final alert = a?.alert ?? false;
    final color = alert ? AppTheme.warningColor : AppTheme.primaryColor;

    String status;
    if (d.obdConnecting) {
      status = 'Conectando con el adaptador…';
    } else if (!d.obdConnected) {
      status = d.obdError ?? 'Adaptador ELM327 sin conectar';
    } else if (d.missingPids.isNotEmpty) {
      status = 'El vehículo no reporta: ${d.missingPids.join(', ')}. El detector queda desactivado.';
    } else if (!d.detectorReady) {
      status = d.obdError ?? 'Leyendo señales (detector no disponible)';
    } else if (a == null) {
      status = 'Leyendo señales: faltan ${d.samplesToWarmUp} s para la primera evaluación';
    } else if (alert) {
      status = 'Comportamiento anómalo sostenido. Señal que más se aleja de lo normal: ${d.anomalySignalLabel}';
    } else {
      status = 'Operación dentro de lo normal';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: alert ? AppTheme.warningColor : AppTheme.borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('DETECTOR EN EL DISPOSITIVO',
              style: vMono(size: 9.5, color: AppTheme.textFaint, letterSpacing: 0.18)),
          const Spacer(),
          if (a != null)
            Text('s = ${a.score.toStringAsFixed(2)}', style: vMono(size: 10, color: color)),
        ]),
        const SizedBox(height: 8),
        Text(status, style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, height: 1.35)),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            onPressed: d.obdConnecting
                ? null
                : () => d.obdConnected ? d.disconnectObd() : d.connectObd(),
            child: Text(d.obdConnected ? 'Desconectar ELM327' : 'Conectar ELM327'),
          ),
        ),
      ]),
    );
  }
}
