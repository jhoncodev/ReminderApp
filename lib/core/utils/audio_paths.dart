import 'dart:io';

import 'package:path_provider/path_provider.dart';

// Los audios de recordatorios grabados viven en el almacenamiento
// privado de la app: <documentos>/reminder_audios/<nombre>.m4a
Future<String> reminderAudioPath(String fileName) async {
  final docs = await getApplicationDocumentsDirectory();
  final folder = Directory('${docs.path}/reminder_audios');
  if (!await folder.exists()) {
    await folder.create(recursive: true);
  }
  return '${folder.path}/$fileName';
}

// Borra el archivo de audio si existe (al eliminar o re-grabar)
Future<void> deleteReminderAudio(String fileName) async {
  final file = File(await reminderAudioPath(fileName));
  if (await file.exists()) {
    await file.delete();
  }
}
