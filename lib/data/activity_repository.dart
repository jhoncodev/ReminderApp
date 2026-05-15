import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reminder_app/models/activity.dart';

class ActivityRepository {
  
  // Creamos la referencia a la colección 'activities' en firestore
  // con withConverter, todas las consultas nos devolverán objetos
  // de tipo Activity
  final CollectionReference<Activity> _activitiesRef = FirebaseFirestore.instance
  .collection('activities')
  .withConverter(
    fromFirestore: Activity.fromFirestore,
    toFirestore: (activity, _) => activity.toFirestore(),
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

  // Stream (Escucha en tiempo real a firestore) con todas las actividades del
  // usuario actual, mostrando de arriba abajo por fecha de creación
  Stream<List<Activity>> watchAll(){
    return _activitiesRef
    .where('userId', isEqualTo: _currentUserId)
    .orderBy('createdAt', descending: true)
    .snapshots()
    .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Método para crear una nueva actividad, firestore genera el id
  // que es el documento automaticamente
  Future<void> create(Activity activity) async {
    await _activitiesRef.add(activity);
    
  }

  // Método para actualizar una actividad por completo, se requiere que la
  // actividad tenga id
  Future<void> update(Activity activity) async {
    if(activity.id == null){
      throw Exception('No se puede actualizar una actividad sin id');
    }

    await _activitiesRef.doc(activity.id).set(activity);
  }

  // Método para eliminar una actividad por id
  Future<void> delete(String id) async {
    await _activitiesRef.doc(id).delete();
  }

  // Método para obtener una actividad por su id
  Future<Activity?> getById(String id) async {
    final snapshot = await _activitiesRef.doc(id).get();
    return snapshot.data();
  }
}
