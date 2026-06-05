import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reminder_app/models/course.dart';

class CourseRepository {
  // Se crea la referencia a la colección 'courses' en firestore
  // con withConverter, todas las consultas nos devolverán objetos
  // del tipo Course
  final CollectionReference<Course> _coursesRef = FirebaseFirestore.instance
      .collection('courses')
      .withConverter<Course>(
        fromFirestore: Course.fromFirestore,
        toFirestore: (course, _) => course.toFirestore(),
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

  // Stream (Escucha en tiempo real a firestore) con todos los cursos del
  // usuario actual, mostrando de arriba abajo opor fecha de creación
  Stream<List<Course>> watchAll() {
    return _coursesRef
        .where('userId', isEqualTo: _currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Método para crear un nuevo curso, firestore genera el id
  // que es el documento automaticamente
  Future<void> create(Course course) async {
    await _coursesRef.add(course);
  }

  // Método para actualizar un curso por completo, se requiere que el
  // curso tenga id
  Future<void> update(Course course) async {
    if (course.id == null) {
      throw Exception('No se puede actualizar un curso sin id');
    }

    await _coursesRef.doc(course.id).set(course);
  }

  // Método para eliminar un curso por id
  Future<void> delete(String id) async {
    await _coursesRef.doc(id).delete();
  }

  // ==========================================
  // READ (Single Course for display)
  // ==========================================
  Future<Course?> getCourseById(String courseId) async {
    final doc = await _coursesRef.doc(courseId).get();

    if (!doc.exists) return null;

    final course = doc.data();

    if (course == null) return null;

    if (course.userId != _currentUserId) return null;

    return course;
  }

  // ==========================================
  // READ (All Courses for the Current User)
  // ==========================================
  Stream<List<Course>> getUserCourses() {
    final userId = _currentUserId;

    return _coursesRef
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            print('Course: ${doc.data().name}');
            return doc.data();
          }).toList(),
        );
  }
}
