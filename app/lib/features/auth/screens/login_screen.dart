import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:vehicle_predictive_maintenance_app/app/theme/app_theme.dart';
import 'package:vehicle_predictive_maintenance_app/app/widgets/vera_components.dart';
import 'package:vehicle_predictive_maintenance_app/core/providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isRegister = false;
  bool _obscure = true;
  bool _obscureNew = true;
  bool _needsVerification = false;
  bool _needsMfa = false;
  // forgot-password states: 'none' | 'emailEntry' | 'codeEntry'
  String _forgotStep = 'none';

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _mfaCodeCtrl = TextEditingController();
  final _resetEmailCtrl = TextEditingController();
  final _resetCodeCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _codeCtrl.dispose();
    _mfaCodeCtrl.dispose();
    _resetEmailCtrl.dispose();
    _resetCodeCtrl.dispose();
    _newPassCtrl.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: vMono(color: Colors.white, size: 12)),
      backgroundColor: AppTheme.dangerColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    if (_isRegister) {
      final nameParts = _nameCtrl.text.trim().split(' ');
      final result = await auth.signUp(
        firstName: nameParts.first,
        lastName: nameParts.skip(1).join(' '),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (!mounted) return;
      if (result.ok) {
        context.go('/select-vehicle');
      } else if (result.needsEmailVerification) {
        setState(() => _needsVerification = true);
      } else {
        _showError(result.error ?? 'Error al registrarse');
      }
    } else {
      final result = await auth.signIn(_emailCtrl.text.trim(), _passCtrl.text);
      if (!mounted) return;
      if (result.ok) {
        // Router will redirect automatically via refreshListenable
      } else if (result.mfaRequired) {
        setState(() => _needsMfa = true);
      } else {
        _showError(result.error ?? 'Credenciales incorrectas');
      }
    }
  }

  Future<void> _verifyCode() async {
    if (_codeCtrl.text.trim().isEmpty) return;
    final auth = context.read<AuthProvider>();
    final result = await auth.verifyEmail(_codeCtrl.text.trim());
    if (!mounted) return;
    if (result.ok) {
      // Router redirects automatically
    } else {
      _showError(result.error ?? 'Código incorrecto');
    }
  }

  Future<void> _verifyMfa() async {
    final code = _mfaCodeCtrl.text.trim();
    if (code.isEmpty) return;
    final auth = context.read<AuthProvider>();
    final result = await auth.verifyMfa(code);
    if (!mounted) return;
    if (result.ok) {
      // Router redirects automatically
    } else {
      _showError(result.error ?? 'Código incorrecto');
    }
  }

  Future<void> _sendResetCode() async {
    final email = _resetEmailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError('Ingresa un email válido');
      return;
    }
    final auth = context.read<AuthProvider>();
    final result = await auth.sendPasswordResetCode(email);
    if (!mounted) return;
    if (result.ok) {
      setState(() => _forgotStep = 'codeEntry');
    } else {
      _showError(result.error ?? 'No se pudo enviar el código');
    }
  }

  Future<void> _completeReset() async {
    final code = _resetCodeCtrl.text.trim();
    final newPass = _newPassCtrl.text;
    if (code.length != 6) { _showError('Código de 6 dígitos requerido'); return; }
    if (newPass.length < 8) { _showError('Mínimo 8 caracteres'); return; }
    final auth = context.read<AuthProvider>();
    final result = await auth.completePasswordReset(code, newPass);
    if (!mounted) return;
    if (result.ok) {
      // Router redirects automatically — to dashboard if vehicle exists, else /select-vehicle
      setState(() => _forgotStep = 'none');
    } else {
      _showError(result.error ?? 'Código incorrecto o expirado');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().isLoading;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(children: [
        // radial bg
        Positioned.fill(child: CustomPaint(painter: _AuthBgPainter())),
        SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              child: _needsVerification
                  ? _VerificationView(
                      codeCtrl: _codeCtrl,
                      email: _emailCtrl.text.trim(),
                      loading: loading,
                      onVerify: _verifyCode,
                    )
                  : _needsMfa
                      ? _MfaView(
                          codeCtrl: _mfaCodeCtrl,
                          email: _emailCtrl.text.trim(),
                          loading: loading,
                          onVerify: _verifyMfa,
                          onBack: () => setState(() => _needsMfa = false),
                        )
                      : _forgotStep == 'emailEntry'
                      ? _ForgotEmailView(
                          emailCtrl: _resetEmailCtrl,
                          loading: loading,
                          onSend: _sendResetCode,
                          onBack: () => setState(() => _forgotStep = 'none'),
                        )
                      : _forgotStep == 'codeEntry'
                          ? _ForgotResetView(
                              codeCtrl: _resetCodeCtrl,
                              passCtrl: _newPassCtrl,
                              obscure: _obscureNew,
                              loading: loading,
                              email: _resetEmailCtrl.text.trim(),
                              onToggleObscure: () => setState(() => _obscureNew = !_obscureNew),
                              onComplete: _completeReset,
                              onBack: () => setState(() => _forgotStep = 'emailEntry'),
                            )
                          : _AuthBody(
                              formKey: _formKey,
                              isRegister: _isRegister,
                              loading: loading,
                              obscure: _obscure,
                              nameCtrl: _nameCtrl,
                              emailCtrl: _emailCtrl,
                              passCtrl: _passCtrl,
                              onToggleObscure: () => setState(() => _obscure = !_obscure),
                              onSubmit: _submit,
                              onForgotPassword: () => setState(() {
                                _forgotStep = 'emailEntry';
                                _resetEmailCtrl.text = _emailCtrl.text;
                              }),
                              onToggleMode: () => setState(() {
                                _isRegister = !_isRegister;
                                _formKey.currentState?.reset();
                              }),
                            ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Main auth body ────────────────────────────────────────────────────────────

class _AuthBody extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final bool isRegister;
  final bool loading;
  final bool obscure;
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final VoidCallback onToggleMode;
  final VoidCallback onForgotPassword;

  const _AuthBody({
    required this.formKey,
    required this.isRegister,
    required this.loading,
    required this.obscure,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.passCtrl,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.onToggleMode,
    required this.onForgotPassword,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 18),

          // ── Top bar ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.only(bottom: 14),
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.borderColor))),
            child: Row(children: [
              const VeraMark(size: 14),
              const SizedBox(width: 8),
              Text('VERA', style: vMono(color: AppTheme.textPrimary, size: 9.5, letterSpacing: 0.18)),
              Text(isRegister ? ' · registro' : ' · authorization',
                  style: vMono(size: 9.5, letterSpacing: 0.18)),
              const Spacer(),
              const VeraLiveDot(),
              const SizedBox(width: 5),
              Text('online', style: vMono(size: 9.5, letterSpacing: 0.18)),
            ]),
          ),

          const SizedBox(height: 22),

          // ── Hero text ────────────────────────────────────────────────
          Text(
            isRegister ? 'stage 03 · nueva cuenta' : 'stage 03 · auth',
            style: vMono(color: AppTheme.textFaint, size: 9.5, letterSpacing: 0.18),
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(children: [
              TextSpan(
                text: isRegister ? 'Crear cuenta' : 'Bienvenido',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 36, fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary, letterSpacing: -0.028 * 36, height: 1.0,
                ),
              ),
              TextSpan(
                text: '_',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 36, fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor, height: 1.0,
                ),
              ),
            ]),
          ),
          const SizedBox(height: 4),
          Text(
            isRegister
                ? 'regístrate para comenzar'
                : 'inicia sesión para acceder a tu cabina',
            style: vBody(size: 13),
          ),

          const SizedBox(height: 20),

          // ── Segmented tab ─────────────────────────────────────────────
          VeraSegmented(
            active: isRegister ? 1 : 0,
            items: const ['Iniciar sesión', 'Crear cuenta'],
            onChanged: (i) {
              if ((i == 0) == isRegister) onToggleMode();
            },
          ),

          const SizedBox(height: 20),

          // ── Fields ───────────────────────────────────────────────────
          if (isRegister) ...[
            VeraPromptField(
              id: 'NAM_01',
              label: 'nombre completo',
              controller: nameCtrl,
              validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 10),
          ],
          VeraPromptField(
            id: 'USR_01',
            label: 'correo',
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            validator: (v) => v == null || !v.contains('@') ? 'Email inválido' : null,
          ),
          const SizedBox(height: 10),
          VeraPromptField(
            id: 'PWD_01',
            label: 'contraseña',
            controller: passCtrl,
            obscure: obscure,
            suffix: GestureDetector(
              onTap: onToggleObscure,
              child: Icon(
                obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                color: AppTheme.textSecondary, size: 18,
              ),
            ),
            validator: (v) => v == null || v.length < 8 ? 'Mínimo 8 caracteres' : null,
          ),

          if (!isRegister) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: onForgotPassword,
                child: Text(
                  '¿olvidaste tu contraseña? → recuperar',
                  style: vMono(size: 11, color: AppTheme.primaryColor, letterSpacing: 0.08),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // ── CTA button ───────────────────────────────────────────────
          VeraButton(
            label: isRegister ? 'CREAR CUENTA' : 'INICIAR SESIÓN',
            loading: loading,
            onTap: onSubmit,
          ),

          const SizedBox(height: 20),

          Center(
            child: GestureDetector(
              onTap: onToggleMode,
              child: RichText(
                text: TextSpan(children: [
                  TextSpan(
                    text: isRegister ? '¿no tienes cuenta? ' : '¿no tienes cuenta? ',
                    style: vMono(size: 12, letterSpacing: 0.06),
                  ),
                  TextSpan(
                    text: isRegister ? 'iniciar sesión →' : 'regístrate →',
                    style: vMono(
                      size: 12, weight: FontWeight.w600,
                      color: AppTheme.textPrimary, letterSpacing: 0.06,
                    ),
                  ),
                ]),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // ── System status ────────────────────────────────────────────
          const VeraDivider(label: 'system status'),
          const SizedBox(height: 12),
          VeraDataLine(k: 'server', v: '200 OK · 24 ms'),
          const VeraDataLine(k: 'model', v: 'loaded'),
          const VeraDataLine(k: 'build', v: '2046'),

          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

// ── Email verification view ───────────────────────────────────────────────────

class _VerificationView extends StatelessWidget {
  final TextEditingController codeCtrl;
  final String email;
  final bool loading;
  final VoidCallback onVerify;

  const _VerificationView({
    required this.codeCtrl,
    required this.email,
    required this.loading,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.only(bottom: 14),
          decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderColor))),
          child: Row(children: [
            const VeraMark(size: 14),
            const SizedBox(width: 8),
            Text('VERA', style: vMono(color: AppTheme.textPrimary, size: 9.5, letterSpacing: 0.18)),
            Text(' · verificación', style: vMono(size: 9.5, letterSpacing: 0.18)),
            const Spacer(),
            const VeraLiveDot(),
          ]),
        ),
        const SizedBox(height: 22),
        Text('stage 03 · email confirm',
            style: vMono(color: AppTheme.textFaint, size: 9.5, letterSpacing: 0.18)),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(children: [
            TextSpan(
              text: 'Verifica tu\ncorreo',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 34, fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary, height: 1.0,
              ),
            ),
            TextSpan(
              text: '_',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 34, fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor, height: 1.0,
              ),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        Text('Código enviado a $email', style: vBody(size: 13)),
        const SizedBox(height: 28),
        VeraPromptField(
          id: 'VRF_01',
          label: 'código de verificación',
          controller: codeCtrl,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 24),
        VeraButton(label: 'VERIFICAR', loading: loading, onTap: onVerify),
        const SizedBox(height: 40),
      ]),
    );
  }
}

// ── Forgot password — step 1: enter email ─────────────────────────────────────

class _ForgotEmailView extends StatelessWidget {
  final TextEditingController emailCtrl;
  final bool loading;
  final VoidCallback onSend;
  final VoidCallback onBack;

  const _ForgotEmailView({
    required this.emailCtrl,
    required this.loading,
    required this.onSend,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 18),
        _TopBar(subtitle: '· recuperar acceso', onBack: onBack),
        const SizedBox(height: 22),
        Text('recovery', style: vMono(color: AppTheme.textFaint, size: 9.5, letterSpacing: 0.18)),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(children: [
            TextSpan(
              text: 'Recuperar\ncontraseña',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 34, fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary, height: 1.05,
              ),
            ),
            TextSpan(
              text: '_',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 34, fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor, height: 1.05,
              ),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        Text('Te enviaremos un código de 6 dígitos a tu email.',
            style: vBody(size: 13)),
        const SizedBox(height: 28),
        VeraPromptField(
          id: 'RST_EMAIL',
          label: 'email',
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 24),
        VeraButton(label: 'ENVIAR CÓDIGO', loading: loading, onTap: onSend),
        const SizedBox(height: 40),
      ]),
    );
  }
}

// ── Forgot password — step 2: enter code + new password ──────────────────────

class _ForgotResetView extends StatelessWidget {
  final TextEditingController codeCtrl;
  final TextEditingController passCtrl;
  final bool obscure;
  final bool loading;
  final String email;
  final VoidCallback onToggleObscure;
  final VoidCallback onComplete;
  final VoidCallback onBack;

  const _ForgotResetView({
    required this.codeCtrl,
    required this.passCtrl,
    required this.obscure,
    required this.loading,
    required this.email,
    required this.onToggleObscure,
    required this.onComplete,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 18),
        _TopBar(subtitle: '· nueva contraseña', onBack: onBack),
        const SizedBox(height: 22),
        Text('recovery · step 2', style: vMono(color: AppTheme.textFaint, size: 9.5, letterSpacing: 0.18)),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(children: [
            TextSpan(
              text: 'Nuevo\nacceso',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 34, fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary, height: 1.05,
              ),
            ),
            TextSpan(
              text: '_',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 34, fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor, height: 1.05,
              ),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        Text('Código enviado a $email', style: vBody(size: 13)),
        const SizedBox(height: 28),
        VeraPromptField(
          id: 'RST_CODE',
          label: 'código de 6 dígitos',
          controller: codeCtrl,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        VeraPromptField(
          id: 'RST_PASS',
          label: 'nueva contraseña',
          controller: passCtrl,
          obscure: obscure,
          suffix: GestureDetector(
            onTap: onToggleObscure,
            child: Icon(
              obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: AppTheme.textSecondary, size: 18,
            ),
          ),
        ),
        const SizedBox(height: 24),
        VeraButton(label: 'RESTABLECER', loading: loading, onTap: onComplete),
        const SizedBox(height: 40),
      ]),
    );
  }
}

// ── Shared top bar with back arrow ────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String subtitle;
  final VoidCallback onBack;
  const _TopBar({required this.subtitle, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 14),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.borderColor))),
      child: Row(children: [
        GestureDetector(
          onTap: onBack,
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 14, color: AppTheme.textSecondary),
        ),
        const SizedBox(width: 10),
        const VeraMark(size: 14),
        const SizedBox(width: 8),
        Text('VERA', style: vMono(color: AppTheme.textPrimary, size: 9.5, letterSpacing: 0.18)),
        Text(subtitle, style: vMono(size: 9.5, letterSpacing: 0.18)),
        const Spacer(),
        const VeraLiveDot(),
      ]),
    );
  }
}

// ── MFA verification view ─────────────────────────────────────────────────────

class _MfaView extends StatelessWidget {
  final TextEditingController codeCtrl;
  final String email;
  final bool loading;
  final VoidCallback onVerify;
  final VoidCallback onBack;

  const _MfaView({
    required this.codeCtrl,
    required this.email,
    required this.loading,
    required this.onVerify,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 18),
        _TopBar(subtitle: '· verificación 2FA', onBack: onBack),
        const SizedBox(height: 22),
        Text('autenticación · step 2', style: vMono(color: AppTheme.textFaint, size: 9.5, letterSpacing: 0.18)),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(children: [
            TextSpan(
              text: 'Confirma\ntu acceso',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 34, fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary, height: 1.0,
              ),
            ),
            TextSpan(
              text: '_',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 34, fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor, height: 1.0,
              ),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        Text('Código de 6 dígitos enviado a $email', style: vBody(size: 13)),
        const SizedBox(height: 28),
        VeraPromptField(
          id: 'MFA_01',
          label: 'código de verificación',
          controller: codeCtrl,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 24),
        VeraButton(label: 'VERIFICAR', loading: loading, onTap: onVerify),
        const SizedBox(height: 40),
      ]),
    );
  }
}

// ── Background painter ────────────────────────────────────────────────────────

class _AuthBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // pure black — no background wash
  }
  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
