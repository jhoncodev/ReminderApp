import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- Add this import

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // <-- Add Firestore instance

  Future<UserCredential?> signInWithGoogle() async {
    try {
      await GoogleSignIn.instance.initialize();
      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();

      if (googleUser == null) return null;

      final clientAuth = await googleUser.authorizationClient.authorizeScopes([
        'email',
        'profile',
      ]);

      final googleAuth = await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: clientAuth.accessToken,
      );

      // 1. Sign in to Firebase
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      // 2. Check if this Google user already has a profile in Firestore
      if (user != null) {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();

        // 3. If they don't exist, create their profile matching your Register flow
        if (!userDoc.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            // Pull the display name from Google, or default to 'Usuario'
            'name': user.displayName ?? 'Usuario', 
            'email': user.email ?? '',
            'avatarIcon': 'anonimo', // You can keep your local avatar logic!
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      return userCredential;
      
    } catch (e) {
      print("Error during Google Sign-In: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    await GoogleSignIn.instance.disconnect();
    await _auth.signOut();
  }
}