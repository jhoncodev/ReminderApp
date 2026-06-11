import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reminder_app/models/user.dart' as app_user;

class UserRepository {
  // Repositorio del perfil de usuario (colección 'users', docId = uid)

  String get _currentUserId {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No hay usuario autenticado');
    }
    return user.uid;
  }

  final CollectionReference<app_user.User> _usersRef = FirebaseFirestore
      .instance
      .collection('users')
      .withConverter(
        fromFirestore: app_user.User.fromFirestore,
        toFirestore: (user, _) => user.toFirestore(),
      );

  Future<app_user.User?> getCurrentUser(String userId) async {
    try {
      final snapshot = await _usersRef.doc(userId).get();
      if (snapshot.exists) {
        return snapshot.data();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> updateUser(app_user.User user) async {
    await _usersRef.doc(_currentUserId).set(user);
  }
}
