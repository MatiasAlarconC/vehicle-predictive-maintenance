import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:vehicle_predictive_maintenance_app/app/theme/app_theme.dart';
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
  bool _needsVerification = false;

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
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
    super.dispose();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.dangerColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      final result =
          await auth.signIn(_emailCtrl.text.trim(), _passCtrl.text);
      if (!mounted) return;
      if (result.ok) {
        context.go('/select-vehicle');
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
      context.go('/select-vehicle');
    } else {
      _showError(result.error ?? 'Código incorrecto');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          _GlowBlob(top: -100, right: -80, size: 300,
              color: AppTheme.primaryColor.withValues(alpha: 0.12)),
          _GlowBlob(bottom: -60, left: -80, size: 250,
              color: AppTheme.primaryColor.withValues(alpha: 0.07)),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: _needsVerification
                    ? _VerificationView(
                        codeCtrl: _codeCtrl,
                        email: _emailCtrl.text.trim(),
                        loading: loading,
                        onVerify: _verifyCode,
                      )
                    : _AuthForm(
                        formKey: _formKey,
                        isRegister: _isRegister,
                        loading: loading,
                        obscure: _obscure,
                        nameCtrl: _nameCtrl,
                        emailCtrl: _emailCtrl,
                        passCtrl: _passCtrl,
                        onToggleObscure: () =>
                            setState(() => _obscure = !_obscure),
                        onSubmit: _submit,
                        onToggleMode: () => setState(() {
                          _isRegister = !_isRegister;
                          _formKey.currentState?.reset();
                        }),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Auth form ──────────────────────────────────────────────────────────────────

class _AuthForm extends StatelessWidget {
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

  const _AuthForm({
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
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),
          const _Logo(),
          const SizedBox(height: 56),
          Text(
            isRegister ? 'Crear cuenta' : 'Bienvenido',
            style: const TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isRegister
                ? 'Regístrate para comenzar'
                : 'Inicia sesión en tu cuenta',
            style: const TextStyle(
                fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 40),
          if (isRegister) ...[
            _AuthField(
              controller: nameCtrl,
              label: 'Nombre completo',
              icon: Icons.person_outline_rounded,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
          ],
          _AuthField(
            controller: emailCtrl,
            label: 'Correo electrónico',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (v) =>
                v == null || !v.contains('@') ? 'Email inválido' : null,
          ),
          const SizedBox(height: 16),
          _AuthField(
            controller: passCtrl,
            label: 'Contraseña',
            icon: Icons.lock_outline_rounded,
            obscureText: obscure,
            suffix: GestureDetector(
              onTap: onToggleObscure,
              child: Icon(
                obscure
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: AppTheme.textSecondary,
                size: 20,
              ),
            ),
            validator: (v) =>
                v == null || v.length < 8 ? 'Mínimo 8 caracteres' : null,
          ),
          const SizedBox(height: 32),
          _SubmitButton(
            loading: loading,
            label: isRegister ? 'CREAR CUENTA' : 'INICIAR SESIÓN',
            onTap: onSubmit,
          ),
          const SizedBox(height: 24),
          Center(
            child: GestureDetector(
              onTap: onToggleMode,
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 14),
                  children: [
                    TextSpan(
                      text: isRegister
                          ? '¿Ya tienes cuenta? '
                          : '¿No tienes cuenta? ',
                      style: const TextStyle(
                          color: AppTheme.textSecondary),
                    ),
                    TextSpan(
                      text: isRegister ? 'Iniciar sesión' : 'Registrarse',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
// ── Email verification ─────────────────────────────────────────────────────────

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 48),
        const _Logo(),
        const SizedBox(height: 56),
        const Text(
          'Verifica tu\ncorreo',
          style: TextStyle(
            fontFamily: 'Rajdhani',
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            height: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Código enviado a $email',
          style: const TextStyle(
              fontSize: 14, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 40),
        _AuthField(
          controller: codeCtrl,
          label: 'Código de verificación',
          icon: Icons.verified_outlined,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 32),
        _SubmitButton(loading: loading, label: 'VERIFICAR', onTap: onVerify),
        const SizedBox(height: 48),
      ],
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(
          'assets/images/vera_logo.svg',
          width: 44,
          height: 44,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'VERA',
              style: TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: 4,
              ),
            ),
            ShaderMask(
              shaderCallback: (b) =>
                  AppTheme.primaryGradient.createShader(b),
              child: const Text(
                'MANTENIMIENTO PREDICTIVO',
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool loading;
  final String label;
  final VoidCallback onTap;

  const _SubmitButton(
      {required this.loading, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: loading
          ? const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.primaryColor),
              ),
            )
          : GestureDetector(
              onTap: onTap,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.glowShadow(AppTheme.primaryColor,
                      intensity: 0.3),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _AuthField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.suffix,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppTheme.surface,
        labelStyle: const TextStyle(
            color: AppTheme.textSecondary, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppTheme.primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppTheme.dangerColor, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppTheme.dangerColor, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double size;
  final Color color;

  const _GlowBlob(
      {this.top, this.bottom, this.left, this.right,
      required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent]),
        ),
      ),
    );
  }
}
