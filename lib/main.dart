import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/catatan_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/penduduk_provider.dart';
import 'providers/keluarga_provider.dart';
import 'providers/dasawisma_provider.dart';
import 'providers/rekapitulasi_provider.dart';
import 'providers/reference_provider.dart';
import 'services/connectivity_service.dart';
import 'screens/auth/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SiEdaApp());
}

class SiEdaApp extends StatelessWidget {
  const SiEdaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services
        ChangeNotifierProvider(create: (_) => ConnectivityService()),

        // State providers
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => PendudukProvider()),
        ChangeNotifierProvider(create: (_) => KeluargaProvider()),
        ChangeNotifierProvider(create: (_) => DasawismaProvider()),
        ChangeNotifierProvider(create: (_) => RekapitulasiProvider()),
        ChangeNotifierProvider(create: (_) => ReferenceProvider()),
        ChangeNotifierProvider(create: (_) => CatatanProvider()),
      ],
      child: MaterialApp(
        title: 'SIEDA',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
