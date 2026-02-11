import 'package:flutter/material.dart';

class BackgroundScaffold extends StatelessWidget {
  final Widget child;

  const BackgroundScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image (Placeholder)
          // In a real scenario, use: Image.asset('assets/images/background.jpg', fit: BoxFit.cover),
          // Background Image
          Image.asset('assets/images/background.jpg', fit: BoxFit.cover),
          // Dark Overlay
          Container(color: Colors.black.withValues(alpha: 0.5)),
          // Content
          SafeArea(child: child),
        ],
      ),
    );
  }
}
