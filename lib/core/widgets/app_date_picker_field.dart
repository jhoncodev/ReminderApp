import 'package:flutter/material.dart';
import 'package:reminder_app/core/theme/app_colors.dart';

class AppDatePickerField extends StatelessWidget {
  final TextEditingController controller;

  const AppDatePickerField({
    super.key,
    required this.controller,
  });

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.purplePrimary,
            surface: AppColors.surface,
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: AppColors.surface,
          ),
        ), 
        child: child!,
      )
    );

    if (picked != null) {
      controller.text = "${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: AnimatedBuilder(
        animation: controller, 
        builder: (_, _){
          final hasValue = controller.text.isNotEmpty;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hasValue ? controller.text: "mm/dd/yyyy",
                    style: TextStyle(
                      color: hasValue ? Colors.white : AppColors.hint,
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_today,
                  color: AppColors.purplePrimary,
                  size: 18,
                )
              ],
            ),
          );
        }
      )
    );
  }
}
