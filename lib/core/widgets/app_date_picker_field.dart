import 'package:flutter/material.dart';
import 'package:reminder_app/core/theme/app_colors.dart';
import 'package:reminder_app/core/utils/picker_theme.dart';

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
      builder: buildDarkPicker,
    );

    if (picked != null) {
      controller.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
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
                    hasValue ? controller.text: "dd/mm/aaaa",
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
