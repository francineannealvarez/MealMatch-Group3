// 📁 lib/services/log_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/meal_log.dart';

class LogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🔹 Get all logs for TODAY (for the logged-in user)
  Future<List<MealLog>> getTodayLogs() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final String today = _formatDate(DateTime.now());

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('meal_logs')
        .where('date', isEqualTo: today)
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) => MealLog.fromDoc(doc)).toList();
  }

  /// 🔹 Get logs within a date range (used for week/month/custom)
  Future<List<MealLog>> getLogsInRange(DateTime start, DateTime end) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('meal_logs')
        .where('timestamp', isGreaterThanOrEqualTo: start)
        .where('timestamp', isLessThanOrEqualTo: end)
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) => MealLog.fromDoc(doc)).toList();
  }

  /// 🔹 Calculate total calories for a list of MealLogs
  int calculateTotalCalories(List<MealLog> logs) {
    int total = 0;
    for (var log in logs) {
      total += log.calories;
    }
    return total;
  }

  /// 🔹 Get user's calorie goal (from `users` collection)
  Future<int?> getUserCalorieGoal() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    final data = doc.data();
    // Ensure that you have a field like 'goalCalories' in user document
    return data?['goalCalories'] != null
        ? (data!['goalCalories'] as num).toInt()
        : null;
  }

  /// 🔹 Get summary for today (total calories + remaining calories)
  Future<Map<String, dynamic>> getTodaySummary() async {
    final logs = await getTodayLogs();
    final totalCalories = calculateTotalCalories(logs);

    final goal = await getUserCalorieGoal();
    final remaining = (goal != null) ? (goal - totalCalories) : null;

    return {
      'totalCalories': totalCalories,
      'goalCalories': goal,
      'remainingCalories': remaining,
    };
  }

  /// 🔹 Format date (YYYY-MM-DD)
  String _formatDate(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";
  }
}
