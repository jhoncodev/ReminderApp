import 'package:flutter/material.dart';
import 'package:reminder_app/core/theme/app_colors.dart';
import 'package:reminder_app/core/widgets/app_label.dart';
import 'package:reminder_app/core/widgets/app_text_field.dart';
import 'package:reminder_app/core/widgets/dark_app_bar.dart';
import 'package:reminder_app/core/widgets/primary_gradient_button.dart';
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
  List<String> days = ["L", "M", "M", "J", "V", "S", "D"];
  List<bool> selectedDays = List.generate(7, (_) => false);

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

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
      backgroundColor: AppColors.background,
      appBar: const DarkAppBar(title: "Crear Curso"),
      body: SafeArea(
        child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Course name
                  const AppLabel(text:"NOMBRE DEL CURSO"),
                  const SizedBox(height: 8),
                  AppTextField(
                    controller: nameController, 
                    hint: "Ej. Aplicaciones Móviles"
                  ),
                  const SizedBox(height: 24),

                  // Academic Period Section
                  _buildAcademicPeriodSection(),

                  const SizedBox(height: 24),

                  // Weekly Schedule Section
                  _buildWeeklyScheduleSection(),

                  const SizedBox(height: 50),
                  
                  // Button
                  PrimaryGradientButton(
                    text: "Crear Curso", 
                    onPressed: createCourse,
                    glow: true,
                  )
                ],
              ),
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
                const AppLabel(text:"PERIODO ACADÉMICO"),
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
          const AppLabel(text:"PERIODO"),
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
            const AppLabel(text:"HORARIO SEMANAL"),
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
