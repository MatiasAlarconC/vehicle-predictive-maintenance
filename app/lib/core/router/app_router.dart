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

      final isLoggingIn = state.matchedLocation == '/login';
      final isSelectingVehicle = state.matchedLocation == '/select-vehicle';
      final isSplash = state.matchedLocation == '/';

      if (isSplash) return null;

      if (!auth.isLoggedIn) {
        return isLoggingIn ? null : '/login';
      }

      if (!vehicle.hasVehicle) {
        return isSelectingVehicle ? null : '/select-vehicle';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/select-vehicle',
        builder: (context, state) => const CarSelectionScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/predict',
        builder: (context, state) => const PredictionScreen(),
      ),
    ],
  );
}
