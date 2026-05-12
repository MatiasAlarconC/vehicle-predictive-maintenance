import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:vehicle_predictive_maintenance_app/core/providers/auth_provider.dart';
import 'package:vehicle_predictive_maintenance_app/core/providers/vehicle_provider.dart';
import 'package:vehicle_predictive_maintenance_app/features/auth/screens/login_screen.dart';
import 'package:vehicle_predictive_maintenance_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:vehicle_predictive_maintenance_app/features/prediction/screens/prediction_screen.dart';
import 'package:vehicle_predictive_maintenance_app/features/splash/screens/splash_screen.dart';
import 'package:vehicle_predictive_maintenance_app/features/vehicle/screens/car_selection_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final auth = context.read<AuthProvider>();
      final vehicle = context.read<VehicleProvider>();

      final loc = state.matchedLocation;
      if (loc == '/') return null;

      // Still initializing Clerk — wait at splash
      if (!auth.isInitialized) return '/';

      if (!auth.isSignedIn) {
        return loc == '/login' ? null : '/login';
      }

      if (!vehicle.hasVehicle) {
        return loc == '/select-vehicle' ? null : '/select-vehicle';
      }

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
}
