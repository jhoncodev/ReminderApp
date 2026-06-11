import 'package:flutter/material.dart';
import 'package:reminder_app/core/theme/app_colors.dart';

void showSuccessSnack(BuildContext context, String message){
  _showSnack(context, message, AppColors.success, Icons.check_circle_outline);
}

void showErrorSnack(BuildContext context, String message){
  _showSnack(context, message, AppColors.error, Icons.error_outline);
}

void _showSnack(BuildContext context, String message, Color color, IconData icon){
  ScaffoldMessenger.of(context)
  ..hideCurrentSnackBar()
  ..showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: color,
      content: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.white))
          )
        ],
      ),
    )
  );
}