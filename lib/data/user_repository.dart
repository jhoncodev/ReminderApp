import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reminder_app/models/user.dart';

class UserRepository {
  // This class can be used to manage user-related data operations, such as fetching user details, updating profiles, etc.
  // For now, it's just a placeholder for future user-related functionalities.  
  final CollectionReference<User> _usersRef = FirebaseFirestore.instance
  .collection('users')
  .withConverter(
    fromFirestore: User.fromFirestore, 
    toFirestore: (user, _) => user.toFirestore(),
  );

  Future<User?> getCurrentUser(String userId) async {
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

}