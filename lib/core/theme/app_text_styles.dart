import 'package:flutter/material.dart';
import 'package:veyyon/core/theme/app_colors.dart';

class AppTextStyles {
  AppTextStyles._();
  static const mono = TextStyle(
    fontFamily: 'JetBrainsMono',
    color: AppColors.text,
  );
  static const label = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.text3,
    letterSpacing: 4,
  );
}
