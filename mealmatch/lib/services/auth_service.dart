import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  static Future<UserCredential?> signInWithGoogle() async {
    try {
      // ✅ Force logout first so user can choose another account
      await _googleSignIn.signOut();

      // ✅ Start the Google sign-in process again
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // user canceled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print("Error in Google Sign-In: $e");
      return null;
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut(); // ✅ This clears the Google account session
  }
}
