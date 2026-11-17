import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/circuit_provider.dart';
import 'providers/saved_circuits_provider.dart';
import 'screens/app_shell.dart';
import 'screens/onboarding_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..boot()),
        ChangeNotifierProvider(create: (_) => CircuitProvider()),
        ChangeNotifierProvider(create: (_) => SavedCircuitsProvider()),
      ],
      child: const QubitLabApp(),
    ),
  );
}

class QubitLabApp extends StatelessWidget {
  const QubitLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QubitLab',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.booting) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    return auth.loggedIn ? const AppShell() : const OnboardingScreen();
  }
}
