import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reminder_app/models/period.dart';

class PeriodRepository {
  // Creamos la referencia a la colección 'periods' en firestore
  // con withConverter, todas las consultas nos devolverán objetos
  // tipo Period
  final CollectionReference<Period> _periodsRef = FirebaseFirestore.instance
      .collection('periods')
      .withConverter(
        fromFirestore: Period.fromFirestore,
        toFirestore: (period, _) => period.toFirestore(),
      );

  // Se devuelve el uid del usaurio con sesión iniciada y
  // si no existe se lanza una excepción
  String get _currentUserId {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No hay usuario autenticado');
    }
    return user.uid;
  }

  // Stream (Escucha en tiempo real a firestore) con todos los periodos del
  // usuario actual NO ARCHIVADOS, ordenados por fecha de inicio
  // Filtrado en cliente para evitar índice compuesto
  Stream<List<Period>> watchAll() {
    return _periodsRef
        .where('userId', isEqualTo: _currentUserId)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data())
            .where((p) => !p.isArchived)
            .toList());
  }

  // Stream con todos los periodos ARCHIVADOS del usuario actual
  // Filtrado en cliente para evitar índice compuesto
  Stream<List<Period>> watchArchived() {
    return _periodsRef
        .where('userId', isEqualTo: _currentUserId)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data())
            .where((p) => p.isArchived)
            .toList());
  }

  // Método para crear un nuevo periodo, firestore genera el id
  // que es el documento automaticamente
  Future<void> create(Period period) async {
    await _periodsRef.add(period);
  }

  // Método para actualizar un periodo por completo, se requiere que el
  // periodo tenga id
  Future<void> update(Period period) async {
    if (period.id == null) {
      throw Exception('No se puede actualizar un periodo sin id');
    }

    await _periodsRef.doc(period.id).set(period);
  }

  // Método para eliminar un periodo por su id
  Future<void> delete(String id) async {
    await _periodsRef.doc(id).delete();
  }

  Future<Period?> getById(String id) async {
    final snapshot = await _periodsRef.doc(id).get();
    return snapshot.data();
  }

  Future<List<Period>> getAll() async {
    final snapshot = await _periodsRef
        .where('userId', isEqualTo: _currentUserId)
        .orderBy('startDate', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => doc.data())
        .where((p) => !p.isArchived)
        .toList();
  }

  // Método para archivar un periodo (cambiar isArchived a true)
  Future<void> archive(Period period) async {
    if (period.id == null) {
      throw Exception('No se puede archivar un periodo sin id');
    }
    final archivedPeriod = Period(
      id: period.id,
      userId: period.userId,
      name: period.name,
      startDate: period.startDate,
      endDate: period.endDate,
      isArchived: true,
      createdAt: period.createdAt,
      updatedAt: DateTime.now(),
    );
    await _periodsRef.doc(period.id).set(archivedPeriod);
  }

  // Método para desarchivar un periodo (cambiar isArchived a false)
  Future<void> unarchive(Period period) async {
    if (period.id == null) {
      throw Exception('No se puede desarchivar un periodo sin id');
    }
    final unarchivedPeriod = Period(
      id: period.id,
      userId: period.userId,
      name: period.name,
      startDate: period.startDate,
      endDate: period.endDate,
      isArchived: false,
      createdAt: period.createdAt,
      updatedAt: DateTime.now(),
    );
    await _periodsRef.doc(period.id).set(unarchivedPeriod);
  }
}
