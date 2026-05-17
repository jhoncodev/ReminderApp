import 'package:cloud_firestore/cloud_firestore.dart';

class User{
  final String? id;
  final String name;
  final String email;
  final String? avatarIcon;
  final DateTime createdAt;
  final DateTime updatedAt;
  User({
    this.id,
    required this.name,
    required this.email,
    this.avatarIcon,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ){
    final data = snapshot.data()!;
    return User(
      id: snapshot.id, 
      name: data['name'] as String,
      email: data['email'] as String,
      avatarIcon: data['avatarIcon'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate()
    );
  }

  Map<String, dynamic> toFirestore(){
    return{
      'name': name,
      'email': email,
      if (avatarIcon != null) 'avatarIcon':avatarIcon,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt)
    };
  }

}