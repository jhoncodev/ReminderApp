import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reminder_app/models/teacher.dart';

class TeacherRepository {
  // Se crea la referencia a la colección 'teachers' en firestore
  // con withConverter, todas las consultas nos devolverán objetos
  // del tipo Teacher
  final CollectionReference<Teacher> _teachersRef = FirebaseFirestore.instance
      .collection('teachers')
      .withConverter(
        fromFirestore: Teacher.fromFirestore,
        toFirestore: (teacher, _) => teacher.toFirestore(),
      );

  // Se devuelve el uid del usuario con sesión iniciada y
  // si no existe se lanza una excepción
  String get _currentUserId {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No hay usuario autenticado');
    }
    return user.uid;
  }

  // Stream con todos los profesores del usuario actual.
  // Sin orderBy en la query (se ordena por nombre en cliente)
  // para no necesitar otro índice compuesto: la lista es pequeña.
  Stream<List<Teacher>> watchAll() {
    return _teachersRef
        .where('userId', isEqualTo: _currentUserId)
        .snapshots()
        .map((snapshot) {
          final teachers = snapshot.docs.map((doc) => doc.data()).toList();
          teachers.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
          return teachers;
        });
  }

  Future<Teacher?> getById(String id) async {
    final doc = await _teachersRef.doc(id).get();
    final teacher = doc.data();
    if (teacher == null || teacher.userId != _currentUserId) return null;
    return teacher;
  }

  Future<void> create(Teacher teacher) async {
    await _teachersRef.add(teacher);
  }

  Future<void> update(Teacher teacher) async {
    if (teacher.id == null) {
      throw Exception('El profesor necesita id para actualizarse');
    }
    await _teachersRef.doc(teacher.id).set(teacher);
  }

  Future<void> delete(String id) async {
    await _teachersRef.doc(id).delete();
  }
}
