import 'package:go_router/go_router.dart';
import 'package:vehicle_predictive_maintenance_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:vehicle_predictive_maintenance_app/features/diagnostics/screens/diagnostics_screen.dart';
import 'package:vehicle_predictive_maintenance_app/features/history/screens/history_screen.dart';
import 'package:vehicle_predictive_maintenance_app/features/prediction/screens/prediction_screen.dart';
import 'package:vehicle_predictive_maintenance_app/features/splash/screens/splash_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/predict',
        builder: (context, state) => const PredictionScreen(),
      ),
      GoRoute(
        path: '/diagnostics',
        builder: (context, state) => const DiagnosticsScreen(),
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const HistoryScreen(),
      ),
    ],
  );
}
