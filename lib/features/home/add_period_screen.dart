import 'package:flutter/material.dart';
import 'package:reminder_app/core/theme/app_colors.dart';
import 'package:reminder_app/core/widgets/app_label.dart';
import 'package:reminder_app/core/widgets/app_text_field.dart';
import 'package:reminder_app/core/widgets/dark_app_bar.dart';
import 'package:reminder_app/core/widgets/primary_gradient_button.dart';
import 'package:reminder_app/core/widgets/app_date_picker_field.dart';

// Modelo simple del periodo académico
class AcademicPeriod {
  final String name;
  final String startDate;
  final String endDate;

  AcademicPeriod({
    required this.name,
    required this.startDate,
    required this.endDate,
  });

  // Lista estática en memoria con un periodo preregistrado
  static List<AcademicPeriod> all = [
    AcademicPeriod(
      name: "Ciclo 2024-A",
      startDate: "03/01/2024",
      endDate: "07/31/2024",
    ),
  ];
}

class AddPeriodScreen extends StatefulWidget {
  const AddPeriodScreen({super.key});

  @override
  State<AddPeriodScreen> createState() => _AddPeriodScreenState();
}

class _AddPeriodScreenState extends State<AddPeriodScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    startDateController.dispose();
    endDateController.dispose();
    super.dispose();
  }



  void createPeriod() {
    final name = nameController.text;
    final startDate = startDateController.text;
    final endDate = endDateController.text;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El nombre es obligatorio")),
      );
      return;
    }

    if (startDate.isEmpty || endDate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecciona las fechas de inicio y fin")),
      );
      return;
    }

    final newPeriod = AcademicPeriod(
      name: name,
      startDate: startDate,
      endDate: endDate,
    );

    AcademicPeriod.all.add(newPeriod);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Periodo creado correctamente")),
    );

    Navigator.pop(context, newPeriod);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const DarkAppBar(title: "Crear Periodo"),
      body: SafeArea(
        child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period name
                  const AppLabel(text:"NOMBRE DEL PERIODO"),
                  
                  const SizedBox(height: 8),
                  AppTextField(
                    controller: nameController, 
                    hint: "Ej. Ciclo 2024"
                  ),

                  const SizedBox(height: 24),

                  // Start date
                  const AppLabel(text:"INICIO"),
                  const SizedBox(height: 8),
                  AppDatePickerField(
                    controller: startDateController,
                    label: "Fecha de inicio",
                  ),

                  const SizedBox(height: 20),

                  // End date
                  const AppLabel(text:"FIN"),
                  const SizedBox(height: 8),
                  AppDatePickerField(
                    controller: endDateController,
                    label: "Fecha de fin",
                  ),

                  // Button
                  const SizedBox(height: 50),
                  PrimaryGradientButton(
                    text: "Crear Periodo", 
                    onPressed: createPeriod,
                    glow: true,
                  )
                ],
              ),
            ),
        ),
      );
  }
}
