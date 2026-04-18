import 'package:flutter/material.dart';

class CreateCourseScreen extends StatefulWidget {
  const CreateCourseScreen({super.key});

  @override
  State<CreateCourseScreen> createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends State<CreateCourseScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController academicPeriodNameController =
      TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();

  bool isAcademicPeriodEnabled = false;
  bool isWeeklyScheduleEnabled = false;
  List<String> days = ["L", "M", "X", "J", "V", "S", "D"];
  List<bool> selectedDays = List.generate(7, (_) => false);

  @override
  void dispose() {
    nameController.dispose();
    academicPeriodNameController.dispose();
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
            dialogBackgroundColor: const Color(0xFF1E1E1E),
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
            dialogBackgroundColor: const Color(0xFF1E1E1E),
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

  void createCourse() {
    final name = nameController.text;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El nombre es obligatorio")),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Curso creado correctamente")),
    );

    Navigator.pop(context);
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
          "Diseña tu itinerario.",
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
                  // Course name
                  _label("NOMBRE DEL CURSO"),
                  _input(
                    controller: nameController,
                    hint: "Ej. Matemáticas",
                  ),

                  const SizedBox(height: 24),

                  // Academic Period Section
                  _buildAcademicPeriodSection(),

                  const SizedBox(height: 24),

                  // Weekly Schedule Section
                  _buildWeeklyScheduleSection(),

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
                        color: const Color(0xFF9D65FF).withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: createCourse,
                      borderRadius: BorderRadius.circular(28),
                      child: const Center(
                        child: Text(
                          "Añadir curso",
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

  Widget _buildAcademicPeriodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label("PERIODO ACADÉMICO"),
                const SizedBox(height: 4),
                const Text(
                  "Limitar a 3 ciclos mayúsculos (p. ej. Ciclo 2024)",
                  style: TextStyle(
                    color: Color(0xFF5A5A62),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: isAcademicPeriodEnabled,
                onChanged: (value) {
                  setState(() => isAcademicPeriodEnabled = value);
                },
                activeColor: const Color(0xFF9D65FF),
              ),
            ),
          ],
        ),
        if (isAcademicPeriodEnabled) ...[
          const SizedBox(height: 16),
          _label("NOMBRE DEL PERIODO"),
          _input(
            controller: academicPeriodNameController,
            hint: "Ej. Ciclo 2024",
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "INICIO",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
              const SizedBox(height: 16),
              const Text(
                "FIN",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildWeeklyScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _label("HORARIO SEMANAL"),
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: isWeeklyScheduleEnabled,
                onChanged: (value) {
                  setState(() => isWeeklyScheduleEnabled = value);
                },
                activeColor: const Color(0xFF9D65FF),
              ),
            ),
          ],
        ),
        if (isWeeklyScheduleEnabled) ...[
          const SizedBox(height: 16),
          _daysSelector(),
        ],
      ],
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: selectedDays[index]
                  ? const Color(0xFF9D65FF)
                  : const Color(0xFF232329),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                days[index],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
