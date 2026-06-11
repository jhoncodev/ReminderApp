import 'package:flutter/material.dart';
import 'package:reminder_app/core/theme/app_colors.dart';

class AppLoadingView extends StatelessWidget{
  const AppLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(color: AppColors.purplePrimary),
    );
  }
}

class AppErrorView extends StatelessWidget{
  final String message;
  final Object? error; // detalle técnico en consola no en UI

  const AppErrorView({super.key, required this.message, this.error});

  @override
  Widget build(BuildContext context) {
    if (error != null) debugPrint('AppErrorView: $error');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, color: AppColors.hint, size: 48),
            const SizedBox(height: 12),
            
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            )
          ],
        ),
      ),
    );
  }
}