import 'package:cloud_firestore/cloud_firestore.dart';

// Recurso compartido entre usuarios, pendiente de aceptación.
// payload: copia de los datos del recurso (sin userId ni ids de vínculos)
class SharedItem {
  final String? id;
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final String type; // 'reminder' | 'course' | 'note' | 'period'
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  SharedItem({
    this.id,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.type,
    required this.payload,
    required this.createdAt,
  });

  factory SharedItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    return SharedItem(
      id: snapshot.id,
      fromUserId: data['fromUserId'] as String,
      fromUserName: data['fromUserName'] as String? ?? 'Alguien',
      toUserId: data['toUserId'] as String,
      type: data['type'] as String,
      payload: Map<String, dynamic>.from(data['payload'] as Map),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'toUserId': toUserId,
      'type': type,
      'payload': payload,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Título legible para la bandeja, según el tipo
  String get displayTitle =>
      (payload['name'] ?? payload['title'] ?? 'Sin título') as String;

  String get typeLabel {
    switch (type) {
      case 'course':
        return 'Curso';
      case 'note':
        return 'Apunte';
      case 'period':
        return 'Periodo';
      case 'teacher':
        return 'Profesor';
      default:
        return 'Recordatorio';
    }
  }
}
