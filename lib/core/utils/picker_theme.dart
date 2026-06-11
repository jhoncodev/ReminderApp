import 'package:flutter/material.dart';
import 'package:reminder_app/core/theme/app_colors.dart';

// Tema oscuro compartido para showDatePicker y showTimePicker.
// Fuerza formato 12h (AM/PM) en los selectores de hora.

Widget buildDarkPicker(BuildContext context, Widget? child) {
  return Theme(
    data: ThemeData.dark().copyWith(
      colorScheme: const ColorScheme.dark(
        primary: AppColors.purplePrimary,
        surface: AppColors.surface,
      ),
      dialogTheme: const DialogThemeData(backgroundColor: AppColors.surface),
      timePickerTheme: const TimePickerThemeData(
          dayPeriodColor: AppColors.purplePrimary,
          dayPeriodTextColor: Colors.white,
        ),
    ),
    child: MediaQuery(
      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
      child: child!,
    ),
  );
}
