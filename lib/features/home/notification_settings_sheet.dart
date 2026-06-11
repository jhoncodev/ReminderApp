import 'package:flutter/material.dart';
import 'package:reminder_app/core/theme/app_colors.dart';
import 'package:reminder_app/core/utils/app_feedback.dart';
import 'package:reminder_app/core/widgets/primary_gradient_button.dart';
import 'package:reminder_app/services/notification_service.dart';

// Config de avisos (se abre desde la campana del Home):
// lista de "X min antes" que se pueden agregar o quitar.
// Vacía = notificaciones apagadas.
void showNotificationSettingsSheet(
  BuildContext context,
  List<int> currentLeadTimes,
) {
  final leadTimes = List<int>.from(currentLeadTimes);
  const options = [5, 10, 15, 30, 60];

  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheetState) {
        final available =
            options.where((o) => !leadTimes.contains(o)).toList();

        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Notificaciones",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Recibe avisos antes de cada curso o recordatorio con hora. Sin avisos = notificaciones apagadas.",
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
              const SizedBox(height: 24),

              if (leadTimes.isEmpty)
                const Text(
                  "Sin avisos configurados",
                  style: TextStyle(color: AppColors.hint, fontSize: 14),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final lead in leadTimes)
                      Chip(
                        backgroundColor: AppColors.purplePrimary,
                        label: Text(
                          "$lead min antes",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        deleteIcon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                        onDeleted: () {
                          setSheetState(() => leadTimes.remove(lead));
                        },
                      ),
                  ],
                ),

              if (available.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  "Agregar aviso",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final option in available)
                      ActionChip(
                        backgroundColor: AppColors.inputFill,
                        side: const BorderSide(color: Colors.white12),
                        label: Text(
                          "+ $option min",
                          style: const TextStyle(color: Colors.white70),
                        ),
                        onPressed: () {
                          setSheetState(() {
                            leadTimes.add(option);
                            leadTimes.sort((a, b) => b.compareTo(a));
                          });
                        },
                      ),
                  ],
                ),
              ],

              const SizedBox(height: 28),
              PrimaryGradientButton(
                text: "Guardar",
                glow: true,
                onPressed: () async {
                  final service = NotificationService.instance;

                  // Pedir el permiso solo si hay avisos que mostrar
                  var granted = true;
                  if (leadTimes.isNotEmpty) {
                    granted = await service.requestPermission();
                  }

                  service.saveLeadTimes(leadTimes);

                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                  if (!context.mounted) return;
                  if (leadTimes.isNotEmpty && !granted) {
                    showErrorSnack(
                      context,
                      "Permiso denegado: activa las notificaciones en Ajustes del sistema",
                    );
                  } else {
                    showSuccessSnack(context, "Avisos guardados");
                  }
                },
              ),
            ],
          ),
        );
      },
    ),
  );
}
