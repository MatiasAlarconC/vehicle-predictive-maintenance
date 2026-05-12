import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vehicle_predictive_maintenance_app/core/constants/app_constants.dart';
import 'package:vehicle_predictive_maintenance_app/core/enums/app_enums.dart';
import 'package:vehicle_predictive_maintenance_app/core/providers/app_provider.dart';
import 'package:vehicle_predictive_maintenance_app/services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _ipController = TextEditingController();
  final _portController = TextEditingController();
  bool _testing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appProvider = context.read<AppProvider>();
    _ipController.text = appProvider.serverIp;
    _portController.text = appProvider.serverPort;
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _testConnection(BuildContext context) async {
    setState(() => _testing = true);
    final appProvider = context.read<AppProvider>();
    final apiService = ApiService();
    final baseUrl = 'http://${_ipController.text}:${_portController.text}';
    final ok = await apiService.pingHealth(baseUrl);
    await appProvider.setServer(_ipController.text, _portController.text);
    await appProvider.setConnection(ok);
    if (mounted) {
      setState(() => _testing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Conexion exitosa' : 'Sin conexion al servidor')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final isDemo = appProvider.appMode == AppMode.demo;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          title: const Text('Modo Demo / Produccion'),
          subtitle: Text(isDemo ? 'Demo (simulado)' : 'Produccion (API real)'),
          value: !isDemo,
          onChanged: (v) => appProvider.setAppMode(v ? AppMode.production : AppMode.demo),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _ipController,
          decoration: const InputDecoration(labelText: 'IP servidor'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _portController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Puerto (default 8000)'),
        ),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          onPressed: _testing ? null : () => _testConnection(context),
          icon: _testing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.network_check),
          label: const Text('Probar conexion'),
        ),
        const SizedBox(height: 20),
        const Divider(),
        const ListTile(
          title: Text('Version'),
          subtitle: Text('1.0.0'),
        ),
        const ListTile(
          title: Text('Dataset usado'),
          subtitle: Text(AppConstants.datasetName),
        ),
        ListTile(
          title: const Text('Base URL actual'),
          subtitle: Text(appProvider.baseUrl),
        ),
      ],
    );
  }
}
