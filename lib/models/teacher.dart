import 'package:cloud_firestore/cloud_firestore.dart';

// Profesor del usuario, reutilizable entre cursos (vínculo: Course.teacherId)
class Teacher {
  final String? id;
  final String userId;
  final String name;
  final String? email;
  final String? phone;
  final DateTime createdAt;
  final DateTime updatedAt;

  Teacher({
    this.id,
    required this.userId,
    required this.name,
    this.email,
    this.phone,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Teacher.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    return Teacher(
      id: snapshot.id,
      userId: data['userId'] as String,
      name: data['name'] as String,
      email: data['email'] as String?,
      phone: data['phone'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
