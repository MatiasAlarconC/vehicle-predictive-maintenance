import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:vehicle_predictive_maintenance_app/app/widgets/custom_card.dart';
import 'package:vehicle_predictive_maintenance_app/core/constants/app_constants.dart';
import 'package:vehicle_predictive_maintenance_app/core/enums/app_enums.dart';
import 'package:vehicle_predictive_maintenance_app/core/providers/app_provider.dart';
import 'package:vehicle_predictive_maintenance_app/core/providers/prediction_provider.dart';
import 'package:vehicle_predictive_maintenance_app/features/prediction/widgets/explanation_widget.dart';
import 'package:vehicle_predictive_maintenance_app/features/prediction/widgets/prediction_form.dart';
import 'package:vehicle_predictive_maintenance_app/features/prediction/widgets/prediction_gauge.dart';
import 'package:vehicle_predictive_maintenance_app/models/prediction_request.dart';
import 'package:vehicle_predictive_maintenance_app/services/history_service.dart';

class PredictionScreen extends StatelessWidget {
  const PredictionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PredictionProvider(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Realizar Predicción'),
        ),
        body: Consumer<PredictionProvider>(
          builder: (context, provider, child) {
            switch (provider.status) {
              case PredictionStatus.initial:
                return const PredictionInputView();
              case PredictionStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case PredictionStatus.success:
                return PredictionResultView(response: provider.predictionResponse!);
              case PredictionStatus.error:
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: ${provider.errorMessage}'),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => provider.reset(),
                        child: const Text('Intentar de Nuevo'),
                      )
                    ],
                  ),
                );
            }
          },
        ),
      ),
    );
  }
}

class PredictionInputView extends StatelessWidget {
  const PredictionInputView({super.key});

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final appProvider = Provider.of<AppProvider>(context);
    final predictionProvider = Provider.of<PredictionProvider>(context, listen: false);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: CustomCard(
        child: PredictionForm(
          formKey: formKey,
          isLoading: predictionProvider.status == PredictionStatus.loading,
          onPredict: (engineTemp, brakePad, tirePressure, maintenanceType) {
            final request = PredictionRequest(
              engineTemp: engineTemp,
              brakePadThickness: brakePad,
              tirePressure: tirePressure,
              maintenanceType: maintenanceType,
            );
            predictionProvider.makePrediction(
              request,
              appProvider.appMode,
              baseUrl: appProvider.baseUrl,
              onFallbackToDemo: () async {
                await appProvider.setAppMode(AppMode.demo);
              },
            );
          },
        ),
      ),
    );
  }
}

class PredictionResultView extends StatelessWidget {
  final dynamic response;
  const PredictionResultView({super.key, required this.response});

  String _lottieFor(double probability) {
    if (probability >= 0.8) {
      return 'https://assets5.lottiefiles.com/packages/lf20_jbrw3hcz.json';
    }
    if (probability >= 0.45) {
      return 'https://assets2.lottiefiles.com/packages/lf20_touohxv0.json';
    }
    return 'https://assets5.lottiefiles.com/packages/lf20_ydo1amjm.json';
  }

  Future<void> _saveToHistory(BuildContext context) async {
    await HistoryService().saveRecord({
      'timestamp': DateTime.now().toIso8601String(),
      'anomaly': response.anomaly,
      'probability': response.probability,
      'source': AppConstants.datasetName,
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Guardado en historial')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final high = response.probability >= 0.8;
    final medium = response.probability >= 0.45 && response.probability < 0.8;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          CustomCard(
            child: Column(
              children: [
                SizedBox(
                  height: 120,
                  child: Lottie.network(
                    _lottieFor(response.probability),
                    repeat: true,
                    errorBuilder: (context, _, __) => Icon(
                      high
                          ? Icons.error
                          : medium
                              ? Icons.warning_amber
                              : Icons.check_circle,
                      size: 64,
                    ),
                  ),
                ),
                Text(
                  response.anomaly
                      ? (high ? 'Peligro detectado' : 'Alerta detectada')
                      : 'Sin anomalia detectada',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: high
                        ? Colors.red
                        : medium
                            ? Colors.orange
                            : Colors.green,
                  ),
                ),
                const SizedBox(height: 16),
                PredictionGauge(probability: response.probability),
                Text(
                  'Probabilidad de Anomalía: ${(response.probability * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CustomCard(
            child: ExplanationWidget(explanation: response.explanation),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _saveToHistory(context),
                  child: const Text('Guardar en historial'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Provider.of<PredictionProvider>(context, listen: false).reset(),
                  child: const Text('Nueva prediccion'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
