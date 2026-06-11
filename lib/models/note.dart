import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  final String id;
  final String userId;
  final String? courseId;
  final String title;
  final int colorCode;
  final String content;
  final DateTime createdAt;
  

  Note({
    required this.id, 
    required this.userId, 
    this.courseId, 
    required this.content, 
    required this.createdAt, 
    required this.title,
    required this.colorCode,
  });

  factory Note.fromFirestore(Map<String, dynamic> data, String id) {
    return Note(
      id: id,
      userId: data['userId'] as String,
      courseId: data['courseId'] as String?,
      title: data['title'] as String,
      content: data['content'] as String,
      colorCode: data['colorCode'] as int? ?? 0xFF1E1E1E, // Color por defecto si no viene en el doc
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'courseId': courseId,
      'title': title,
      'colorCode': colorCode,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

}
