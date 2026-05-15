import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:vehicle_predictive_maintenance_app/app/theme/app_theme.dart';
import 'package:vehicle_predictive_maintenance_app/app/widgets/vera_components.dart';
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
  final _ipCtrl   = TextEditingController();
  final _portCtrl = TextEditingController();
  bool _testing       = false;
  bool _initialized   = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final app = context.read<AppProvider>();
    _ipCtrl.text   = app.serverIp;
    _portCtrl.text = app.serverPort;
    _initialized = true;
  }

  @override
  void dispose() {
    _ipCtrl.dispose();
    _portCtrl.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    if (_ipCtrl.text.trim().isEmpty || _portCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Ingresa IP y puerto', style: vMono(color: Colors.white, size: 12)),
        backgroundColor: AppTheme.dangerColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ));
      return;
    }
    setState(() => _testing = true);
    final app     = context.read<AppProvider>();
    final baseUrl = 'http://${_ipCtrl.text.trim()}:${_portCtrl.text.trim()}';
    final ok      = await ApiService().pingHealth(baseUrl);
    await app.setServer(_ipCtrl.text.trim(), _portCtrl.text.trim());
    await app.setConnection(ok);
    if (mounted) {
      setState(() => _testing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          ok ? 'Conexión exitosa' : 'Sin conexión al servidor',
          style: vMono(color: ok ? Colors.black : Colors.white, size: 12),
        ),
        backgroundColor: ok ? AppTheme.primaryColor : AppTheme.dangerColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final app       = context.watch<AppProvider>();
    final auth      = context.watch<AuthProvider>();
    final isDemo    = app.appMode == AppMode.demo;
    final connected = app.isConnected;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(children: [

          // ── Top bar ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.borderColor))),
            child: Row(children: [
              const VeraMark(size: 14),
              const SizedBox(width: 8),
              Text('VERA', style: vMono(color: AppTheme.textPrimary, size: 9.5, letterSpacing: 0.18)),
              Text(' · ajustes', style: vMono(size: 9.5, color: AppTheme.textFaint, letterSpacing: 0.18)),
              const Spacer(),
              Text('v1.0.0', style: vMono(size: 9.5, color: AppTheme.textFaint)),
            ]),
          ),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // ── Page title ────────────────────────────────────────
                Text('Ajustes', style: GoogleFonts.spaceGrotesk(
                    fontSize: 30, fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary, height: 1)),
                const SizedBox(height: 28),

                // ── Section: Modo ─────────────────────────────────────
                _SectionLabel('Modo de operación'),
                const SizedBox(height: 10),
                _SettingsCard(children: [
                  _SettingsRow(
                    label: 'Modo demo',
                    subtitle: 'Datos simulados OBD-II',
                    trailing: Switch(
                      value: isDemo,
                      onChanged: (v) => app.setAppMode(v ? AppMode.demo : AppMode.production),
                      activeTrackColor: AppTheme.warningColor.withValues(alpha: 0.5),
                      activeThumbColor: AppTheme.warningColor,
                      inactiveThumbColor: AppTheme.textSecondary,
                      inactiveTrackColor: AppTheme.borderStrong,
                    ),
                    last: true,
                  ),
                ]),

                const SizedBox(height: 24),

                // ── Section: Servidor ─────────────────────────────────
                Row(children: [
                  _SectionLabel('Servidor FastAPI'),
                  const Spacer(),
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: connected ? AppTheme.primaryColor : AppTheme.dangerColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(connected ? 'online' : 'offline',
                      style: vMono(size: 9, color: AppTheme.textFaint)),
                ]),
                const SizedBox(height: 10),
                _SettingsCard(children: [
                  _InputRow(label: 'Dirección IP', hint: '192.168.1.100',
                      controller: _ipCtrl, keyboardType: TextInputType.number),
                  _InputRow(label: 'Puerto', hint: '8000',
                      controller: _portCtrl, keyboardType: TextInputType.number, last: true),
                ]),
                const SizedBox(height: 10),
                Text('URL activa: ${app.baseUrl}',
                    style: vMono(size: 9, color: AppTheme.textFaint, letterSpacing: 0.05)),
                const SizedBox(height: 12),
                // Test connection button
                GestureDetector(
                  onTap: _testing ? null : _testConnection,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      if (_testing)
                        const SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.textSecondary,
                          ),
                        )
                      else
                        const Icon(Icons.wifi_tethering_rounded,
                            color: AppTheme.textSecondary, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        _testing ? 'Probando...' : 'Probar conexión',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 14, fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary),
                      ),
                    ]),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Section: Sistema ──────────────────────────────────
                _SectionLabel('Sistema'),
                const SizedBox(height: 10),
                _SettingsCard(children: [
                  _InfoRow(label: 'Versión', value: 'v1.0.0'),
                  _InfoRow(label: 'Plataforma', value: 'Flutter 3.x'),
                  _InfoRow(label: 'Modelo IA', value: 'XGBoost + RF'),
                  _InfoRow(label: 'Explicabilidad', value: 'LIME + SHAP'),
                  _InfoRow(label: 'Protocolo', value: 'OBD-II (ELM327)', last: true),
                ]),

                const SizedBox(height: 24),

                // ── Section: Cuenta ───────────────────────────────────
                _SectionLabel('Cuenta'),
                const SizedBox(height: 10),
                _SettingsCard(children: [
                  _InfoRow(label: 'Nombre', value: auth.firstName.isNotEmpty ? auth.firstName : '—'),
                  _InfoRow(label: 'Email', value: auth.email ?? '—', last: true),
                ]),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    await auth.signOut();
                    if (context.mounted) context.go('/auth');
                  },
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.dangerColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.logout_rounded, color: AppTheme.dangerColor, size: 16),
                      const SizedBox(width: 8),
                      Text('Cerrar sesión',
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: 14, fontWeight: FontWeight.w600,
                              color: AppTheme.dangerColor)),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: vMono(size: 10, color: AppTheme.textFaint, letterSpacing: 0.2),
    );
  }
}

// ─── Settings card container ──────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

// ─── Toggle row ───────────────────────────────────────────────────────────────

class _SettingsRow extends StatelessWidget {
  final String label;
  final String? subtitle;
  final Widget trailing;
  final bool last;

  const _SettingsRow({
    required this.label,
    this.subtitle,
    required this.trailing,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: GoogleFonts.spaceGrotesk(
                  fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
              if (subtitle != null)
                Text(subtitle!, style: vMono(size: 9, color: AppTheme.textFaint, letterSpacing: 0.05)),
            ])),
            trailing,
          ]),
        ),
        if (!last) Divider(color: AppTheme.borderColor, height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}

// ─── Info row ─────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label, value;
  final bool last;

  const _InfoRow({required this.label, required this.value, this.last = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Text(label, style: vMono(size: 11, color: AppTheme.textSecondary, letterSpacing: 0.05)),
            const Spacer(),
            Text(value, style: GoogleFonts.spaceGrotesk(
                fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
          ]),
        ),
        if (!last) Divider(color: AppTheme.borderColor, height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}

// ─── Input row ────────────────────────────────────────────────────────────────

class _InputRow extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool last;

  const _InputRow({
    required this.label,
    required this.hint,
    required this.controller,
    required this.keyboardType,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            SizedBox(
              width: 110,
              child: Text(label, style: vMono(size: 11, color: AppTheme.textSecondary, letterSpacing: 0.05)),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: keyboardType,
                textAlign: TextAlign.right,
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
                cursorColor: AppTheme.primaryColor,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintText: hint,
                  hintStyle: vMono(size: 11, color: AppTheme.textFaint),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ]),
        ),
        if (!last) Divider(color: AppTheme.borderColor, height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}
