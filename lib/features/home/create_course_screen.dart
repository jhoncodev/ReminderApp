import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:reminder_app/core/theme/app_colors.dart';
import 'package:reminder_app/core/widgets/app_label.dart';
import 'package:reminder_app/core/widgets/app_text_field.dart';
import 'package:reminder_app/core/widgets/dark_app_bar.dart';
import 'package:reminder_app/core/widgets/days_selector.dart';
import 'package:reminder_app/core/widgets/primary_gradient_button.dart';
import 'package:reminder_app/data/course_repository.dart';
import 'package:reminder_app/data/period_repository.dart';
import 'package:reminder_app/models/course.dart';
import 'package:reminder_app/models/period.dart';

class CreateCourseScreen extends StatefulWidget {
  final Course? course;
  const CreateCourseScreen({super.key, this.course});

  bool get isEditing => course != null;

  @override
  State<CreateCourseScreen> createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends State<CreateCourseScreen> {
  final _courseRepo = CourseRepository();
  final _periodRepo = PeriodRepository();
  final nameController = TextEditingController();

  bool isAcademicPeriodEnabled = false;
  Period? selectedPeriod;
  List<bool> selectedDays = List.generate(7, (_) => false);

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.course;
    if (existing == null) return;

    nameController.text = existing.name;

    // Dias prellenados
    for (final day in existing.scheduleDays) {
      if (day >= 0 && day < selectedDays.length) {
        selectedDays[day] = true;
      }
    }

    if (existing.academicPeriodId != null) {
      isAcademicPeriodEnabled = true;
      _periodRepo.getById(existing.academicPeriodId!).then((period) {
        if (!mounted) return;
        setState(() => selectedPeriod = period);
      });
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return "$m/$d/${date.year}";
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openPeriodSelector() async {
    final result = await showModalBottomSheet<Period>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: StreamBuilder<List<Period>>(
            stream: _periodRepo.watchAll(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.purplePrimary,
                    ),
                  ),
                );
              }

              final periods = snapshot.data ?? [];

              return Column(
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
                  if (periods.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        "Aún no tienes periodos creados. Ve a Periodos para crear uno.",
                        style: TextStyle(color: AppColors.hint),
                      ),
                    )
                  else
                    ...periods.map(
                      (period) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          period.name,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          "${_formatDate(period.startDate)} - ${_formatDate(period.endDate)}",
                          style: const TextStyle(color: AppColors.hint),
                        ),
                        onTap: () => Navigator.pop(ctx, period),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );

    if (result != null) {
      setState(() => selectedPeriod = result);
    }
  }

  Future<void> _saveCourse() async {
    if (_isSaving) return;

    final name = nameController.text.trim();
    if (name.isEmpty) {
      _showSnack("El nombre es obligatorio");
      return;
    }

    // Se debe validar que al menos un día se haya seleccionado
    final scheduleDays = <int>[];
    for (var i = 0; i < selectedDays.length; i++) {
      if (selectedDays[i]) scheduleDays.add(i);
    }
    if (scheduleDays.isEmpty) {
      _showSnack("Selecciona al menos un día de la semana");
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnack("No hay usuario autenticado");
      return;
    }

    final periodId = isAcademicPeriodEnabled ? selectedPeriod?.id : null;

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();

      if (widget.isEditing) {
        final original = widget.course!;
        final updated = Course(
          id: original.id,
          userId: original.userId,
          academicPeriodId: periodId,
          name: name,
          scheduleDays: scheduleDays,
          createdAt: original.createdAt,
          updatedAt: now,
        );
        await _courseRepo.update(updated);
      } else {
        final newCourse = Course(
          userId: user.uid,
          academicPeriodId: periodId,
          name: name,
          scheduleDays: scheduleDays,
          createdAt: now,
          updatedAt: now,
        );
        await _courseRepo.create(newCourse);
      }

      if (!mounted) return;
      _showSnack(
        widget.isEditing
            ? "Curso actualizado correctamente"
            : "Curso creado correctamente",
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showSnack("Error al guardar: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing ? "Editar Curso" : "Crear Curso";
    final buttonText = widget.isEditing ? "Guardar Cambios" : "Crear Curso";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: DarkAppBar(title: title),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppLabel(text: "NOMBRE DEL CURSO"),
              const SizedBox(height: 8),
              AppTextField(
                controller: nameController,
                hint: "Ej. Aplicaciones Móviles",
              ),
              const SizedBox(height: 24),

              _buildAcademicPeriodSection(),
              const SizedBox(height: 24),

              _buildWeeklyScheduleSection(),
              const SizedBox(height: 50),

              PrimaryGradientButton(
                text: _isSaving ? "Guardando..." : buttonText,
                onPressed: _isSaving ? null : _saveCourse,
                glow: true,
              ),
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
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppLabel(text: "PERIODO ACADÉMICO"),
                SizedBox(height: 4),
                Text(
                  "Selecciona el ciclo al que pertenece este curso",
                  style: TextStyle(color: AppColors.hint, fontSize: 12),
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
                activeThumbColor: AppColors.purplePrimary,
              ),
            ),
          ],
        ),
        if (isAcademicPeriodEnabled) ...[
          const SizedBox(height: 16),
          const AppLabel(text: "PERIODO"),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _openPeriodSelector,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
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
                            : AppColors.hint,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.purplePrimary,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
          if (selectedPeriod != null) ...[
            const SizedBox(height: 8),
            Text(
              "${_formatDate(selectedPeriod!.startDate)} - ${_formatDate(selectedPeriod!.endDate)}",
              style: const TextStyle(color: AppColors.hint, fontSize: 12),
            ),
          ],
        ],
      ],
    );
  }

  // Selector de dias siempre visible
  Widget _buildWeeklyScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppLabel(text: "HORARIO SEMANAL"),
        const SizedBox(height: 4),
        const Text(
          "Selecciona los días en que se imparte el curso",
          style: TextStyle(color: AppColors.hint, fontSize: 12),
        ),
        const SizedBox(height: 16),
        DaysSelector(
          selectedDays: selectedDays,
          onSelectionChanged: (updatedDays) {
            setState(() => selectedDays = updatedDays);
          },
        ),
      ],
    );
  }
}
