// lib/services/firebase_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create user with email & password
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

      // Calculate daily calorie goal automatically
      int dailyCalorieGoal = _calculateDailyCalorieGoal(
        gender: gender,
        age: age,
        height: height,
        weight: weight,
        activityLevel: activityLevel,
        goals: goals,
      );

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
        'dailyCalorieGoal': dailyCalorieGoal, // ✅ NEW: Auto-calculated goal
        'createdAt': FieldValue.serverTimestamp(),
      });

      return user;
    } catch (e) {
      print('❌ signUpUser error: $e');
      return null;
    }
  }

  // Save user data (for Google sign-ins)
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

    // Calculate daily calorie goal automatically
    int dailyCalorieGoal = _calculateDailyCalorieGoal(
      gender: gender,
      age: age,
      height: height,
      weight: weight,
      activityLevel: activityLevel,
      goals: goals,
    );

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
      'dailyCalorieGoal': dailyCalorieGoal, // ✅ NEW: Auto-calculated goal
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ✅ NEW: Get user's daily calorie goal
  Future<int?> getUserCalorieGoal() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists && doc.data() != null) {
        return doc.data()!['dailyCalorieGoal'] as int?;
      }
      return null;
    } catch (e) {
      print('❌ getUserCalorieGoal error: $e');
      return null;
    }
  }

  // ✅ NEW: Get complete user data
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('❌ getUserData error: $e');
      return null;
    }
  }

  // ✅ NEW: Update user weight (recalculates calorie goal)
  Future<void> updateUserWeight(double newWeight) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userData = await getUserData();
      if (userData == null) return;

      // Recalculate calorie goal with new weight
      int newCalorieGoal = _calculateDailyCalorieGoal(
        gender: userData['gender'],
        age: userData['age'],
        height: userData['height'],
        weight: newWeight,
        activityLevel: userData['activityLevel'],
        goals: List<String>.from(userData['goals']),
      );

      await _firestore.collection('users').doc(user.uid).update({
        'weight': newWeight,
        'dailyCalorieGoal': newCalorieGoal,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ updateUserWeight error: $e');
    }
  }

  // ✅ NEW: Update activity level (recalculates calorie goal)
  Future<void> updateActivityLevel(String newActivityLevel) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userData = await getUserData();
      if (userData == null) return;

      int newCalorieGoal = _calculateDailyCalorieGoal(
        gender: userData['gender'],
        age: userData['age'],
        height: userData['height'],
        weight: userData['weight'],
        activityLevel: newActivityLevel,
        goals: List<String>.from(userData['goals']),
      );

      await _firestore.collection('users').doc(user.uid).update({
        'activityLevel': newActivityLevel,
        'dailyCalorieGoal': newCalorieGoal,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ updateActivityLevel error: $e');
    }
  }

  // ✅ NEW: Calculate BMR using Mifflin-St Jeor Equation
  double _calculateBMR({
    required String gender,
    required int age,
    required double height,
    required double weight,
  }) {

    
    // BMR calculation (Mifflin-St Jeor)
    // Male: (10 × weight in kg) + (6.25 × height in cm) − (5 × age in years) + 5
    // Female: (10 × weight in kg) + (6.25 × height in cm) − (5 × age in years) − 161

    if (gender.toLowerCase() == 'male') {
      return (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      return (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }
  }

  // ✅ NEW: Get activity multiplier
  double _getActivityMultiplier(String activityLevel) {
    switch (activityLevel.toLowerCase()) {
      case 'sedentary':
        return 1.2; // Little or no exercise
      case 'lightly active':
        return 1.375; // Exercise 1-3 times/week
      case 'moderately active':
        return 1.55; // Exercise 4-5 times/week
      case 'extremely active':
        return 1.9; // Intense exercise 6-7 times/week
      default:
        return 1.2;
    }
  }

  // ✅ NEW: Calculate TDEE (Total Daily Energy Expenditure)
  double _calculateTDEE({
    required String gender,
    required int age,
    required double height,
    required double weight,
    required String activityLevel,
  }) {
    double bmr = _calculateBMR(
      gender: gender,
      age: age,
      height: height,
      weight: weight,
    );

    double activityMultiplier = _getActivityMultiplier(activityLevel);

    return bmr * activityMultiplier;
  }

  // ✅ NEW: Calculate daily calorie goal based on user's goals
  int _calculateDailyCalorieGoal({
    required String gender,
    required int age,
    required double height,
    required double weight,
    required String activityLevel,
    required List<String> goals,
  }) {
    double tdee = _calculateTDEE(
      gender: gender,
      age: age,
      height: height,
      weight: weight,
      activityLevel: activityLevel,
    );

    // Adjust based on goals
    bool hasLoseWeight = goals.any(
      (g) =>
          g.toLowerCase().contains('lose') ||
          g.toLowerCase().contains('weight loss'),
    );
    bool hasGainWeight = goals.any(
      (g) =>
          g.toLowerCase().contains('gain') ||
          g.toLowerCase().contains('muscle'),
    );

    if (hasLoseWeight) {
      // Create 500 calorie deficit for weight loss (~0.5 kg per week)
      return (tdee - 500).round();
    } else if (hasGainWeight) {
      // Create 300-500 calorie surplus for weight gain
      return (tdee + 400).round();
    } else {
      // Maintain weight
      return tdee.round();
    }
  }

  // ✅ NEW: Calculate BMI
  double calculateBMI(double weight, double height) {
    double heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  // ✅ NEW: Get BMI category
  String getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }
}
