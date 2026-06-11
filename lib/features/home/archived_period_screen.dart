import 'package:flutter/material.dart';
import 'package:reminder_app/core/theme/app_colors.dart';
import 'package:reminder_app/core/utils/app_feedback.dart';
import 'package:reminder_app/core/utils/date_helpers.dart';
import 'package:reminder_app/core/widgets/dark_app_bar.dart';
import 'package:reminder_app/core/widgets/status_views.dart';
import 'package:reminder_app/data/period_repository.dart';
import 'package:reminder_app/models/period.dart';

class ArchivedPeriodScreen extends StatefulWidget {
  const ArchivedPeriodScreen({super.key});

  @override
  State<ArchivedPeriodScreen> createState() => _ArchivedPeriodScreenState();
}

class _ArchivedPeriodScreenState extends State<ArchivedPeriodScreen> {
  final _repo = PeriodRepository();

  Future<void> _confirmUnarchive(Period period) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          "Restaurar periodo",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          "¿Desarchivas \"${period.name}\"?",
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
              "Restaurar",
              style: TextStyle(color: AppColors.purplePrimary),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _repo.unarchive(period);
      if (!mounted) return;
        showSuccessSnack(context, "Periodo restaurado");
    } catch (e) {
      if (!mounted) return;
        showErrorSnack(context, "Error al restaurar el periodo");
        debugPrint("Error al restaurar el periodo: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const DarkAppBar(title: "Periodos Archivados"),
      body: StreamBuilder<List<Period>>(
        stream: _repo.watchArchived(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingView();
          }

          if (snapshot.hasError) {
            return AppErrorView(
              message: "No se pudieron cargar las calificaciones",
              error: snapshot.error,
            );
          }

          final periods = snapshot.data ?? [];
          if (periods.isEmpty) {
            return const _EmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: periods.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, index) => _ArchivedPeriodTile(
              period: periods[index],
              formatDate: formatShortDate,
              onUnarchive: () => _confirmUnarchive(periods[index]),
            ),
          );
        },
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
            Icon(
              Icons.archive_outlined,
              color: AppColors.purplePrimary,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              "Sin periodos archivados",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Los periodos que archives aparecerán aquí.",
              style: TextStyle(color: AppColors.hint, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ArchivedPeriodTile extends StatelessWidget {
  final Period period;
  final String Function(DateTime) formatDate;
  final VoidCallback onUnarchive;

  const _ArchivedPeriodTile({
    required this.period,
    required this.formatDate,
    required this.onUnarchive,
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
                  period.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${formatDate(period.startDate)} - ${formatDate(period.endDate)}",
                  style: const TextStyle(color: AppColors.hint, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onUnarchive,
            icon: const Icon(
              Icons.unarchive_outlined,
              color: AppColors.purplePrimary,
            ),
            tooltip: "Restaurar",
          ),
        ],
      ),
    );
  }
}
