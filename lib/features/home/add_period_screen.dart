import 'package:flutter/material.dart';
import 'package:reminder_app/core/theme/app_colors.dart';
import 'package:reminder_app/core/widgets/app_label.dart';
import 'package:reminder_app/core/widgets/app_text_field.dart';
import 'package:reminder_app/core/widgets/dark_app_bar.dart';
import 'package:reminder_app/core/widgets/primary_gradient_button.dart';

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

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF9D65FF),
              surface: Color(0xFF232329),
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF1E1E1E),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        startDateController.text =
            "${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF9D65FF),
              surface: Color(0xFF232329),
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF1E1E1E),
            ) ,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        endDateController.text =
            "${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
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
                  GestureDetector(
                    onTap: () => _selectStartDate(context),
                    child: TextField(
                      controller: startDateController,
                      enabled: false,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "mm/dd/yyyy",
                        hintStyle: const TextStyle(color: Color(0xFF5A5A62)),
                        filled: true,
                        fillColor: const Color(0xFF232329),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: const Icon(
                          Icons.calendar_today,
                          color: Color(0xFF9D65FF),
                          size: 18,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // End date
                  const AppLabel(text:"FIN"),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _selectEndDate(context),
                    child: TextField(
                      controller: endDateController,
                      enabled: false,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "mm/dd/yyyy",
                        hintStyle: const TextStyle(color: Color(0xFF5A5A62)),
                        filled: true,
                        fillColor: const Color(0xFF232329),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: const Icon(
                          Icons.calendar_today,
                          color: Color(0xFF9D65FF),
                          size: 18,
                        ),
                      ),
                    ),
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
