import 'package:flutter/material.dart';
import 'package:vehicle_predictive_maintenance_app/models/prediction_response.dart';

class ExplanationWidget extends StatefulWidget {
  final List<ExplanationItem> explanation;

  const ExplanationWidget({super.key, required this.explanation});

  @override
  State<ExplanationWidget> createState() => _ExplanationWidgetState();
}

class _ExplanationWidgetState extends State<ExplanationWidget> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final shown = _expanded ? widget.explanation : widget.explanation.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Por que?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...shown.map(
          (item) {
            final percent = (item.contribution * 100).clamp(0, 100).toDouble();
            final riskUp = item.direction == 'aumenta riesgo';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.variable.replaceAll('_', ' ')}: contribuye ${percent.toStringAsFixed(1)}% a esta ${riskUp ? 'alerta' : 'estabilidad'}',
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    minHeight: 8,
                    value: percent / 100,
                    backgroundColor: Colors.white10,
                    color: riskUp ? Colors.redAccent : Colors.greenAccent,
                  ),
                ],
              ),
            );
          },
        ),
        TextButton(
          onPressed: () => setState(() => _expanded = !_expanded),
          child: Text(_expanded ? 'Ver menos' : 'Ver analisis completo'),
        ),
      ],
    );
  }
}
