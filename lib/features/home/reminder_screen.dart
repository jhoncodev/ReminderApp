import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:reminder_app/core/theme/app_colors.dart';
import 'package:reminder_app/core/utils/app_feedback.dart';
import 'package:reminder_app/core/utils/audio_paths.dart';
import 'package:reminder_app/core/utils/date_helpers.dart';
import 'package:reminder_app/core/utils/time_helpers.dart';
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

  // Pestaña activa: false = Escritos, true = Grabados
  bool _showRecorded = false;

  // Un solo reproductor para toda la lista (tocar otro audio detiene el anterior)
  final _player = AudioPlayer();
  String? _playingId;

  // Nota de voz rápida: mantener presionado el + en Grabados graba sin formulario
  final _quickRecorder = AudioRecorder();
  bool _quickRecording = false;
  int _quickSeconds = 0;
  Timer? _quickTimer;
  String? _quickFileName;
  static const _maxQuickSeconds = 120;

  static const _dayLabels = ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"];

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingId = null);
    });
  }

  @override
  void dispose() {
    _quickTimer?.cancel();
    _quickRecorder.dispose();
    _player.dispose();
    super.dispose();
  }

  // ── Nota de voz rápida ────────────────────────────────────────────────────

  Future<void> _startQuickRecording() async {
    if (_quickRecording) return;
    if (!await _quickRecorder.hasPermission()) {
      if (mounted) showErrorSnack(context, "Permiso de micrófono denegado");
      return;
    }

    await _player.stop(); // no grabar mientras suena un audio
    final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
    final path = await reminderAudioPath(fileName);
    // Calidad voz (32 kbps mono): permite compartir el audio por Firestore
    await _quickRecorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 32000,
        sampleRate: 22050,
        numChannels: 1,
      ),
      path: path,
    );

    if (!mounted) return;
    setState(() {
      _quickRecording = true;
      _quickSeconds = 0;
      _quickFileName = fileName;
      _playingId = null;
    });

    _quickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _quickSeconds++);
      if (_quickSeconds >= _maxQuickSeconds) _finishQuickRecording();
    });
  }

  Future<void> _finishQuickRecording() async {
    if (!_quickRecording) return;
    _quickTimer?.cancel();
    await _quickRecorder.stop();

    final fileName = _quickFileName;
    final seconds = _quickSeconds;
    if (mounted) setState(() => _quickRecording = false);
    if (fileName == null) return;

    // Soltó demasiado rápido: toque accidental, se descarta
    if (seconds < 1) {
      deleteReminderAudio(fileName);
      if (mounted) {
        showErrorSnack(context, "Mantén presionado el botón para grabar");
      }
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      deleteReminderAudio(fileName);
      return;
    }

    // Se guarda SIN programar (sin fecha): al editarla después,
    // el formulario exigirá la fecha y recién ahí entra al Home/notificaciones
    final now = DateTime.now();
    final hour = formatTo12h(formatTo24h(TimeOfDay.fromDateTime(now)));
    final voiceNote = Reminder(
      userId: user.uid,
      name: "Nota de voz ${formatShortDate(now)} $hour",
      frequency: 'Una vez',
      scheduleDays: const [],
      createdAt: now,
      updatedAt: now,
      audioFileName: fileName,
    );
    _repo
        .create(voiceNote)
        .catchError((e) => debugPrint("Error al sincronizar nota de voz: $e"));

    if (mounted) {
      showSuccessSnack(context, "Nota de voz guardada, edítala para programarla");
    }
  }

  String _formatSeconds(int seconds) {
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // Compartir: si es grabado, el audio viaja en el payload como Base64
  // (límite de Firestore: 1 MB por doc; base64 infla ~33%, de ahí los 700 KB)
  Future<void> _shareReminder(Reminder reminder) async {
    final payload = reminderPayload(reminder);

    if (reminder.audioFileName != null) {
      try {
        final file = File(await reminderAudioPath(reminder.audioFileName!));
        final bytes = await file.readAsBytes();
        if (bytes.length > 700 * 1024) {
          if (mounted) {
            showErrorSnack(context, "Este audio es muy pesado para compartir");
          }
          return;
        }
        payload['audioBase64'] = base64Encode(bytes);
      } catch (e) {
        debugPrint("Error al leer el audio para compartir: $e");
        if (mounted) {
          showErrorSnack(context, "No se encontró el audio en este dispositivo");
        }
        return;
      }
    }

    if (!mounted) return;
    showShareSheet(
      context,
      type: 'reminder',
      typeLabel: reminder.isRecorded ? 'Recordatorio de Voz' : 'Recordatorio',
      resourceTitle: reminder.name,
      payload: payload,
    );
  }

  Future<void> _togglePlay(Reminder reminder) async {
    if (reminder.audioFileName == null) return;

    if (_playingId == reminder.id) {
      await _player.stop();
      if (mounted) setState(() => _playingId = null);
      return;
    }

    try {
      final path = await reminderAudioPath(reminder.audioFileName!);
      await _player.stop();
      await _player.play(DeviceFileSource(path));
      if (mounted) setState(() => _playingId = reminder.id);
    } catch (e) {
      debugPrint("Error al reproducir el audio: $e");
      if (mounted) {
        showErrorSnack(context, "No se encontró el audio en este dispositivo");
      }
    }
  }

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
      // El audio local ya no tiene dueño: se borra también
      if (reminder.audioFileName != null) {
        if (_playingId == reminder.id) _player.stop();
        deleteReminderAudio(reminder.audioFileName!);
      }
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
      MaterialPageRoute(
        // El + crea según la pestaña activa: escrito o grabado
        builder: (_) => CreateReminderScreen(audioMode: _showRecorded),
      ),
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

  // Pestañas Escritos | Grabados (mismo estilo que el selector de frecuencia)
  Widget _buildTypeTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          _typeTab("Escritos", false),
          const SizedBox(width: 8),
          _typeTab("Grabados", true),
        ],
      ),
    );
  }

  Widget _typeTab(String label, bool recorded) {
    final selected = _showRecorded == recorded;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _showRecorded = recorded),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.purplePrimary : AppColors.inputFill,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                recorded ? Icons.mic : Icons.edit_note,
                size: 18,
                color: selected ? Colors.white : Colors.grey,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const DarkAppBar(title: "Recordatorios"),
      body: Column(
        children: [
          _buildTypeTabs(),
          if (_quickRecording)
            Container(
              margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.15),
                border: Border.all(color: Colors.redAccent),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mic, color: Colors.redAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Grabando nota de voz... ${_formatSeconds(_quickSeconds)}",
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Text(
                    "Suelta para guardar",
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            )
          else if (_showRecorded)
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Text(
                "Tip: mantén presionado el botón + para grabar una nota de voz rápida",
                style: TextStyle(color: AppColors.hint, fontSize: 12),
              ),
            ),
          Expanded(
            child: StreamBuilder<List<Reminder>>(
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

                final reminders = (snapshot.data ?? [])
                    .where((r) => r.isRecorded == _showRecorded)
                    .toList();
                if (reminders.isEmpty) {
                  return _EmptyState(recorded: _showRecorded);
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: reminders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, index) => _ReminderTile(
                    reminder: reminders[index],
                    formatDays: _formatDays,
                    isPlaying: _playingId == reminders[index].id,
                    onPlay: () => _togglePlay(reminders[index]),
                    onShare: () => _shareReminder(reminders[index]),
                    onEdit: () => _openEdit(reminders[index]),
                    onDelete: () => _confirmDelete(reminders[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _showRecorded
          ? _buildQuickRecordFab()
          : FloatingActionButton(
              backgroundColor: AppColors.purplePrimary,
              foregroundColor: Colors.white,
              onPressed: _openCreate,
              child: const Icon(Icons.add),
            ),
    );
  }

  // FAB dual de Grabados: toque corto = formulario completo;
  // mantener presionado = grabar nota de voz rápida (soltar = guardar)
  Widget _buildQuickRecordFab() {
    return GestureDetector(
      onTap: _quickRecording ? null : _openCreate,
      onLongPressStart: (_) => _startQuickRecording(),
      onLongPressEnd: (_) => _finishQuickRecording(),
      onLongPressCancel: _finishQuickRecording,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: _quickRecording ? Colors.redAccent : AppColors.purplePrimary,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          _quickRecording ? Icons.mic : Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool recorded;
  const _EmptyState({this.recorded = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              recorded ? Icons.mic_none : Icons.check_circle,
              color: AppColors.purplePrimary,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              recorded
                  ? "Aún no tienes recordatorios grabados"
                  : "Aún no tienes recordatorios",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              recorded
                  ? "Toca el botón + para grabar tu primer recordatorio de voz."
                  : "Toca el botón + para crear tu primer recordatorio.",
              style: const TextStyle(color: AppColors.hint, fontSize: 14),
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
  final bool isPlaying;
  final VoidCallback onPlay;
  final VoidCallback onShare;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReminderTile({
    required this.reminder,
    required this.formatDays,
    required this.isPlaying,
    required this.onPlay,
    required this.onShare,
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
          if (reminder.isRecorded)
            IconButton(
              onPressed: onPlay,
              icon: Icon(
                isPlaying ? Icons.stop_circle : Icons.play_circle_fill,
                color: AppColors.green,
                size: 30,
              ),
              tooltip: isPlaying ? "Detener" : "Escuchar",
            ),
          IconButton(
            onPressed: onShare,
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
