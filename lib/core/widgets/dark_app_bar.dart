import 'package:flutter/material.dart';
import 'package:reminder_app/core/theme/app_colors.dart';

class DarkAppBar extends StatelessWidget implements PreferredSizeWidget{
  final String title;
  const DarkAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context), 
        icon: const Icon(Icons.arrow_back, color: Colors.white),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: false,
    );
  }
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}