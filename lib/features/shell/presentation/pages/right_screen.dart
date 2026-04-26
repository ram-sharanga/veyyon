import 'package:flutter/material.dart';
import 'package:veyyon/core/theme/app_text_styles.dart';

class RightScreen extends StatelessWidget {
  const RightScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('···', style: AppTextStyles.label)),
    );
  }
}
