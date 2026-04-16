import 'package:flutter/material.dart';

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
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Text(
                "NUEVA ENTRADA",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 8),
              const Text(
                "Crear Actividad",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 32),

              // Acitivity name
              _label("NOMBRE DE LA ACTIVIDAD"),
              _input(controller: nameController, hint: "Ej. Sesión de Yoga"),

              const SizedBox(height: 20),

              // Notes
              _label("NOTAS / DETALLES"),
              _input(
                controller: notesController,
                hint: "Detalles adicionales...",
                maxLines: 3,
              ),

              const SizedBox(height: 20),

              // Amount
              _label("PRESUPUESTO"),
              _input(
                controller: amountController,
                hint: "Monto (opcional)",
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 24),

              // Frequency
              _label("FRECUENCIA"),
              const SizedBox(height: 8),
              _frequencySelector(),

              const SizedBox(height: 20),

              // Days
              _label("DÍAS SELECCIONADOS"),
              const SizedBox(height: 8),
              _daysSelector(),

              const SizedBox(height: 32),

              // Create button
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFB483FF), Color(0xFF7A4BFF)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: ElevatedButton(
                  onPressed: createActivity,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                  child: const Text(
                    "Crear Actividad",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Labels
  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  // Inputs
  Widget _input({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF5A5A62)),
          filled: true,
          fillColor: const Color(0xFF232329),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
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

  // Days selector
  Widget _daysSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(days.length, (index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              selectedDays[index] = !selectedDays[index];
            });
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: selectedDays[index]
                  ? const Color(0xFF9D65FF)
                  : const Color(0xFF232329),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                days[index],
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        );
      }),
    );
  }
}