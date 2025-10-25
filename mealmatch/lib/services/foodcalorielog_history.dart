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

  /// 🔹 Get logs for a specific date
  Future<List<MealLog>> getLogsByDate(DateTime date) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final String dateStr = _formatDate(date);

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('meal_logs')
        .where('date', isEqualTo: dateStr)
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) => MealLog.fromDoc(doc)).toList();
  }

  /// 🔹 Get logs by date and category
  Future<List<MealLog>> getLogsByDateAndCategory(
      DateTime date, String category) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final String dateStr = _formatDate(date);

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('meal_logs')
        .where('date', isEqualTo: dateStr)
        .where('category', isEqualTo: category)
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) => MealLog.fromDoc(doc)).toList();
  }

  /// 🔹 Get logs within a date range (used for week/month/custom)
  Future<List<MealLog>> getLogsInRange(DateTime start, DateTime end) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    // Set start to beginning of day and end to end of day
    final startOfDay = DateTime(start.year, start.month, start.day);
    final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('meal_logs')
        .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
        .where('timestamp', isLessThanOrEqualTo: endOfDay)
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) => MealLog.fromDoc(doc)).toList();
  }

  /// 🔹 Delete a meal log
  Future<void> deleteMealLog(String logId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('meal_logs')
        .doc(logId)
        .delete();
  }

  /// 🔹 Calculate total calories for a list of MealLogs
  double calculateTotalCalories(List<MealLog> logs) {
    double total = 0;
    for (var log in logs) {
      total += log.calories;
    }
    return total;
  }

  /// 🔹 Calculate total macros for a list of MealLogs
  Map<String, double> calculateTotalMacros(List<MealLog> logs) {
    double totalCarbs = 0;
    double totalProteins = 0;
    double totalFats = 0;

    for (var log in logs) {
      totalCarbs += log.carbs;
      totalProteins += log.proteins;
      totalFats += log.fats;
    }

    return {
      'carbs': totalCarbs,
      'proteins': totalProteins,
      'fats': totalFats,
    };
  }

  /// 🔹 Get user's calorie goal (from `users` collection)
  Future<int?> getUserCalorieGoal() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    final data = doc.data();
    return data?['goalCalories'] != null
        ? (data!['goalCalories'] as num).toInt()
        : null;
  }

  /// 🔹 Get summary for today (total calories + remaining calories)
  Future<Map<String, dynamic>> getTodaySummary() async {
    final logs = await getTodayLogs();
    final totalCalories = calculateTotalCalories(logs);
    final macros = calculateTotalMacros(logs);

    final goal = await getUserCalorieGoal();
    final remaining = (goal != null) ? (goal - totalCalories) : null;

    return {
      'totalCalories': totalCalories,
      'goalCalories': goal,
      'remainingCalories': remaining,
      'totalCarbs': macros['carbs'],
      'totalProteins': macros['proteins'],
      'totalFats': macros['fats'],
    };
  }

  /// 🔹 Group logs by category for a specific date
  Future<Map<String, List<MealLog>>> getLogsGroupedByCategory(
      DateTime date) async {
    final logs = await getLogsByDate(date);

    Map<String, List<MealLog>> grouped = {
      'Breakfast': [],
      'Lunch': [],
      'Dinner': [],
      'Snack': [],
    };

    for (var log in logs) {
      if (grouped.containsKey(log.category)) {
        grouped[log.category]!.add(log);
      }
    }

    return grouped;
  }

  /// 🔹 Format date (YYYY-MM-DD)
  String _formatDate(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";
  }
}