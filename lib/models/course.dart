import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reminder_app/models/course_session.dart';

class Course {
  final String? id;
  final String userId;
  final String? academicPeriodId;
  final String name;
  final List<CourseSession> sessions;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  Course({
    this.id,
    required this.userId,
    this.academicPeriodId,
    required this.name,
    required this.sessions,
    this.note,
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
      sessions: (data['sessions'] as List<dynamic>? ?? [])
        .map((e) => CourseSession.fromMap(e as Map<String, dynamic>))
        .toList(),
      note: data['note'] as String?,
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
      'sessions': sessions.map((s) => s.toMap()).toList(),
      if (note != null) 'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt)
    };
  } 
}