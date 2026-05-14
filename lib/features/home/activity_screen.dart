import 'package:flutter/material.dart';
import 'package:reminder_app/core/theme/app_colors.dart';
import 'package:reminder_app/core/widgets/dark_app_bar.dart';

class ActivityScreen extends StatelessWidget{
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      appBar: DarkAppBar(title: "Actividades"),
    );
  }
}