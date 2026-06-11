import 'package:flutter/material.dart';
import 'package:reminder_app/core/theme/app_colors.dart';
import 'package:reminder_app/features/home/reminder_screen.dart';
import 'package:reminder_app/features/home/course_screen.dart';
import 'package:reminder_app/features/home/period_screen.dart';
import 'package:reminder_app/features/home/teacher_screen.dart';
import 'package:reminder_app/features/note/notes_screen.dart';

class CreateOptionsSheet {
  CreateOptionsSheet._();

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _SheetContent(),
    );
  }
}

class _SheetContent extends StatelessWidget {
  const _SheetContent();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "¿Qué deseas gestionar?",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            _OptionCard(
              icon: Icons.event_note,
              iconBackground: AppColors.cyan,
              title: "Recordatorio",
              subtitle: "Exámenes, prácticas, reuniones, mensualidades",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReminderScreen()),
                );
              },
            ),
            const SizedBox(height: 16),

            _OptionCard(
              icon: Icons.school,
              iconBackground: AppColors.purplePrimary,
              title: "Curso",
              subtitle: "Clases, horarios, materias",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CourseScreen()),
                );
              },
            ),
            const SizedBox(height: 16),

            _OptionCard(
              icon: Icons.note_add,
              iconBackground: AppColors.green,
              title: "Notas",
              subtitle: "Notas libres o asociadas a cursos",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotesScreen()),
                );
              },
            ),

            const SizedBox(height: 16),

            _OptionCard(
              icon: Icons.calendar_month,
              iconBackground: AppColors.orange,
              title: "Periodo",
              subtitle: "Ciclos académicos, semestres",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PeriodScreen()),
                );
              },
            ),
            const SizedBox(height: 16),

            _OptionCard(
              icon: Icons.person,
              iconBackground: AppColors.pink,
              title: "Profesor",
              subtitle: "Tus docentes, vinculables a cursos",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TeacherScreen()),
                );
              },
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    "Cancelar",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.purplePrimary.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),

                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.hint, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.hint),
          ],
        ),
      ),
    );
  }
}
