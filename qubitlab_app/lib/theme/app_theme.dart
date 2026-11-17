import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const bg = Color(0xFFF1F1FC);
  static const ink = Color(0xFF111118);
  static const muted = Color(0xFF8A8AA0);
  static const indigo = Color(0xFF7C80F2);
  static const orange = Color(0xFFF2994A);
  static const purple = Color(0xFFA561D8);
  static const green = Color(0xFF4CC38A);
  static const pink = Color(0xFFEF6B9B);
  static const teal = Color(0xFF3CB8C9);
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.indigo),
      scaffoldBackgroundColor: AppColors.bg,
    );
    return base.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme)
          .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
    );
  }
}
