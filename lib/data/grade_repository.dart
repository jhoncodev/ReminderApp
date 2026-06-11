import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reminder_app/models/grade.dart';

class GradeRepository {
  // Se crea la referencia a la colección 'grades' en firestore
  // con withConverter, todas las consultas nos devolverán objetos
  // del tipo Grade
  final CollectionReference<Grade> _gradesRef = FirebaseFirestore.instance
      .collection('grades')
      .withConverter<Grade>(
        fromFirestore: Grade.fromFirestore,
        toFirestore: (grade, _) => grade.toFirestore(),
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

  // Stream (Escucha en tiempo real a firestore) con todas las calificaciones
  // del usuario actual, ordenadas por fecha de creación descendente
  Stream<List<Grade>> watchAll() {
    return _gradesRef
        .where('userId', isEqualTo: _currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Stream de calificaciones para un curso específico
  Stream<List<Grade>> watchByCourse(String courseId) {
    return _gradesRef
        .where('userId', isEqualTo: _currentUserId)
        .where('courseId', isEqualTo: courseId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Obtiene todas las calificaciones de un curso (Future, no Stream)
  Future<List<Grade>> getByCourse(String courseId) async {
    final snapshot = await _gradesRef
        .where('userId', isEqualTo: _currentUserId)
        .where('courseId', isEqualTo: courseId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // Método para crear una nueva calificación, firestore genera el id
  // que es el documento automáticamente
  Future<void> create(Grade grade) async {
    await _gradesRef.add(grade);
  }

  // Método para actualizar una calificación por completo, se requiere que la
  // calificación tenga id
  Future<void> update(Grade grade) async {
    if (grade.id == null) {
      throw Exception('No se puede actualizar una calificación sin id');
    }

    await _gradesRef.doc(grade.id).set(grade);
  }

  // Método para eliminar una calificación por id
  Future<void> delete(String id) async {
    await _gradesRef.doc(id).delete();
  }

  // Calcula el promedio ponderado de un curso en escala 0-20
  double calculateWeightedAverage(List<Grade> grades) {
    if (grades.isEmpty) return 0.0;

    double totalWeightedValue = 0.0;
    double totalWeight = 0.0;

    for (final grade in grades) {
      totalWeightedValue += grade.weightedContribution;
      totalWeight += grade.weight;
    }

    if (totalWeight == 0) return 0.0;
    return (totalWeightedValue / totalWeight) * 20;
  }

  // Calcula la suma total de pesos
  double calculateTotalWeight(List<Grade> grades) {
    return grades.fold(0.0, (sums, grade) => sums + grade.weight);
  }

  // Valida que la suma de pesos no exceda 100
  bool isWeightValid(List<Grade> grades) {
    return calculateTotalWeight(grades) <= 100.0;
  }

  // Obtiene el peso restante disponible para asignar
  double getRemainingWeight(List<Grade> grades) {
    final total = calculateTotalWeight(grades);
    return (100.0 - total).clamp(0.0, 100.0);
  }
}
