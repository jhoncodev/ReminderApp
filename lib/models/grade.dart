import 'package:cloud_firestore/cloud_firestore.dart';

class Grade {
  final String? id;
  final String userId;
  final String courseId;
  final String title;
  final double value;
  final double maxValue;
  final double weight;
  final DateTime createdAt;
  final DateTime updatedAt;

  Grade({
    this.id,
    required this.userId,
    required this.courseId,
    required this.title,
    required this.value,
    required this.maxValue,
    required this.weight,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convertimos el documento de calificación que está en firestore
  // a un objeto de tipo Grade de la app
  factory Grade.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    return Grade(
      id: snapshot.id,
      userId: data['userId'] as String,
      courseId: data['courseId'] as String,
      title: data['title'] as String,
      value: (data['value'] as num).toDouble(),
      maxValue: (data['maxValue'] as num).toDouble(),
      weight: (data['weight'] as num).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Convertimos el objeto Grade de la app para poder guardar
  // como documento en firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'courseId': courseId,
      'title': title,
      'value': value,
      'maxValue': maxValue,
      'weight': weight,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Calcula la calificación normalizada (0-1)
  double get normalizedValue => value / maxValue;

  // Calcula la contribución de esta calificación al promedio ponderado
  double get weightedContribution => normalizedValue * weight;

  // Copia modificada con nuevos valores
  Grade copyWith({
    String? id,
    String? userId,
    String? courseId,
    String? title,
    double? value,
    double? maxValue,
    double? weight,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Grade(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      value: value ?? this.value,
      maxValue: maxValue ?? this.maxValue,
      weight: weight ?? this.weight,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
