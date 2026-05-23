import 'package:cloud_firestore/cloud_firestore.dart';

class Reminder {
  final String? id;
  final String userId;
  final String name;
  final String? notes;
  final double? budgetAmount;
  final String frequency;
  final List<int> scheduleDays;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? startTime; // "HH:mm"
  final DateTime? date;

  Reminder({
    this.id,
    required this.userId,
    required this.name,
    this.notes,
    this.budgetAmount,
    required this.frequency,
    required this.scheduleDays,
    required this.createdAt,
    required this.updatedAt,
    this.startTime,
    this.date,
  });

  // Convertimos el documento de Reminder que traemos de firestore
  // a un objeto de tipo Reminder para usar libremente en la App
  factory Reminder.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    return Reminder(
      id: snapshot.id,
      userId: data['userId'] as String,
      name: data['name'] as String,
      notes: data['notes'] as String?,
      budgetAmount: (data['budgetAmount'] as num?)?.toDouble(),
      frequency: data['frequency'] as String,
      scheduleDays: List<int>.from(data['scheduleDays'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      startTime: data['startTime'] as String?,
      date: data['date'] != null ? (data['date'] as Timestamp).toDate() : null,
    );
  }

  // Convertimos el objeto de tipo Activity a un documento para
  // poder subirlo a firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      if (notes != null) 'notes': notes,
      if (budgetAmount != null) 'budgetAmount': budgetAmount,
      'frequency': frequency,
      'scheduleDays': scheduleDays,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (startTime != null) 'startTime': startTime,
      if (date != null) 'date': Timestamp.fromDate(date!),
    };
  }
}
