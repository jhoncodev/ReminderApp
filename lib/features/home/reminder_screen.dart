import 'package:flutter/material.dart';
import 'package:reminder_app/core/theme/app_colors.dart';
import 'package:reminder_app/core/utils/app_feedback.dart';
import 'package:reminder_app/core/widgets/dark_app_bar.dart';
import 'package:reminder_app/core/widgets/share_sheet.dart';
import 'package:reminder_app/core/widgets/status_views.dart';
import 'package:reminder_app/data/reminder_repository.dart';
import 'package:reminder_app/features/home/create_reminder_screen.dart';
import 'package:reminder_app/models/reminder.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  final _repo = ReminderRepository();

  static const _dayLabels = ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"];

  String _formatDays(List<int> days) {
    if (days.isEmpty) return "Sin días";
    return days.map((d) => _dayLabels[d]).join(", ");
  }

  Future<void> _confirmDelete(Reminder reminder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          "Eliminar recordatorio",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          "¿Seguro que deseas eliminar \"${reminder.name}\"? Esta acción no se puede deshacer.",
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
    if (reminder.id == null) return;

    try {
      _repo
          .delete(reminder.id!)
          .catchError(
            (e) => debugPrint("Error al sincronizar la eliminación: $e"),
          );
      if (!mounted) return;
      showSuccessSnack(context, "Recordatorio eliminado");
    } catch (e) {
      if (!mounted) return;
      showErrorSnack(context, "Error al eliminar el recordatorio");
      debugPrint("Error al eliminar el recordatorio: $e");
    }
  }

  void _openCreate() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateReminderScreen()),
    );
  }

  void _openEdit(Reminder reminder) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateReminderScreen(reminder: reminder),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const DarkAppBar(title: "Recordatorios"),
      body: StreamBuilder<List<Reminder>>(
        stream: _repo.watchAll(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingView();
          }

          if (snapshot.hasError) {
            return AppErrorView(
              message: "No se pudieron cargar los recordatorios",
              error: snapshot.error,
            );
          }

          final reminders = snapshot.data ?? [];
          if (reminders.isEmpty) {
            return const _EmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: reminders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, index) => _ReminderTile(
              reminder: reminders[index],
              formatDays: _formatDays,
              onEdit: () => _openEdit(reminders[index]),
              onDelete: () => _confirmDelete(reminders[index]),
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
            Icon(Icons.check_circle, color: AppColors.purplePrimary, size: 64),
            SizedBox(height: 16),
            Text(
              "Aún no tienes recordatorios",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Toca el botón + para crear tu primer recordatorio.",
              style: TextStyle(color: AppColors.hint, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  final Reminder reminder;
  final String Function(List<int>) formatDays;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReminderTile({
    required this.reminder,
    required this.formatDays,
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
                  reminder.name,
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
                  "${reminder.frequency} • ${formatDays(reminder.scheduleDays)}",
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
              type: 'reminder',
              typeLabel: 'Recordatorio',
              resourceTitle: reminder.name,
              payload: reminderPayload(reminder),
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
