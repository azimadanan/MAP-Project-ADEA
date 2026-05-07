import 'package:flutter/material.dart';

/// LoadingOverlay — Fullscreen semi-transparent overlay with centered spinner
/// Used as a Stack layer on top of screens during async operations
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF185FA5),
                strokeWidth: 3,
              ),
            ),
          ),
      ],
    );
  }
}
