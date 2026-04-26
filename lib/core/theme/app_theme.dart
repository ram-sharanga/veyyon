import 'package:flutter/material.dart';
import 'package:veyyon/core/theme/app_colors.dart';

class AppTheme {
  AppTheme._();
  static ThemeData get dark => ThemeData.dark().copyWith(
    scaffoldBackgroundColor: AppColors.black,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      surface: AppColors.surface,
    ),
  );
}
