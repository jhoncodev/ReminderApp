import 'package:flutter/material.dart';
import 'package:reminder_app/core/theme/app_colors.dart';

class PrimaryGradientButton extends StatelessWidget{
  final String text;
  final VoidCallback? onPressed;
  final bool glow;

  const PrimaryGradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context){
    final isDisabled = onPressed == null;
      return Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: glow
                ? [
                    BoxShadow(
                      color: AppColors.purplePrimary.withValues(alpha: 0.6),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(28),
              child: Center(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
  }
}