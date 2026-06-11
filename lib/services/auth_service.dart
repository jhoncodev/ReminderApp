import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      await GoogleSignIn.instance.initialize();
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance
          .authenticate();

      final clientAuth = await googleUser.authorizationClient.authorizeScopes([
        'email',
        'profile',
      ]);

      final googleAuth = googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: clientAuth.accessToken,
      );

      // 1. Iniciar sesión en Firebase
      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      User? user = userCredential.user;

      // 2. Verificar si este usuario de Google ya tiene perfil en Firestore
      if (user != null) {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        // 3. Si no existe, crear su perfil igual que en el flujo de registro
        if (!userDoc.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            // Nombre desde Google, o 'Usuario' por defecto
            'name': user.displayName ?? 'Usuario',
            'email': user.email ?? '',
            'avatarIcon': 'anonimo', // Por defecto; el usuario puede cambiarlo en Perfil
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      return userCredential;
    } on GoogleSignInException catch (e) {
      // Cancelar el prompt no es un error: no se muestra nada
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }

  Future<void> signOut() async {
    await GoogleSignIn.instance.disconnect();
    await _auth.signOut();
  }

  // Envía el correo de restablecimiento de contraseña
  // Firebase no revela si el correo existe
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }
}

// Traducción de codigos de FirebaseAuthException a mensajes para el usuario.
String authErrorMessage(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-credential':
    case 'user-not-found':
    case 'wrong-password':
      return 'Correo o contraseña incorrectos';
    case 'invalid-email':
      return 'El correo electrónico está mal formateado';
    case 'too-many-requests':
      return 'Demasiados intentos, espera unos minutos';
    case 'user-disabled':
      return 'Esta cuenta está deshabilitada';
    case 'network-request-failed':
      return 'Sin conexión a internet';
    case 'email-already-in-use':
      return 'Ya existe una cuenta con ese correo';
    case 'weak-password':
      return 'La contraseña es muy débil (mínimo 6 caracteres)';
    default:
      return 'Ocurrió un error, intenta de nuevo';
  }
}
