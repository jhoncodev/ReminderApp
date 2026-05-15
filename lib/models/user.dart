import 'package:cloud_firestore/cloud_firestore.dart';

class User{
  final String? id;
  final String name;
  final String email;
  final String? password;
  final DateTime createdAt;
  final DateTime updatedAt;
  User({
    this.id,
    required this.name,
    required this.email,
    this.password,
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
      //password: data['password'] as String,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate()
    );
  }

  Map<String, dynamic> toFirestore(){
    return{
      'name': name,
      'email': email,
      'password': password,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt)
    };
  }

}