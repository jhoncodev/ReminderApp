import 'package:flutter/material.dart';
import 'package:reminder_app/core/theme/app_colors.dart';
import 'package:reminder_app/core/widgets/app_label.dart';
import 'package:reminder_app/core/widgets/app_text_field.dart';
import 'package:reminder_app/core/widgets/dark_app_bar.dart';
import 'package:reminder_app/core/widgets/primary_gradient_button.dart';
import 'package:reminder_app/core/widgets/days_selector.dart';

class CreateActivityScreen extends StatefulWidget {
  const CreateActivityScreen({super.key});

  @override
  State<CreateActivityScreen> createState() => _CreateActivityScreenState();
}

class _CreateActivityScreenState extends State<CreateActivityScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController amountController = TextEditingController();

  String frequency = "Una vez";
  List<String> days = ["L", "M", "M", "J", "V", "S", "D"];
  List<bool> selectedDays = List.generate(7, (_) => false);

  @override
  void dispose() {
    nameController.dispose();
    notesController.dispose();
    amountController.dispose();
    super.dispose();
  }

  void createActivity() {
    final name = nameController.text;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El nombre es obligatorio")),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Actividad creada correctamente")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const DarkAppBar(title: "Crear Actividad"),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Acitivity name
              const AppLabel(text:"NOMBRE DE LA ACTIVIDAD"),
              const SizedBox(height: 8),
              AppTextField(
                controller: nameController, 
                hint: "Ej. Sesión de Yoga"
              ),

              const SizedBox(height: 20),

              // Notes
              const AppLabel(text:"NOTAS / DETALLES"),
              const SizedBox(height: 8),
              AppTextField(
                controller: notesController, 
                hint: "Detalles adicionales ...",
                maxLines: 3,
              ),

              const SizedBox(height: 20),

              // Amount
              const AppLabel(text:"PRESUPUESTO"),
              const SizedBox(height: 8),
              AppTextField(
                controller: amountController, 
                hint: "Monto (opcional)",
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 24),

              // Frequency
              const AppLabel(text:"FRECUENCIA"),
              const SizedBox(height: 8),
              _frequencySelector(),

              const SizedBox(height: 20),

              // Days
              const AppLabel(text:"DÍAS SELECCIONADOS"),
              const SizedBox(height: 8),
              DaysSelector(
                selectedDays: selectedDays,
                onSelectionChanged: (updatedDays) {
                  setState(() {
                    selectedDays = updatedDays;
                  });
                },
              ),

              const SizedBox(height: 32),

              // Create button
              PrimaryGradientButton(
                text: "Crear Actividad", 
                onPressed: createActivity,
                glow: true,
              )
            ],
          ),
        ),
      ),
    );
  }

  // Frequency selector
  Widget _frequencySelector() {
    final options = ["Una vez", "Diario", "Semanal", "Mensual"];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: options.map((e) {
        final selected = frequency == e;

        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() => frequency = e);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF9D65FF) : const Color(0xFF232329),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  e,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

}