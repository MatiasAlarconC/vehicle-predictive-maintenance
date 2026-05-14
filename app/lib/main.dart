import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vehicle_predictive_maintenance_app/app/theme/app_theme.dart';
import 'package:vehicle_predictive_maintenance_app/core/providers/app_provider.dart';
import 'package:vehicle_predictive_maintenance_app/core/providers/auth_provider.dart';
import 'package:vehicle_predictive_maintenance_app/core/providers/diagnostics_provider.dart';
import 'package:vehicle_predictive_maintenance_app/core/providers/history_provider.dart';
import 'package:vehicle_predictive_maintenance_app/core/providers/prediction_provider.dart';
import 'package:vehicle_predictive_maintenance_app/core/providers/vehicle_provider.dart';
import 'package:vehicle_predictive_maintenance_app/core/router/app_router.dart';

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
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => VehicleProvider()),
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()..loadHistory()),
        ChangeNotifierProxyProvider<AppProvider, DiagnosticsProvider>(
          create: (_) => DiagnosticsProvider(),
          update: (_, appProvider, diagnosticsProvider) {
            final provider = diagnosticsProvider ?? DiagnosticsProvider();
            provider.updateConfig(appProvider);
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => PredictionProvider()),
      ],
      child: const VehicleMaintenanceApp(),
    ),
  );
}

class VehicleMaintenanceApp extends StatefulWidget {
  const VehicleMaintenanceApp({super.key});

  @override
  State<VehicleMaintenanceApp> createState() => _VehicleMaintenanceAppState();
}

class _VehicleMaintenanceAppState extends State<VehicleMaintenanceApp> {
  // El router se inicializa una sola vez en didChangeDependencies
  // (no en initState porque necesita context con providers)
  late final _router = AppRouter.createRouter(context);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Vera',
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
