import 'package:flutter/material.dart';
import 'package:billing_app/core/theme/app_theme.dart';

class GestockLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const GestockLogo({super.key, this.size = 72, this.color});

  @override
  Widget build(BuildContext context) {
    final logoColor = color ?? AppTheme.primaryColor;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            logoColor,
            logoColor.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: logoColor.withValues(alpha: 0.35),
            blurRadius: size * 0.25,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.inventory_2_rounded,
            size: size * 0.48,
            color: Colors.white,
          ),
          Positioned(
            right: size * 0.12,
            top: size * 0.12,
            child: Container(
              padding: EdgeInsets.all(size * 0.02),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
                size: size * 0.22,
                color: logoColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
