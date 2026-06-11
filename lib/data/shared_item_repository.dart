import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reminder_app/core/utils/audio_paths.dart';
import 'package:reminder_app/models/shared_item.dart';

class SharedItemRepository {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _currentUserId {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No hay usuario autenticado');
    return user.uid;
  }

  CollectionReference<SharedItem> get _ref => _firestore
      .collection('shared_items')
      .withConverter(
        fromFirestore: SharedItem.fromFirestore,
        toFirestore: (item, _) => item.toFirestore(),
      );

  // Busca el uid de un usuario por su correo. Null si no existe.
  // Requiere conexión (las reglas exigen limit(1) en esta query).
  Future<String?> findUserIdByEmail(String email) async {
    final snap = await _firestore
        .collection('users')
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.id;
  }

  // Envía una copia del recurso al destinatario
  Future<void> send({
    required String toUserId,
    required String fromUserName,
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    final item = SharedItem(
      fromUserId: _currentUserId,
      fromUserName: fromUserName,
      toUserId: toUserId,
      type: type,
      payload: payload,
      createdAt: DateTime.now(),
    );
    await _ref.add(item);
  }

  // Bandeja: lo que me compartieron y aún no acepto/rechazo
  Stream<List<SharedItem>> watchInbox() {
    return _ref
        .where('toUserId', isEqualTo: _currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  // Aceptar: crea la copia en MI colección correspondiente y borra el compartido
  Future<void> accept(SharedItem item) async {
    final data = Map<String, dynamic>.from(item.payload);

    // Audio compartido (recordatorio de voz): viaja como Base64 dentro del
    // payload y aquí se materializa como archivo local del receptor
    final audioBase64 = data.remove('audioBase64') as String?;
    if (audioBase64 != null) {
      final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final file = File(await reminderAudioPath(fileName));
      await file.writeAsBytes(base64Decode(audioBase64));
      data['audioFileName'] = fileName;
    }

    data['userId'] = _currentUserId;
    data['createdAt'] = Timestamp.now();
    data['updatedAt'] = Timestamp.now();

    await _firestore.collection(_collectionFor(item.type)).add(data);
    await _ref.doc(item.id).delete();
  }

  // Rechazar: solo se descarta el compartido
  Future<void> reject(SharedItem item) async {
    await _ref.doc(item.id).delete();
  }

  String _collectionFor(String type) {
    switch (type) {
      case 'course':
        return 'courses';
      case 'note':
        return 'notes';
      case 'period':
        return 'periods';
      case 'teacher':
        return 'teachers';
      default:
        return 'reminders';
    }
  }
}
