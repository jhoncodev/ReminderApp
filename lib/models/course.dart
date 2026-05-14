import 'package:cloud_firestore/cloud_firestore.dart';

class Course {
  final String? id;
  final String userId;
  final String? academicPeriodId;
  final String name;
  final List<int> scheduleDays;
  final DateTime createdAt;
  final DateTime updatedAt;

  Course({
    this.id,
    required this.userId,
    this.academicPeriodId,
    required this.name,
    required this.scheduleDays,
    required this.createdAt,
    required this.updatedAt
  });

  // Convertimos el documento del curso que esta en firestore 
  // a un objeto de tipo curso de la app
  factory Course.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ){
    final data = snapshot.data()!;
    return Course(
      id: snapshot.id,
      userId: data['userId'] as String,
      academicPeriodId: data['academicPeriodId'] as String?,
      name: data['name'] as String,
      scheduleDays: List<int>.from(data['scheduleDays'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate()

    );
  }

  // Convertimos el objeto curso de la app para poder guardar
  // como documento en firestore
  Map<String, dynamic> toFirestore(){
    return{
      'userId': userId,
      if (academicPeriodId != null) 'academicPeriodId': academicPeriodId,
      'name': name,
      'scheduleDays': scheduleDays,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt)
    };
  } 
}