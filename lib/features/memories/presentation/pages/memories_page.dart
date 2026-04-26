import 'package:flutter/material.dart';
import 'package:veyyon/core/theme/app_text_styles.dart';

class MemoriesPage extends StatelessWidget {
  const MemoriesPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('MEMORIES', style: AppTextStyles.label)),
    );
  }
}
