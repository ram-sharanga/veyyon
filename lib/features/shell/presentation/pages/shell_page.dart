import 'package:flutter/material.dart';
import 'center_screen.dart';
import 'right_screen.dart';
import 'package:veyyon/features/memories/presentation/pages/memories_page.dart';

class ShellPage extends StatefulWidget {
  const ShellPage({super.key});
  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  final _controller = PageController(initialPage: 1);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _controller,
      children: const [MemoriesPage(), CenterScreen(), RightScreen()],
    );
  }
}
