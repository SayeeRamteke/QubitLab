import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Widget _orbit(double deg, double r, Color color, IconData icon) {
    final a = deg * math.pi / 180;
    return Positioned(
      left: 150 + r * math.cos(a) - 20,
      top: 150 + r * math.sin(a) - 20,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _ring(double size) => Center(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _ring(260),
                        _ring(170),
                        Center(
                          child: Container(
                            width: 96,
                            height: 96,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [AppColors.indigo, AppColors.purple],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [BoxShadow(color: Color(0x667C80F2), blurRadius: 40)],
                            ),
                            child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 48),
                          ),
                        ),
                        _orbit(200, 130, AppColors.orange, Icons.blur_circular_rounded),
                        _orbit(300, 130, AppColors.green, Icons.science_rounded),
                        _orbit(30, 130, AppColors.pink, Icons.emoji_events_rounded),
                        _orbit(120, 130, AppColors.teal, Icons.auto_graph_rounded),
                        _orbit(250, 85, AppColors.indigo, Icons.link_rounded),
                        _orbit(70, 85, AppColors.purple, Icons.tune_rounded),
                      ],
                    ),
                  ),
                ),
              ),
              const Text(
                'Learn quantum computing, anywhere',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Build circuits, watch qubits come alive, and beat the Arena.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  child: const Text('Get Started',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
