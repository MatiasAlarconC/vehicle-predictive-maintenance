import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:vehicle_predictive_maintenance_app/core/providers/auth_provider.dart';
import 'package:vehicle_predictive_maintenance_app/core/providers/vehicle_provider.dart';
import 'package:vehicle_predictive_maintenance_app/features/auth/screens/login_screen.dart';
import 'package:vehicle_predictive_maintenance_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:vehicle_predictive_maintenance_app/features/prediction/screens/prediction_screen.dart';
import 'package:vehicle_predictive_maintenance_app/features/splash/screens/splash_screen.dart';
import 'package:vehicle_predictive_maintenance_app/features/vehicle/screens/car_selection_screen.dart';

/// Combina AuthProvider + VehicleProvider en un solo ChangeNotifier para que
/// GoRouter re-evalúe el redirect automáticamente cuando cambia cualquiera.
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(AuthProvider auth, VehicleProvider vehicle) {
    auth.addListener(notifyListeners);
    vehicle.addListener(notifyListeners);
  }
}

class AppRouter {
  /// Router global reutilizable (inicializado con createRouter).
  static late GoRouter router;

  static GoRouter createRouter(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final vehicle = context.read<VehicleProvider>();
    final notifier = _RouterNotifier(auth, vehicle);

    router = GoRouter(
      initialLocation: '/',
      refreshListenable: notifier,
      redirect: (ctx, state) {
        final loc = state.matchedLocation;
        if (loc == '/') return null;

        if (!auth.isInitialized) return '/';

        if (!auth.isSignedIn) {
          return loc == '/login' ? null : '/login';
        }

        if (!vehicle.hasVehicle) {
          return loc == '/select-vehicle' ? null : '/select-vehicle';
        }

        // Ya autenticado con vehículo — no redirigir a login/splash
        if (loc == '/login' || loc == '/') return '/dashboard';

        return null;
      },
      routes: [
        GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/select-vehicle', builder: (_, __) => const CarSelectionScreen()),
        GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
        GoRoute(path: '/predict', builder: (_, __) => const PredictionScreen()),
      ],
    );
    return router;
  }
}
