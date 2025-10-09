import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔹 Create user with email & password
  Future<User?> signUpUser({
    required String email,
    required String password,
    required String name,
    required List<String> goals,
    required String activityLevel,
    required String gender,
    required int age,
    required double height,
    required double weight,
    required double goalWeight,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;

      // Save user info in Firestore
      await _firestore.collection('users').doc(user!.uid).set({
        'email': email,
        'name': name,
        'goals': goals,
        'activityLevel': activityLevel,
        'gender': gender,
        'age': age,
        'height': height,
        'weight': weight,
        'goalWeight': goalWeight,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return user;
    } catch (e) {
      print('❌ signUpUser error: $e');
      return null;
    }
  }

  // 🔹 Save user data (for Google sign-ins)
  Future<void> saveUserData({
    required String email,
    required String name,
    required List<String> goals,
    required String activityLevel,
    required String gender,
    required int age,
    required double height,
    required double weight,
    required double goalWeight,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).set({
      'email': email,
      'name': name,
      'goals': goals,
      'activityLevel': activityLevel,
      'gender': gender,
      'age': age,
      'height': height,
      'weight': weight,
      'goalWeight': goalWeight,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)); // ✅ merge = don't overwrite existing Google data
  }
}
