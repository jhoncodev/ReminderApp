import 'package:flutter/material.dart';
import 'package:reminder_app/core/theme/app_colors.dart';
import 'package:reminder_app/core/utils/app_feedback.dart';
import 'package:reminder_app/core/utils/date_helpers.dart';
import 'package:reminder_app/core/widgets/bottom_nav_bar.dart';
import 'package:reminder_app/core/widgets/status_views.dart';
import 'package:reminder_app/data/shared_item_repository.dart';
import 'package:reminder_app/models/shared_item.dart';

// Bandeja de compartidos: lo que otros usuarios me enviaron,
// pendiente de aceptar (se copia a mi cuenta) o rechazar (se descarta)
class ShareScreen extends StatefulWidget {
  const ShareScreen({super.key});

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  final _repo = SharedItemRepository();

  void _accept(SharedItem item) {
    _repo
        .accept(item)
        .catchError((e) => debugPrint("Error al aceptar compartido: $e"));
    showSuccessSnack(context, "${item.typeLabel} agregado a tu cuenta");
  }

  void _reject(SharedItem item) {
    _repo
        .reject(item)
        .catchError((e) => debugPrint("Error al rechazar compartido: $e"));
    showSuccessSnack(context, "Compartido descartado");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const BottomNavBar(currentRoute: '/share'),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 4),
              child: Text(
                "Compartidos",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                "Lo que te enviaron tus compañeros",
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<SharedItem>>(
                stream: _repo.watchInbox(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const AppLoadingView();
                  }
                  if (snapshot.hasError) {
                    return AppErrorView(
                      message: "No se pudieron cargar los compartidos",
                      error: snapshot.error,
                    );
                  }

                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return const _EmptyState();
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, index) => _SharedTile(
                      item: items[index],
                      onAccept: () => _accept(items[index]),
                      onReject: () => _reject(items[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
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
              Icons.inbox_outlined,
              color: AppColors.purplePrimary,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              "Nada por aquí",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Cuando un compañero te comparta un curso, apunte, recordatorio o periodo, aparecerá aquí para que lo aceptes.",
              style: TextStyle(color: AppColors.hint, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SharedTile extends StatelessWidget {
  final SharedItem item;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _SharedTile({
    required this.item,
    required this.onAccept,
    required this.onReject,
  });

  IconData get _icon {
    switch (item.type) {
      case 'course':
        return Icons.school;
      case 'note':
        return Icons.note_alt_outlined;
      case 'period':
        return Icons.calendar_month;
      case 'teacher':
        return Icons.person_outline;
      default:
        // Recordatorio: con micrófono si viaja con audio (grabado)
        return item.payload.containsKey('audioBase64')
            ? Icons.mic
            : Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icon, color: AppColors.purplePrimary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${item.typeLabel} • ${item.displayTitle}",
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
                      "De ${item.fromUserName} • ${formatShortDate(item.createdAt)}",
                      style: const TextStyle(
                        color: AppColors.hint,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onReject,
                child: const Text(
                  "Rechazar",
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.purplePrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: onAccept,
                child: const Text(
                  "Aceptar",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
