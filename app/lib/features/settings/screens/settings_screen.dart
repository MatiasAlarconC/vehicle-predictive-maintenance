import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:vehicle_predictive_maintenance_app/app/theme/app_theme.dart';
import 'package:vehicle_predictive_maintenance_app/app/widgets/custom_card.dart';
import 'package:vehicle_predictive_maintenance_app/core/constants/app_constants.dart';
import 'package:vehicle_predictive_maintenance_app/core/enums/app_enums.dart';
import 'package:vehicle_predictive_maintenance_app/core/providers/app_provider.dart';
import 'package:vehicle_predictive_maintenance_app/core/providers/auth_provider.dart';
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
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final appProvider = context.read<AppProvider>();
    _ipController.text = appProvider.serverIp;
    _portController.text = appProvider.serverPort;
    _initialized = true;
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    if (_ipController.text.trim().isEmpty ||
        _portController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa IP y puerto antes de probar la conexión'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
      return;
    }

    setState(() => _testing = true);
    final appProvider = context.read<AppProvider>();
    final baseUrl =
        'http://${_ipController.text.trim()}:${_portController.text.trim()}';
    final ok = await ApiService().pingHealth(baseUrl);
    await appProvider.setServer(
        _ipController.text.trim(), _portController.text.trim());
    await appProvider.setConnection(ok);
    if (mounted) {
      setState(() {
        _testing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(ok ? '✓ Conexión exitosa' : '✗ Sin conexión al servidor'),
          backgroundColor: ok ? AppTheme.successColor : AppTheme.dangerColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final isDemo = appProvider.appMode == AppMode.demo;
    final connectionOk = appProvider.isConnected;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _SettingsHeader()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Modo de operación
              _SectionTitle(label: 'MODO DE OPERACIÓN'),
              const SizedBox(height: 10),
              CustomCard(
                child: Column(
                  children: [
                    _ModeToggle(
                      isDemo: isDemo,
                      onChanged: (v) => appProvider
                          .setAppMode(v ? AppMode.demo : AppMode.production),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Conexión al servidor
              _SectionTitle(label: 'SERVIDOR FASTAPI'),
              const SizedBox(height: 10),
              CustomCard(
                child: Column(
                  children: [
                    TextField(
                      controller: _ipController,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Dirección IP del servidor',
                        prefixIcon: Icon(Icons.router_rounded,
                            color: AppTheme.primaryColor, size: 20),
                        hintText: '192.168.1.100',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _portController,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Puerto',
                        prefixIcon: Icon(Icons.settings_ethernet_rounded,
                            color: AppTheme.primaryColor, size: 20),
                        hintText: '8000',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: _testing ? null : _testConnection,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 50,
                          decoration: BoxDecoration(
                            color: connectionOk
                                ? AppTheme.successColor.withValues(alpha: 0.1)
                                : AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: connectionOk
                                  ? AppTheme.successColor.withValues(alpha: 0.4)
                                  : AppTheme.borderColor,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_testing)
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primaryColor,
                                  ),
                                )
                              else
                                Icon(
                                  connectionOk
                                      ? Icons.check_circle_rounded
                                      : Icons.network_check_rounded,
                                  size: 18,
                                  color: connectionOk
                                      ? AppTheme.successColor
                                      : AppTheme.primaryColor,
                                ),
                              const SizedBox(width: 10),
                              Text(
                                _testing
                                    ? 'Probando...'
                                    : connectionOk
                                        ? 'Conectado'
                                        : 'Probar conexión',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: connectionOk
                                      ? AppTheme.successColor
                                      : AppTheme.primaryColor,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Info del sistema
              _SectionTitle(label: 'INFORMACIÓN DEL SISTEMA'),
              const SizedBox(height: 10),
              CustomCard(
                child: Column(
                  children: [
                    _InfoRow(
                        label: 'Versión',
                        value: '1.0.0',
                        icon: Icons.info_outline_rounded),
                    const Divider(color: AppTheme.borderColor, height: 20),
                    _InfoRow(
                        label: 'Dataset',
                        value: AppConstants.datasetName,
                        icon: Icons.dataset_rounded),
                    const Divider(color: AppTheme.borderColor, height: 20),
                    _InfoRow(
                        label: 'Modelo ML',
                        value: 'XGBoost + Random Forest',
                        icon: Icons.psychology_rounded),
                    const Divider(color: AppTheme.borderColor, height: 20),
                    _InfoRow(
                        label: 'URL activa',
                        value: appProvider.baseUrl,
                        icon: Icons.link_rounded),
                    const Divider(color: AppTheme.borderColor, height: 20),
                    _InfoRow(
                        label: 'Explicabilidad',
                        value: 'LIME + SHAP',
                        icon: Icons.lightbulb_outline_rounded),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Cerrar sesión
              _SectionTitle(label: 'CUENTA'),
              const SizedBox(height: 10),
              _SignOutButton(),

              const SizedBox(height: 24),

              // Footer
              Center(
                child: Text(
                  'Vera · Mantenimiento Predictivo con IA',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary.withValues(alpha: 0.5),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.backgroundSecondary, AppTheme.background],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AJUSTES',
            style: TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: 3,
            ),
          ),
          Text(
            'Configuración del sistema',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        color: AppTheme.textSecondary,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final bool isDemo;
  final ValueChanged<bool> onChanged;
  const _ModeToggle({required this.isDemo, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isDemo ? AppTheme.warningColor : AppTheme.successColor)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isDemo ? Icons.science_rounded : Icons.wifi_rounded,
            color: isDemo ? AppTheme.warningColor : AppTheme.successColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isDemo ? 'Modo Demo' : 'Modo Producción',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                isDemo ? 'Datos simulados OBD-II' : 'Conectado a Raspberry Pi',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        Switch(
          value: !isDemo,
          onChanged: onChanged,
          activeThumbColor: AppTheme.successColor,
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _InfoRow(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 10),
        Text(label,
            style:
                const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppTheme.surfaceElevated,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text('Cerrar sesión',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontFamily: 'Rajdhani',
                    fontWeight: FontWeight.w700)),
            content: const Text('¿Estás seguro que quieres salir?',
                style: TextStyle(color: AppTheme.textSecondary)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar',
                    style: TextStyle(color: AppTheme.textSecondary)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Cerrar sesión',
                    style: TextStyle(color: AppTheme.dangerColor,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
        if (confirmed == true && context.mounted) {
          await context.read<AuthProvider>().signOut();
          if (context.mounted) context.go('/login');
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.dangerColor.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded,
                color: AppTheme.dangerColor, size: 20),
            const SizedBox(width: 10),
            const Text(
              'CERRAR SESIÓN',
              style: TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.dangerColor,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
