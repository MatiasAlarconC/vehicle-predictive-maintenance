import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vehicle_predictive_maintenance_app/core/constants/clerk_config.dart';

/// Wraps clerk_auth's [clerk.Auth] as a [ChangeNotifier] Provider.
/// Handles sign-in, sign-up (with email verification), and sign-out.
class AuthProvider with ChangeNotifier {
  late clerk.Auth _auth;
  bool _initialized = false;
  bool _loading = false;
  String? _lastError;

  bool get isInitialized => _initialized;
  bool get isLoading => _loading;
  bool get isSignedIn => _initialized && _auth.user != null;
  clerk.User? get user => _initialized ? _auth.user : null;
  String get firstName => user?.firstName ?? user?.email?.split('@').first ?? '';
  String? get lastError => _lastError;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _auth = clerk.Auth(
      config: clerk.AuthConfig(
        publishableKey: kClerkPublishableKey,
        persistor: clerk.DefaultPersistor(
          getCacheDirectory: getApplicationDocumentsDirectory,
        ),
      ),
    );
    try {
      await _auth.initialize();
    } catch (_) {
      // If the publishable key is a placeholder, initialization will fail —
      // the app will still open, but auth calls will show an error snackbar.
    }
    _initialized = true;
    notifyListeners();
  }

  Future<SignInResult> signIn(String email, String password) async {
    _loading = true;
    _lastError = null;
    notifyListeners();
    try {
      await _auth.attemptSignIn(
        strategy: clerk.Strategy.password,
        identifier: email,
        password: password,
      );
      return _auth.user != null
          ? SignInResult.success
          : SignInResult.failure('Credenciales incorrectas');
    } on clerk.ClerkError catch (e) {
      _lastError = e.message;
      return SignInResult.failure(e.message);
    } catch (e) {
      _lastError = e.toString();
      return SignInResult.failure(e.toString());
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<SignUpResult> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    _loading = true;
    _lastError = null;
    notifyListeners();
    try {
      await _auth.attemptSignUp(
        strategy: clerk.Strategy.password,
        firstName: firstName,
        lastName: lastName,
        emailAddress: email,
        password: password,
        passwordConfirmation: password,
      );
      if (_auth.user != null) return SignUpResult.success;
      // Likely needs email verification
      return SignUpResult.needsVerification;
    } on clerk.ClerkError catch (e) {
      _lastError = e.message;
      return SignUpResult.failure(e.message);
    } catch (e) {
      _lastError = e.toString();
      return SignUpResult.failure(e.toString());
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<SignInResult> verifyEmail(String code) async {
    _loading = true;
    _lastError = null;
    notifyListeners();
    try {
      await _auth.attemptSignUp(
        strategy: clerk.Strategy.emailCode,
        code: code,
      );
      return _auth.user != null
          ? SignInResult.success
          : SignInResult.failure('Verificación fallida');
    } on clerk.ClerkError catch (e) {
      _lastError = e.message;
      return SignInResult.failure(e.message);
    } catch (e) {
      _lastError = e.toString();
      return SignInResult.failure(e.toString());
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {}
    notifyListeners();
  }

  @override
  void dispose() {
    if (_initialized) _auth.terminate();
    super.dispose();
  }
}

// ── Result types ──────────────────────────────────────────────────────────────

class SignInResult {
  final bool ok;
  final String? error;
  const SignInResult._(this.ok, this.error);
  static const success = SignInResult._(true, null);
  factory SignInResult.failure(String msg) => SignInResult._(false, msg);
}

class SignUpResult {
  final bool ok;
  final bool needsEmailVerification;
  final String? error;
  const SignUpResult._(this.ok, this.needsEmailVerification, this.error);
  static const success = SignUpResult._(true, false, null);
  static const needsVerification = SignUpResult._(false, true, null);
  factory SignUpResult.failure(String msg) => SignUpResult._(false, false, msg);
}
