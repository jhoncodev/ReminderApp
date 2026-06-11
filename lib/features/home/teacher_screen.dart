import 'package:flutter/material.dart';
import 'package:reminder_app/core/theme/app_colors.dart';
import 'package:reminder_app/core/utils/app_feedback.dart';
import 'package:reminder_app/core/widgets/dark_app_bar.dart';
import 'package:reminder_app/core/widgets/share_sheet.dart';
import 'package:reminder_app/core/widgets/status_views.dart';
import 'package:reminder_app/data/teacher_repository.dart';
import 'package:reminder_app/features/home/create_teacher_screen.dart';
import 'package:reminder_app/models/teacher.dart';

class TeacherScreen extends StatefulWidget {
  const TeacherScreen({super.key});

  @override
  State<TeacherScreen> createState() => _TeacherScreenState();
}

class _TeacherScreenState extends State<TeacherScreen> {
  final _repo = TeacherRepository();

  Future<void> _confirmDelete(Teacher teacher) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          "Eliminar profesor",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          "¿Seguro que deseas eliminar a \"${teacher.name}\"? Los cursos vinculados quedarán sin profesor.",
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
    if (teacher.id == null) return;

    _repo
        .delete(teacher.id!)
        .catchError((e) => debugPrint("Error al sincronizar la eliminación: $e"));
    if (!mounted) return;
    showSuccessSnack(context, "Profesor eliminado");
  }

  void _openCreate() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateTeacherScreen()),
    );
  }

  void _openEdit(Teacher teacher) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateTeacherScreen(teacher: teacher)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const DarkAppBar(title: "Profesores"),
      body: StreamBuilder<List<Teacher>>(
        stream: _repo.watchAll(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingView();
          }

          if (snapshot.hasError) {
            return AppErrorView(
              message: "No se pudieron cargar los profesores",
              error: snapshot.error,
            );
          }

          final teachers = snapshot.data ?? [];
          if (teachers.isEmpty) {
            return const _EmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: teachers.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, index) => _TeacherTile(
              teacher: teachers[index],
              onEdit: () => _openEdit(teachers[index]),
              onDelete: () => _confirmDelete(teachers[index]),
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
            Icon(Icons.person_outline, color: AppColors.purplePrimary, size: 64),
            SizedBox(height: 16),
            Text(
              "Aún no tienes profesores",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Toca el botón + para registrar a tu primer profesor y vincularlo a tus cursos.",
              style: TextStyle(color: AppColors.hint, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TeacherTile extends StatelessWidget {
  final Teacher teacher;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TeacherTile({
    required this.teacher,
    required this.onEdit,
    required this.onDelete,
  });

  String get _contactInfo {
    final parts = <String>[
      if (teacher.email != null && teacher.email!.isNotEmpty) teacher.email!,
      if (teacher.phone != null && teacher.phone!.isNotEmpty) teacher.phone!,
    ];
    return parts.isEmpty ? "Sin datos de contacto" : parts.join(" • ");
  }

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
                  teacher.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _contactInfo,
                  style: const TextStyle(color: AppColors.hint, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => showShareSheet(
              context,
              type: 'teacher',
              typeLabel: 'Profesor',
              resourceTitle: teacher.name,
              payload: teacherPayload(teacher),
            ),
            icon: const Icon(Icons.share_outlined, color: AppColors.cyan),
            tooltip: "Compartir",
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
