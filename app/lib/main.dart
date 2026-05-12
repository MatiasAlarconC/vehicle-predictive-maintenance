import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vehicle_predictive_maintenance_app/core/providers/app_provider.dart';
import 'package:vehicle_predictive_maintenance_app/core/providers/diagnostics_provider.dart';
import 'package:vehicle_predictive_maintenance_app/core/providers/prediction_provider.dart';
import 'package:vehicle_predictive_maintenance_app/core/router/app_router.dart';
import 'package:vehicle_predictive_maintenance_app/app/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => DiagnosticsProvider()),
        ChangeNotifierProvider(create: (_) => PredictionProvider()),
      ],
      child: const VehicleMaintenanceApp(),
    ),
  );
}

class VehicleMaintenanceApp extends StatelessWidget {
  const VehicleMaintenanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Vehicle Diagnostics',
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
