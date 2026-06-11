import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:reminder_app/core/theme/app_colors.dart';
import 'package:reminder_app/core/utils/app_feedback.dart';
import 'package:reminder_app/core/utils/date_helpers.dart';
import 'package:reminder_app/core/utils/time_helpers.dart';
import 'package:reminder_app/core/widgets/app_label.dart';
import 'package:reminder_app/core/widgets/app_text_field.dart';
import 'package:reminder_app/core/widgets/color_selector.dart';
import 'package:reminder_app/core/widgets/dark_app_bar.dart';
import 'package:reminder_app/core/widgets/primary_gradient_button.dart';
import 'package:reminder_app/core/widgets/session_editor_sheet.dart';
import 'package:reminder_app/data/course_repository.dart';
import 'package:reminder_app/data/period_repository.dart';
import 'package:reminder_app/models/course.dart';
import 'package:reminder_app/models/course_session.dart';
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
  final noteController = TextEditingController();
  int _selectedColor = 0xFF6C63FF;

  bool isAcademicPeriodEnabled = false;
  Period? selectedPeriod;
  List<CourseSession> _sessions = [];

  bool _isSaving = false;

  static const _dayNames = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  @override
  void initState() {
    super.initState();
    final existing = widget.course;
    if (existing == null) return;

    nameController.text = existing.name;
    noteController.text = existing.note ?? '';
    _sessions = List.from(existing.sessions);

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
    noteController.dispose();
    super.dispose();
  }

  Future<void> _addSession() async {
    final session = await SessionEditorSheet.show(context);
    if (session != null) {
      setState(() => _sessions.add(session));
    }
  }

  Future<void> _editSession(int index) async {
    final session = await SessionEditorSheet.show(
      context,
      initial: _sessions[index],
    );
    if (session != null) {
      setState(() => _sessions[index] = session);
    }
  }

  void _removeSession(int index) {
    setState(() => _sessions.removeAt(index));
  }

  Future<void> _saveCourse() async {
    if (_isSaving) return;

    final name = nameController.text.trim();
    if (name.isEmpty) {
      showErrorSnack(context, "El nombre es obligatorio");
      return;
    }

    if (_sessions.isEmpty) {
      showErrorSnack(context, "Agrega al menos una sesión");
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showErrorSnack(context, "No hay usuario autenticado");
      return;
    }

    final periodId = isAcademicPeriodEnabled ? selectedPeriod?.id : null;
    final note = noteController.text.trim().isEmpty
        ? null
        : noteController.text.trim();

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
          sessions: _sessions,
          note: note,
          colorCode: _selectedColor,
          createdAt: original.createdAt,
          updatedAt: now,
        );

        _courseRepo.update(updated).catchError((e) => debugPrint("Error al sincronizar el curso: $e"));
      } else {
        final newCourse = Course(
          userId: user.uid,
          academicPeriodId: periodId,
          name: name,
          sessions: _sessions,
          note: note,
          colorCode: _selectedColor,
          createdAt: now,
          updatedAt: now,
        );

        _courseRepo.create(newCourse).catchError((e) => debugPrint("Error al sincronizar el curso: $e"));
      }

      if (!mounted) return;
        widget.isEditing ? showSuccessSnack(context, "Curso actualizado correctamente") : showSuccessSnack(context, "Curso creado correctamente");
        Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
        showErrorSnack(context, "Error al guardar el curso");
        debugPrint("Error al guardar el curso: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
                          "${formatShortDate(period.startDate)} - ${formatShortDate(period.endDate)}",
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
              const AppLabel(text: "Nombre del Curso"),
              const SizedBox(height: 8),
              AppTextField(
                controller: nameController,
                hint: "Ej. Aplicaciones Móviles",
              ),
              const SizedBox(height: 24),

              _buildAcademicPeriodSection(),
              const SizedBox(height: 24),

              _buildSessionsSection(),
              const SizedBox(height: 24),

              _buildNoteSection(),
              const SizedBox(height: 24),

              ColorSelector(
                selectedColor: _selectedColor,
                onColorSelected: (newColor) {
                  setState(() {
                    _selectedColor = newColor;
                  });
                },
              ),
              const SizedBox(height: 40),

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
                AppLabel(text: "Período Académico"),
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
              "${formatShortDate(selectedPeriod!.startDate)} - ${formatShortDate(selectedPeriod!.endDate)}",
              style: const TextStyle(color: AppColors.hint, fontSize: 12),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildSessionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppLabel(text: "Sesiones"),
        const SizedBox(height: 4),
        const Text(
          "Días y horarios del curso",
          style: TextStyle(color: AppColors.hint, fontSize: 12),
        ),
        const SizedBox(height: 16),

        // Lista de sesiones existentes
        for (int i = 0; i < _sessions.length; i++) ...[
          _buildSessionCard(_sessions[i], i),
          const SizedBox(height: 12),
        ],

        // Botón "Agregar Sesión"
        _buildAddSessionButton(),
      ],
    );
  }

  Widget _buildSessionCard(CourseSession session, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _dayNames[session.dayOfWeek],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (session.roomName != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.inputFill,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          session.roomName!,
                          style: const TextStyle(
                            color: AppColors.hint,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatTo12h(session.startTime)} → ${formatTo12h(session.endTime)}',
                  style: const TextStyle(color: AppColors.hint, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _editSession(index),
            icon: const Icon(
              Icons.edit_outlined,
              color: AppColors.purplePrimary,
            ),
            tooltip: "Editar",
          ),
          IconButton(
            onPressed: () => _removeSession(index),
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: "Eliminar",
          ),
        ],
      ),
    );
  }

  Widget _buildAddSessionButton() {
    return GestureDetector(
      onTap: _addSession,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.purplePrimary.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, color: AppColors.purplePrimary),
            const SizedBox(width: 12),
            const Text(
              'Agregar Sesión',
              style: TextStyle(
                color: AppColors.purplePrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppLabel(text: "Apunte (Opcional)"),
        const SizedBox(height: 4),
        const Text(
          "Notas o información extra del curso",
          style: TextStyle(color: AppColors.hint, fontSize: 12),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: noteController,
          maxLines: 4,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Ej. Llevar laptop los miércoles",
            hintStyle: const TextStyle(color: AppColors.hint),
            filled: true,
            fillColor: AppColors.inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}
