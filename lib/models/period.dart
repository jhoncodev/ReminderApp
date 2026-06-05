import 'package:cloud_firestore/cloud_firestore.dart';

class Period {
  final String? id;
  final String userId;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  Period({
    this.id,
    required this.userId,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convertimos el documento de Periodo que traemos de firestore
  // a un objeto de tipo Periodo para usar libremente en la App
  factory Period.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    return Period(
      id: snapshot.id,
      userId: data['userId'] as String,
      name: data['name'] as String,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      isArchived: data['isArchived'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Convertimos el objeto de tipo Periodo a un documento para
  // poder subirlo a firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isArchived': isArchived,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
