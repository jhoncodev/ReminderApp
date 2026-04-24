import 'package:flutter/material.dart';
import 'package:reminder_app/features/home/add_period_screen.dart';

class CreateCourseScreen extends StatefulWidget {
  const CreateCourseScreen({super.key});

  @override
  State<CreateCourseScreen> createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends State<CreateCourseScreen> {
  final TextEditingController nameController = TextEditingController();

  bool isAcademicPeriodEnabled = false;
  bool isWeeklyScheduleEnabled = false;
  AcademicPeriod? selectedPeriod;
  List<String> days = ["L", "M", "X", "J", "V", "S", "D"];
  List<bool> selectedDays = List.generate(7, (_) => false);

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  // Abre un bottom sheet con los periodos disponibles + opción para crear uno nuevo
  Future<void> _openPeriodSelector() async {
    final result = await showModalBottomSheet<AcademicPeriod>(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Selecciona un periodo",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...AcademicPeriod.all.map(
                  (period) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      period.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      "${period.startDate} - ${period.endDate}",
                      style: const TextStyle(color: Color(0xFF5A5A62)),
                    ),
                    onTap: () => Navigator.pop(context, period),
                  ),
                ),
                const Divider(color: Color(0xFF232329)),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.add, color: Color(0xFF9D65FF)),
                  title: const Text(
                    "Crear nuevo periodo",
                    style: TextStyle(
                      color: Color(0xFF9D65FF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final newPeriod = await Navigator.push<AcademicPeriod>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddPeriodScreen(),
                      ),
                    );
                    if (newPeriod != null) {
                      setState(() => selectedPeriod = newPeriod);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result != null) {
      setState(() => selectedPeriod = result);
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
                        color: const Color(0xFF9D65FF).withValues(alpha: 0.6),
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
                  "Selecciona el ciclo al que pertenece este curso",
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
                  setState(() {
                    isAcademicPeriodEnabled = value;
                    if (!value) selectedPeriod = null;
                  });
                },
                activeThumbColor: const Color(0xFF9D65FF),
              ),
            ),
          ],
        ),
        if (isAcademicPeriodEnabled) ...[
          const SizedBox(height: 16),
          _label("PERIODO"),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _openPeriodSelector,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFF232329),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedPeriod?.name ?? "Selecciona un periodo",
                      style: TextStyle(
                        color: selectedPeriod != null
                            ? Colors.white
                            : const Color(0xFF5A5A62),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFF9D65FF),
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
          if (selectedPeriod != null) ...[
            const SizedBox(height: 8),
            Text(
              "${selectedPeriod!.startDate} - ${selectedPeriod!.endDate}",
              style: const TextStyle(
                color: Color(0xFF5A5A62),
                fontSize: 12,
              ),
            ),
          ],
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
                activeThumbColor: const Color(0xFF9D65FF),
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
