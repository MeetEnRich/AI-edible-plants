import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'services/sync_service.dart';
import 'services/gemini_service.dart';

import 'screens/splash_screen.dart';
import 'screens/auth_screens.dart';
import 'screens/dashboard_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/result_screen.dart';
import 'screens/herbarium_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/encyclopedia_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProxyProvider<AuthService, SyncService>(
          create: (_) => SyncService()..startMonitoring(),
          update: (_, auth, syncService) =>
              syncService!..updateUser(auth.currentUser?.id),
        ),
        Provider(create: (_) => GeminiService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FloraID Nigeria',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/scan': (context) => const ScanScreen(),
        '/herbarium': (context) => const HerbariumScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/encyclopedia': (context) => const EncyclopediaScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/result') {
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => const ResultScreen(),
          );
        }
        return null;
      },
    );
  }
}
