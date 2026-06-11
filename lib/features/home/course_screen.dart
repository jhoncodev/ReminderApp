import 'package:flutter/material.dart';
import 'package:reminder_app/core/theme/app_colors.dart';
import 'package:reminder_app/core/utils/app_feedback.dart';
import 'package:reminder_app/core/utils/time_helpers.dart';
import 'package:reminder_app/core/widgets/dark_app_bar.dart';
import 'package:reminder_app/core/widgets/status_views.dart';
import 'package:reminder_app/data/course_repository.dart';
import 'package:reminder_app/features/grade/grade_screen.dart';
import 'package:reminder_app/features/home/create_course_screen.dart';
import 'package:reminder_app/models/course.dart';
import 'package:reminder_app/models/course_session.dart';

class CourseScreen extends StatefulWidget {
  const CourseScreen({super.key});

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
  final _repo = CourseRepository();

  static const _dayLabels = ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"];

  String _formatSessions(List<CourseSession> sessions) {
    if (sessions.isEmpty) return "Sin sesiones";
    return sessions.map((s) => '${_dayLabels[s.dayOfWeek]} ${_formatHourShort(s.startTime)} - ${_formatHourShort(s.endTime)}').join(", ");
  }

  String _formatHourShort(String time24h) {
    final formatted = formatTo12h(time24h); // "2:30 PM" o "2:00 PM"
    // Si los minutos son ":00", los omitimos: "2 PM"
    return formatted.replaceAll(':00', '');
  }

  Future<void> _confirmDelete(Course course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          "Eliminar curso",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          "¿Seguro que deseas eliminar \"${course.name}\"? Esta acción no se puede deshacer.",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              "Cancelar",
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "Eliminar",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (course.id == null) return;

    try {
      await _repo.delete(course.id!);
      if (!mounted) return;
        showSuccessSnack(context, "Curso eliminado");
    } catch (e) {
      if (!mounted) return;
        showErrorSnack(context, "Error al eliminar el curso");
        debugPrint("Error al eliminar el curso: $e");
    }
  }

  void _openCreate() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateCourseScreen()),
    );
  }

  void _openEdit(Course course) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateCourseScreen(course: course)),
    );
  }

  void _openGrades(Course course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            GradeScreen(courseId: course.id!, courseName: course.name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const DarkAppBar(title: "Cursos"),
      body: StreamBuilder<List<Course>>(
        stream: _repo.watchAll(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingView();
          }

          if (snapshot.hasError) {
            return AppErrorView(
              message: "No se pudieron cargar los cursos",
              error: snapshot.error,
            );
          }

          final courses = snapshot.data ?? [];
          if (courses.isEmpty) {
            return const _EmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: courses.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, index) => _CourseTile(
              course: courses[index],
              formatSessions: _formatSessions,
              onViewGrades: () => _openGrades(courses[index]),
              onEdit: () => _openEdit(courses[index]),
              onDelete: () => _confirmDelete(courses[index]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.purplePrimary,
        foregroundColor: Colors.white,
        onPressed: _openCreate,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school, color: AppColors.purplePrimary, size: 64),
            SizedBox(height: 16),
            Text(
              "Aún no tienes cursos",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Toca el botón + para crear tu primer curso.",
              style: TextStyle(color: AppColors.hint, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseTile extends StatelessWidget {
  final Course course;
  final String Function(List<CourseSession>) formatSessions;
  final VoidCallback onViewGrades;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CourseTile({
    required this.course,
    required this.formatSessions,
    required this.onViewGrades,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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
                Text(
                  course.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatSessions(course.sessions),
                  style: const TextStyle(color: AppColors.hint, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onViewGrades,
            icon: const Icon(Icons.grading, color: AppColors.purplePrimary),
            tooltip: "Calificaciones",
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(
              Icons.edit_outlined,
              color: AppColors.purplePrimary,
            ),
            tooltip: "Editar",
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: "Eliminar",
          ),
        ],
      ),
    );
  }
}
