import 'package:flutter/material.dart';
import 'package:vehicle_predictive_maintenance_app/app/theme/app_theme.dart';

class PredictionForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final Function(double, double, double, String) onPredict;
  final bool isLoading;

  const PredictionForm({
    super.key,
    required this.formKey,
    required this.onPredict,
    required this.isLoading,
  });

  @override
  State<PredictionForm> createState() => _PredictionFormState();
}

class _PredictionFormState extends State<PredictionForm> {
  final _engineTempController = TextEditingController();
  final _brakePadController = TextEditingController();
  final _tirePressureController = TextEditingController();
  String _selectedMaintenanceType = 'Routine Maintenance';

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _engineTempController,
            decoration: const InputDecoration(labelText: 'Temperatura del Motor (°C)'),
            keyboardType: TextInputType.number,
            validator: (value) => value == null || value.isEmpty ? 'Campo requerido' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _brakePadController,
            decoration: const InputDecoration(labelText: 'Grosor Pastilla de Freno (mm)'),
            keyboardType: TextInputType.number,
            validator: (value) => value == null || value.isEmpty ? 'Campo requerido' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _tirePressureController,
            decoration: const InputDecoration(labelText: 'Presión Neumáticos (PSI)'),
            keyboardType: TextInputType.number,
            validator: (value) => value == null || value.isEmpty ? 'Campo requerido' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedMaintenanceType,
            decoration: const InputDecoration(labelText: 'Tipo de Mantenimiento'),
            items: ['Routine Maintenance', 'Component Replacement', 'Repair']
                .map((label) => DropdownMenuItem(
                      value: label,
                      child: Text(label),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedMaintenanceType = value;
                });
              }
            },
          ),
          const SizedBox(height: 32),
          widget.isLoading
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: () {
                    if (widget.formKey.currentState!.validate()) {
                      widget.onPredict(
                        double.parse(_engineTempController.text),
                        double.parse(_brakePadController.text),
                        double.parse(_tirePressureController.text),
                        _selectedMaintenanceType,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  ),
                  child: const Text('Predecir'),
                ),
        ],
      ),
    );
  }
}
