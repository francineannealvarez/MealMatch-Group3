import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new user account
  Future<String?> signUpUser({
    required String name,
    required List<String> goals,
    required String activityLevel,
    required String gender,
    required int age,
    required double height,
    required double weight,
    required double goalWeight,
    required String email,
    required String password,
  }) async {
    try {
      // Create user in Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save additional user info to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'goals': goals,
        'activityLevel': activityLevel,
        'gender': gender,
        'age': age,
        'height': height,
        'weight': weight,
        'goalWeight': goalWeight,
        'email': email,
        'password': password,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return userCredential.user!.uid; // success
    } catch (e) {
      print('Sign up error: $e');
      return null; // error
    }
  }
}
