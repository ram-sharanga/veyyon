import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/shell/presentation/pages/shell_page.dart';

void main() => runApp(const DayWheelApp());

class DayWheelApp extends StatelessWidget {
  const DayWheelApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const ShellPage(),
    );
  }
}