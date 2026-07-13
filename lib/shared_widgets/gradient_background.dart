import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;
  final Color? baseColor;
  final double opacity;

  const GradientBackground({
    super.key,
    required this.child,
    this.baseColor,
    this.opacity = 0.4,
  });

  @override
  Widget build(BuildContext context) {
    final color = baseColor ?? AppColors.accent;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withOpacity(opacity),
            AppColors.background,
          ],
          stops: const [0.0, 0.4],
        ),
      ),
      child: child,
    );
  }
}
