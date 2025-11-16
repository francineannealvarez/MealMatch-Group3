// lib/services/firebase_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create user with email & password
  // avatar parameter added
  Future<User?> signUpUser({
    required String email,
    required String password,
    required String name,
    String? avatar, // avatar parameter
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

      // Save user info in Firestore with avatar
      Map<String, dynamic> userData = {
        'email': email,
        'name': name,
        'goals': goals,
        'activityLevel': activityLevel,
        'gender': gender,
        'age': age,
        'height': height,
        'weight': weight,
        'goalWeight': goalWeight,
        'dailyCalorieGoal': dailyCalorieGoal,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Add avatar if provided
      if (avatar != null) {
        userData['avatar'] = avatar;
      }

      await _firestore.collection('users').doc(user!.uid).set(userData);

      return user;
    } catch (e) {
      print('❌ signUpUser error: $e');
      return null;
    }
  }

  // Save user data (for Google sign-ins) with avatar
  Future<void> saveUserData({
    required String email,
    required String name,
    String? avatar,
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

    // Prepare user data with avatar
    Map<String, dynamic> userData = {
      'email': email,
      'name': name,
      'goals': goals,
      'activityLevel': activityLevel,
      'gender': gender,
      'age': age,
      'height': height,
      'weight': weight,
      'goalWeight': goalWeight,
      'dailyCalorieGoal': dailyCalorieGoal,
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (avatar != null) {
      userData['avatar'] = avatar;
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(userData, SetOptions(merge: true));
  }

  // ✅ NEW: Change user password
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        return {'success': false, 'message': 'No user is currently signed in'};
      }

      // Step 1: Re-authenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      try {
        await user.reauthenticateWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'wrong-password') {
          return {'success': false, 'message': 'Current password is incorrect'};
        } else if (e.code == 'invalid-credential') {
          return {'success': false, 'message': 'Current password is incorrect'};
        } else {
          return {
            'success': false,
            'message': 'Authentication failed: ${e.message}',
          };
        }
      }

      // Step 2: Update password
      try {
        await user.updatePassword(newPassword);

        // Optional: Log password change in Firestore
        await _firestore.collection('users').doc(user.uid).update({
          'passwordChangedAt': FieldValue.serverTimestamp(),
        });

        return {'success': true, 'message': 'Password changed successfully'};
      } on FirebaseAuthException catch (e) {
        if (e.code == 'weak-password') {
          return {'success': false, 'message': 'The new password is too weak'};
        } else if (e.code == 'requires-recent-login') {
          return {
            'success': false,
            'message':
                'Please log out and log in again before changing password',
          };
        } else {
          return {
            'success': false,
            'message': 'Failed to update password: ${e.message}',
          };
        }
      }
    } catch (e) {
      print('❌ changePassword error: $e');
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  // ✅ NEW: Sign out user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('❌ signOut error: $e');
    }
  }

  // ✅ NEW: Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
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

  // 1. Schedule account deletion (30 days)
Future<Map<String, dynamic>> scheduleAccountDeletion() async {
  try {
    final user = _auth.currentUser;
    
    if (user == null) {
      return {
        'success': false,
        'message': 'No user is currently signed in',
      };
    }

    final deletionDate = DateTime.now().add(const Duration(days: 30));
    final warningDate = DateTime.now().add(const Duration(days: 23)); // Day 23 = 7 days before deletion

    // Mark account as scheduled for deletion
    await _firestore.collection('users').doc(user.uid).update({
      'scheduledForDeletion': true,
      'deletionScheduledAt': FieldValue.serverTimestamp(),
      'deletionDate': Timestamp.fromDate(deletionDate),
      'warningDate': Timestamp.fromDate(warningDate),
      'warningEmailSent': false, // Track if warning email was sent
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    return {
      'success': true,
      'message': 'Account scheduled for deletion',
      'deletionDate': deletionDate,
    };
  } catch (e) {
    print('❌ scheduleAccountDeletion error: $e');
    return {
      'success': false,
      'message': 'Failed to schedule account deletion: $e',
    };
  }
}

// 2. Restore/Cancel account deletion
Future<Map<String, dynamic>> restoreAccount() async {
  try {
    final user = _auth.currentUser;
    
    if (user == null) {
      return {
        'success': false,
        'message': 'No user is currently signed in',
      };
    }

    // Remove all deletion flags
    await _firestore.collection('users').doc(user.uid).update({
      'scheduledForDeletion': FieldValue.delete(),
      'deletionScheduledAt': FieldValue.delete(),
      'deletionDate': FieldValue.delete(),
      'warningDate': FieldValue.delete(),
      'warningEmailSent': FieldValue.delete(),
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    return {
      'success': true,
      'message': 'Account restored successfully',
    };
  } catch (e) {
    print('❌ restoreAccount error: $e');
    return {
      'success': false,
      'message': 'Failed to restore account: $e',
    };
  }
}

// 3. Check deletion status on login
Future<Map<String, dynamic>?> checkDeletionStatus() async {
  try {
    final user = _auth.currentUser;
    
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();

    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      
      if (data['scheduledForDeletion'] == true) {
        final deletionDate = (data['deletionDate'] as Timestamp?)?.toDate();
        
        // Check if deletion date has passed
        if (deletionDate != null && DateTime.now().isAfter(deletionDate)) {
          // Account should be deleted NOW
          await _firestore.collection('users').doc(user.uid).delete();
          await user.delete();
          await _auth.signOut();
          
          return {
            'isScheduled': true,
            'isExpired': true,
            'message': 'Account has been permanently deleted',
          };
        }
        
        final daysRemaining = deletionDate != null 
            ? deletionDate.difference(DateTime.now()).inDays 
            : 0;
        
        return {
          'isScheduled': true,
          'isExpired': false,
          'deletionDate': deletionDate,
          'daysRemaining': daysRemaining,
        };
      }
    }
    
    return {'isScheduled': false};
  } catch (e) {
    print('❌ checkDeletionStatus error: $e');
    return null;
  }
}

// Cancel account deletion (restore account)
Future<Map<String, dynamic>> cancelAccountDeletion() async {
  try {
    final user = _auth.currentUser;
    
    if (user == null) {
      return {
        'success': false,
        'message': 'No user is currently signed in',
      };
    }

      // Remove deletion flags from Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'scheduledForDeletion': FieldValue.delete(),
        'deletionScheduledAt': FieldValue.delete(),
        'deletionDate': FieldValue.delete(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'message': 'Account deletion cancelled successfully',
      };
    } catch (e) {
      print('❌ cancelAccountDeletion error: $e');
      return {
        'success': false,
        'message': 'Failed to cancel account deletion: $e',
      };
    }
  }


  // Permanently delete account (call this after 30 days)
  Future<Map<String, dynamic>> permanentlyDeleteAccount() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        return {'success': false, 'message': 'No user is currently signed in'};
      }

      // Delete user data from Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete the Firebase Auth account
      await user.delete();

      return {'success': true, 'message': 'Account permanently deleted'};
    } catch (e) {
      print('❌ permanentlyDeleteAccount error: $e');
      return {'success': false, 'message': 'Failed to delete account: $e'};
    }
  }
}
