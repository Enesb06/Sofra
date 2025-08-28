import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoadingAnimation extends StatelessWidget {
  final double size;

  const LoadingAnimation({
    super.key,
    this.size = 120.0, // Varsayılan boyut
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Lottie.asset(
        'assets/lottie/spoon_loading.json',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}