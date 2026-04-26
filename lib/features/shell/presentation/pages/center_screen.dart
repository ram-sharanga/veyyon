import 'package:flutter/material.dart';
import 'package:veyyon/core/theme/app_text_styles.dart';

class CenterScreen extends StatelessWidget {
  const CenterScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('TODAY', style: AppTextStyles.label)),
    );
  }
}
