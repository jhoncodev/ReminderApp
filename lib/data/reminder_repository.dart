import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reminder_app/models/reminder.dart';

class ReminderRepository {
  
  // Creamos la referencia a la colección 'reminders' en firestore
  // con withConverter, todas las consultas nos devolverán objetos
  // de tipo Reminder
  final CollectionReference<Reminder> _remindersRef = FirebaseFirestore.instance
  .collection('reminders')
  .withConverter(
    fromFirestore: Reminder.fromFirestore,
    toFirestore: (reminder, _) => reminder.toFirestore(),
  );

  // Se devuelve el uid del usuario con sesión iniciada y
  // si no existe se lanza una excepción
  String get _currentUserId {
    final user = FirebaseAuth.instance.currentUser;
    if(user == null){
      throw Exception('No hay usuario autenticado');
    }
    return user.uid;
  }

  // Stream (Escucha en tiempo real a firestore) con todas los recordatorios del
  // usuario actual, mostrando de arriba abajo por fecha de creación
  Stream<List<Reminder>> watchAll(){
    return _remindersRef
    .where('userId', isEqualTo: _currentUserId)
    .orderBy('createdAt', descending: true)
    .snapshots()
    .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Método para crear un nuevo recordatorio, firestore genera el id
  // que es el documento automaticamente
  Future<void> create(Reminder reminder) async {
    await _remindersRef.add(reminder);
  }

  // Método para actualizar un recordatorio por completo, se requiere que la
  // recordatorio tenga id
  Future<void> update(Reminder reminder) async {
    if(reminder.id == null){
      throw Exception('No se puede actualizar un recordatorio sin id');
    }

    await _remindersRef.doc(reminder.id).set(reminder);
  }

  // Método para eliminar un recordatorio por id
  Future<void> delete(String id) async {
    await _remindersRef.doc(id).delete();
  }

  // Método para obtener un recordatorio por su id
  Future<Reminder?> getById(String id) async {
    final snapshot = await _remindersRef.doc(id).get();
    return snapshot.data();
  }
}
