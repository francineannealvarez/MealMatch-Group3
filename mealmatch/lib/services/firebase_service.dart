// lib/services/firebase_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ MAIN: Sign in with email & password (with deletion check)
  Future<Map<String, dynamic>> signInUser({
    required String email,
    required String password,
  }) async {
    try {
      // Step 1: Sign in
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        return {'success': false, 'message': 'Sign in failed'};
      }

      // Step 2: Check if THIS account is scheduled for deletion
      final deletionStatus = await checkDeletionStatus();

      if (deletionStatus != null && deletionStatus['isScheduled'] == true) {
        final daysRemaining = deletionStatus['daysRemaining'] as int?;

        // If deletion date has passed, delete account permanently
        if (daysRemaining != null && daysRemaining <= 0) {
          await permanentlyDeleteAccount();

          return {
            'success': false,
            'message':
                'Your account has been permanently deleted. Please create a new account to continue.',
            'accountDeleted': true,
          };
        }

        // If still within grace period, inform user
        return {
          'success': false,
          'message':
              'Your account is scheduled for deletion in $daysRemaining days. Cancel the deletion to continue.',
          'scheduledForDeletion': true,
          'daysRemaining': daysRemaining,
          'deletionDate': deletionStatus['deletionDate'],
        };
      }

      // Step 3: Trigger batch cleanup of OTHER expired accounts (background)
      _batchDeleteExpiredAccounts();

      // Step 4: Normal sign in success
      return {'success': true, 'message': 'Sign in successful', 'user': user};
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return {'success': false, 'message': 'No user found with this email'};
      } else if (e.code == 'wrong-password') {
        return {'success': false, 'message': 'Incorrect password'};
      } else if (e.code == 'invalid-email') {
        return {'success': false, 'message': 'Invalid email format'};
      } else if (e.code == 'user-disabled') {
        return {'success': false, 'message': 'This account has been disabled'};
      } else if (e.code == 'invalid-credential') {
        return {'success': false, 'message': 'Invalid email or password'};
      } else {
        return {'success': false, 'message': 'Sign in failed: ${e.message}'};
      }
    } catch (e) {
      print('❌ signInUser error: $e');
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  // Batch delete expired accounts (Firestore + all collections)
  Future<void> _batchDeleteExpiredAccounts() async {
    try {
      final now = DateTime.now();

      final expiredAccounts = await _firestore
          .collection('users')
          .where('scheduledForDeletion', isEqualTo: true)
          .where('deletionDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .limit(10)
          .get();

      if (expiredAccounts.docs.isEmpty) {
        return;
      }

      print(
        '🗑️ Found ${expiredAccounts.docs.length} expired accounts to delete',
      );

      for (var doc in expiredAccounts.docs) {
        try {
          final userId = doc.id;

          // Delete all user collections
          await _deleteUserCollections(userId);

          // Delete main user document
          await _firestore.collection('users').doc(userId).delete();

          print('✅ Deleted all data for user: $userId');
        } catch (e) {
          print('❌ Error deleting account ${doc.id}: $e');
        }
      }
    } catch (e) {
      print('❌ _batchDeleteExpiredAccounts error: $e');
    }
  }

  // Delete all user-related subcollections
  Future<void> _deleteUserCollections(String userId) async {
    try {
      final batch = _firestore.batch();
      int operationCount = 0;
      const int batchLimit = 500; // Firestore batch limit

      // Helper: Delete subcollection under users/{userId}/
      Future<void> deleteSubcollection(String subcollectionName) async {
        try {
          final snapshot = await _firestore
              .collection('users')
              .doc(userId)
              .collection(subcollectionName)
              .get();

          for (var doc in snapshot.docs) {
            batch.delete(doc.reference);
            operationCount++;

            if (operationCount >= batchLimit) {
              await batch.commit();
              operationCount = 0;
            }
          }

          if (snapshot.docs.isNotEmpty) {
            print(
              '✅ Deleted ${snapshot.docs.length} documents from users/$userId/$subcollectionName',
            );
          }
        } catch (e) {
          print('❌ Error deleting subcollection $subcollectionName: $e');
        }
      }

      // Delete meal_logs subcollection (your main data)
      await deleteSubcollection('meal_logs');

      // Delete weight_history subcollection
      await deleteSubcollection('weight_history');

      // Add more subcollections here if you create them in the future

      // Commit any remaining operations
      if (operationCount > 0) {
        await batch.commit();
      }

      print('✅ Successfully deleted all subcollections for user: $userId');
    } catch (e) {
      print('❌ _deleteUserCollections error: $e');
    }
  }

  // ✅ UPDATED: Create user with email & password (now includes weightPace)
  Future<bool> saveUserProfile({
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
    try {
      final user = _auth.currentUser;

      if (user == null) {
        print('❌ No authenticated user found');
        return false;
      }

      // Determine default weight pace based on goals
      String defaultWeightPace = _determineDefaultWeightPace(
        weight,
        goalWeight,
      );

      // Calculate daily calorie goal with weight pace
      int dailyCalorieGoal = _calculateDailyCalorieGoalWithPace(
        gender: gender,
        age: age,
        height: height,
        weight: weight,
        activityLevel: activityLevel,
        goals: goals,
        weightPace: defaultWeightPace,
      );

      // Prepare user data
      Map<String, dynamic> userData = {
        'email': user.email,
        'name': name,
        'goals': goals,
        'activityLevel': activityLevel,
        'gender': gender,
        'age': age,
        'height': height,
        'weight': weight,
        'goalWeight': goalWeight,
        'dailyCalorieGoal': dailyCalorieGoal,
        'weightPace': defaultWeightPace, // ✅ NEW: Add weight pace
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (avatar != null) {
        userData['avatar'] = avatar;
      }

      // Save to Firestore
      await _firestore.collection('users').doc(user.uid).set(userData);

      print(
        '✅ User profile saved successfully with weight pace: $defaultWeightPace',
      );
      return true;
    } catch (e) {
      print('❌ saveUserProfile error: $e');
      return false;
    }
  }

  // ✅ UPDATED: Save user data (for Google sign-ins) with weight pace
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

    // Determine default weight pace based on goals
    String defaultWeightPace = _determineDefaultWeightPace(weight, goalWeight);

    // Calculate daily calorie goal with weight pace
    int dailyCalorieGoal = _calculateDailyCalorieGoalWithPace(
      gender: gender,
      age: age,
      height: height,
      weight: weight,
      activityLevel: activityLevel,
      goals: goals,
      weightPace: defaultWeightPace,
    );

    // Prepare user data with avatar and weight pace
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
      'weightPace': defaultWeightPace, // ✅ NEW: Add weight pace
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (avatar != null) {
      userData['avatar'] = avatar;
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(userData, SetOptions(merge: true));

    print(
      '✅ User data saved successfully with weight pace: $defaultWeightPace',
    );
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

  // ✅ Sign out user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('❌ signOut error: $e');
    }
  }

  // ✅ Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // ✅ Get user's daily calorie goal
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

  // ✅ Get complete user data
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

  // ✅ UPDATED: Update user weight (recalculates calorie goal with pace)
  Future<void> updateUserWeight(double newWeight) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userData = await getUserData();
      if (userData == null) return;

      // Get weight pace or default to 'steady'
      String weightPace = userData['weightPace'] ?? 'steady';

      // Recalculate calorie goal with new weight and existing pace
      int newCalorieGoal = _calculateDailyCalorieGoalWithPace(
        gender: userData['gender'],
        age: userData['age'],
        height: userData['height'],
        weight: newWeight,
        activityLevel: userData['activityLevel'],
        goals: List<String>.from(userData['goals']),
        weightPace: weightPace,
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

  // ✅ UPDATED: Update activity level (recalculates calorie goal with pace)
  Future<void> updateActivityLevel(String newActivityLevel) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userData = await getUserData();
      if (userData == null) return;

      // Get weight pace or default to 'steady'
      String weightPace = userData['weightPace'] ?? 'steady';

      int newCalorieGoal = _calculateDailyCalorieGoalWithPace(
        gender: userData['gender'],
        age: userData['age'],
        height: userData['height'],
        weight: userData['weight'],
        activityLevel: newActivityLevel,
        goals: List<String>.from(userData['goals']),
        weightPace: weightPace,
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

  // ✅ NEW: Determine default weight pace based on current vs goal weight
  String _determineDefaultWeightPace(double currentWeight, double goalWeight) {
    // If trying to lose or gain weight, default to 'steady' (recommended)
    // If maintaining weight, still default to 'steady'
    return 'steady';
  }

  // ✅ NEW: Get calorie adjustment based on weight pace
  int _getCalorieAdjustmentForPace(String weightPace, bool isLosingWeight) {
    switch (weightPace.toLowerCase()) {
      case 'relaxed':
        return isLosingWeight ? -250 : 250; // 0.5 kg/week
      case 'steady':
        return isLosingWeight ? -500 : 500; // 0.5 kg/week
      case 'accelerated':
        return isLosingWeight ? -750 : 750; // 0.75 kg/week
      case 'vigorous':
        return isLosingWeight ? -1000 : 1000; // 1 kg/week
      default:
        return isLosingWeight ? -500 : 500;
    }
  }

  // ✅ NEW: Calculate daily calorie goal with weight pace consideration
  int _calculateDailyCalorieGoalWithPace({
    required String gender,
    required int age,
    required double height,
    required double weight,
    required String activityLevel,
    required List<String> goals,
    required String weightPace,
  }) {
    // Calculate TDEE (maintenance calories)
    double tdee = _calculateTDEE(
      gender: gender,
      age: age,
      height: height,
      weight: weight,
      activityLevel: activityLevel,
    );

    // Determine if user wants to lose or gain weight
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

    // Apply calorie adjustment based on weight pace
    int targetCalories;
    if (hasLoseWeight) {
      int adjustment = _getCalorieAdjustmentForPace(weightPace, true);
      targetCalories = (tdee + adjustment).round();
    } else if (hasGainWeight) {
      int adjustment = _getCalorieAdjustmentForPace(weightPace, false);
      targetCalories = (tdee + adjustment).round();
    } else {
      // Maintain weight - use TDEE
      targetCalories = tdee.round();
    }

    // Apply safety limits
    if (gender.toLowerCase() == 'male') {
      targetCalories = targetCalories.clamp(1500, 4000);
    } else {
      targetCalories = targetCalories.clamp(1200, 4000);
    }

    return targetCalories;
  }

  // Keep existing _calculateDailyCalorieGoal for backward compatibility
  int _calculateDailyCalorieGoal({
    required String gender,
    required int age,
    required double height,
    required double weight,
    required String activityLevel,
    required List<String> goals,
  }) {
    // Default to 'steady' pace if not specified
    return _calculateDailyCalorieGoalWithPace(
      gender: gender,
      age: age,
      height: height,
      weight: weight,
      activityLevel: activityLevel,
      goals: goals,
      weightPace: 'steady',
    );
  }

  // ✅ Calculate BMR using Mifflin-St Jeor Equation
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

  // ✅ Get activity multiplier
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

  // ✅ Calculate TDEE (Total Daily Energy Expenditure)
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

  // ✅ Calculate BMI
  double calculateBMI(double weight, double height) {
    double heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  // ✅ Get BMI category
  String getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Future<Map<String, dynamic>> scheduleAccountDeletion() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        return {'success': false, 'message': 'No user is currently signed in'};
      }

      final deletionDate = DateTime.now().add(const Duration(days: 30));

      await _firestore.collection('users').doc(user.uid).update({
        'scheduledForDeletion': true,
        'deletionScheduledAt': FieldValue.serverTimestamp(),
        'deletionDate': Timestamp.fromDate(deletionDate),
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

  // Cancel account deletion (restore account)
  Future<Map<String, dynamic>> cancelAccountDeletion() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        return {'success': false, 'message': 'No user is currently signed in'};
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

  // Check if account is scheduled for deletion
  Future<Map<String, dynamic>?> checkDeletionStatus() async {
    try {
      final user = _auth.currentUser;

      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;

        if (data['scheduledForDeletion'] == true) {
          final deletionDate = (data['deletionDate'] as Timestamp?)?.toDate();

          return {
            'isScheduled': true,
            'deletionDate': deletionDate,
            'daysRemaining': deletionDate != null
                ? deletionDate.difference(DateTime.now()).inDays
                : 0,
          };
        }
      }

      return {'isScheduled': false};
    } catch (e) {
      print('❌ checkDeletionStatus error: $e');
      return null;
    }
  }

  // ✅ COMPLETE: Permanently delete account (Firestore + all collections + Firebase Auth)
  Future<Map<String, dynamic>> permanentlyDeleteAccount() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        return {'success': false, 'message': 'No user is currently signed in'};
      }

      final uid = user.uid;

      // Step 1: Delete all user collections first
      await _deleteUserCollections(uid);

      // Step 2: Delete main user document
      await _firestore.collection('users').doc(uid).delete();

      // Step 3: Delete Firebase Auth account
      await user.delete();

      print('✅ Permanently deleted account and all data for: $uid');

      return {'success': true, 'message': 'Account permanently deleted'};
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return {
          'success': false,
          'message':
              'For security reasons, please log in again before deleting your account',
          'requiresReauth': true,
        };
      }
      print('❌ permanentlyDeleteAccount error: $e');
      return {
        'success': false,
        'message': 'Failed to delete account: ${e.message}',
      };
    } catch (e) {
      print('❌ permanentlyDeleteAccount error: $e');
      return {'success': false, 'message': 'Failed to delete account: $e'};
    }
  }
}
