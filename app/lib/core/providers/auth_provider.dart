import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vehicle_predictive_maintenance_app/core/constants/clerk_config.dart';

/// Wraps clerk_auth's [clerk.Auth] as a [ChangeNotifier] Provider.
/// Handles sign-in, sign-up (with email verification), and sign-out.
class AuthProvider with ChangeNotifier {
  late clerk.Auth _auth;
  bool _initialized = false;
  bool _loading = false;
  bool _signedInManually = false;
  String? _lastError;
  String? _pendingMfaSignInId;
  String? _pendingMfaAuthToken;
  String? _pendingMfaClientId;
  String? _manualEmail;
  String? _manualFirstName;

  bool get isInitialized => _initialized;
  bool get isLoading => _loading;
  bool get isSignedIn => _initialized && (_auth.user != null || _signedInManually);
  clerk.User? get user => _initialized ? _auth.user : null;
  String get firstName => user?.firstName ?? _manualFirstName ?? _manualEmail?.split('@').first ?? '';
  String? get email => user?.email ?? _manualEmail;
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

  // Clerk FAPI base URL derived from publishable key
  static const _fapiBase = 'https://measured-lynx-42.clerk.accounts.dev/v1';

  Future<SignInResult> signIn(String email, String password) async {
    _loading = true;
    _lastError = null;
    notifyListeners();
    try {
      final dio = Dio(BaseOptions(
        contentType: 'application/x-www-form-urlencoded',
        validateStatus: (_) => true,
        headers: {
          'x-mobile': '1',
          'clerk-api-version': '2021-02-05',
        },
      ));

      // Step 1: create sign_in with just identifier → Clerk returns Authorization header
      final r1 = await dio.post(
        '$_fapiBase/client/sign_ins',
        data: {'identifier': email},
      );
      final r1data = r1.data is Map ? r1.data as Map : {};
      if (r1data['errors'] != null) {
        final msg = (r1data['errors'] as List).isNotEmpty
            ? ((r1data['errors'] as List).first['long_message'] ?? 'Error al iniciar sesión')
            : 'Error al iniciar sesión';
        return SignInResult.failure(msg.toString());
      }
      final signInId = r1data['response']?['id'] as String?;
      if (signInId == null) return SignInResult.failure('No se pudo crear la sesión');

      // Extract Authorization token Clerk returns for this client session
      final authToken = r1.headers.value('authorization');
      final clientId = (r1data['client'] as Map?)?['id'] as String?;

      // Step 2: attempt_first_factor with password, forwarding the client token
      final r2Headers = <String, dynamic>{
        'x-mobile': '1',
        'clerk-api-version': '2021-02-05',
        if (authToken != null) 'authorization': authToken,
        if (clientId != null) 'x-clerk-client-id': clientId,
      };
      final r2 = await dio.post(
        '$_fapiBase/client/sign_ins/$signInId/attempt_first_factor',
        data: {'strategy': 'password', 'password': password},
        options: Options(headers: r2Headers),
      );
      final r2data = r2.data is Map ? r2.data as Map : {};
      if (r2data['errors'] != null) {
        final msg = (r2data['errors'] as List).isNotEmpty
            ? ((r2data['errors'] as List).first['long_message'] ?? 'Credenciales incorrectas')
            : 'Credenciales incorrectas';
        return SignInResult.failure(msg.toString());
      }
      final status = r2data['response']?['status'] as String?;
      if (status == 'complete') {
        _signedInManually = true;
        _manualEmail = email;
        _manualFirstName = r2data['response']?['identifier'] as String?;
        notifyListeners();
        return SignInResult.success;
      }
      // MFA required — need email code as second factor
      if (status == 'needs_second_factor') {
        _manualEmail = email; // store now so it's available after MFA completes
        final signInId2 = r2data['response']?['id'] as String?;
        final authToken2 = r2.headers.value('authorization') ?? authToken;
        final clientId2 = (r2data['client'] as Map?)?['id'] as String? ?? clientId;
        // Prepare email code second factor
        final r2b = await dio.post(
          '$_fapiBase/client/sign_ins/$signInId2/prepare_second_factor',
          data: {'strategy': 'email_code'},
          options: Options(headers: {
            'x-mobile': '1',
            'clerk-api-version': '2021-02-05',
            if (authToken2 != null) 'authorization': authToken2,
            if (clientId2 != null) 'x-clerk-client-id': clientId2,
          }),
        );
        // Store tokens for the MFA step
        _pendingMfaSignInId = signInId2;
        _pendingMfaAuthToken = r2b.headers.value('authorization') ?? authToken2;
        _pendingMfaClientId = clientId2;
        return SignInResult.needsMfa;
      }
      return SignInResult.failure('Credenciales incorrectas');
    } catch (e) {
      _lastError = e.toString();
      return SignInResult.failure(e.toString());
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Submit MFA email code to complete sign-in
  Future<SignInResult> verifyMfa(String code) async {
    _loading = true;
    _lastError = null;
    notifyListeners();
    try {
      final dio = Dio(BaseOptions(
        contentType: 'application/x-www-form-urlencoded',
        validateStatus: (_) => true,
      ));
      final r = await dio.post(
        '$_fapiBase/client/sign_ins/$_pendingMfaSignInId/attempt_second_factor',
        data: {'strategy': 'email_code', 'code': code},
        options: Options(headers: {
          'x-mobile': '1',
          'clerk-api-version': '2021-02-05',
          if (_pendingMfaAuthToken != null) 'authorization': _pendingMfaAuthToken,
          if (_pendingMfaClientId != null) 'x-clerk-client-id': _pendingMfaClientId,
        }),
      );
      final rdata = r.data is Map ? r.data as Map : {};
      if (rdata['errors'] != null) {
        final msg = (rdata['errors'] as List).isNotEmpty
            ? (rdata['errors'] as List).first['long_message'] ?? 'Código incorrecto'
            : 'Código incorrecto';
        return SignInResult.failure(msg.toString());
      }
      if (rdata['response']?['status'] == 'complete') {
        _signedInManually = true;
        _pendingMfaSignInId = null;
        _pendingMfaAuthToken = null;
        _pendingMfaClientId = null;
        // _manualEmail already stored during signIn()
        notifyListeners();
        return SignInResult.success;
      }
      return SignInResult.failure('Código incorrecto');
    } catch (e) {
      _lastError = e.toString();
      return SignInResult.failure(e.toString());
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Step 1 of forgot-password: sends a reset code to [email].
  Future<SignInResult> sendPasswordResetCode(String email) async {
    _loading = true;
    _lastError = null;
    notifyListeners();
    try {
      await _auth.initiatePasswordReset(
        identifier: email,
        strategy: clerk.Strategy.resetPasswordEmailCode,
      );
      return SignInResult.success;
    } on clerk.ClerkError catch (e) {
      _lastError = e.toString();
      return SignInResult.failure(e.toString());
    } catch (e) {
      _lastError = e.toString();
      return SignInResult.failure(e.toString());
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Step 2 of forgot-password: verify [code] and set [newPassword].
  Future<SignInResult> completePasswordReset(
      String code, String newPassword) async {
    _loading = true;
    _lastError = null;
    notifyListeners();
    try {
      await _auth.attemptSignIn(
        strategy: clerk.Strategy.resetPasswordEmailCode,
        code: code,
        password: newPassword,
      );
      return _auth.user != null
          ? SignInResult.success
          : SignInResult.failure('No se pudo restablecer la contraseña');
    } on clerk.ClerkError catch (e) {
      _lastError = e.toString();
      return SignInResult.failure(e.toString());
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
      if (_auth.signUp == null) {
        return SignUpResult.failure('No se pudo crear la cuenta. Revisa tu conexión.');
      }
      // Disparar envío del código de verificación por email
      await _auth.attemptSignUp(strategy: clerk.Strategy.emailCode);
      return SignUpResult.needsVerification;
    } on clerk.ClerkError catch (e) {
      _lastError = e.toString();
      return SignUpResult.failure(e.toString());
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
      _lastError = e.toString();
      return SignInResult.failure(e.toString());
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
    _signedInManually = false;
    _manualEmail = null;
    _manualFirstName = null;
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
  final bool mfaRequired;
  final String? error;
  const SignInResult._(this.ok, this.mfaRequired, this.error);
  static const success = SignInResult._(true, false, null);
  static const needsMfa = SignInResult._(false, true, null);
  factory SignInResult.failure(String msg) => SignInResult._(false, false, msg);
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
