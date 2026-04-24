import 'package:flutter/material.dart';

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
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Agregar periodo",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period name
                  _label("NOMBRE DEL PERIODO"),
                  _input(
                    controller: nameController,
                    hint: "Ej. Ciclo 2024",
                  ),

                  const SizedBox(height: 24),

                  // Start date
                  _label("INICIO"),
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
                  _label("FIN"),
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

                  const SizedBox(height: 100),
                ],
              ),
            ),
            // Floating button
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFB483FF), Color(0xFF7A4BFF)],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF9D65FF),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: createPeriod,
                      borderRadius: BorderRadius.circular(28),
                      child: const Center(
                        child: Text(
                          "Añadir periodo",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }

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
}
