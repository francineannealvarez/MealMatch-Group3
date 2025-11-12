// 📁 lib/services/calorielog_history_service.dart

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

    final now = DateTime.now();
    final dateStr = _formatDate(now);

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('meal_logs')
        .where('date', isEqualTo: dateStr)
        .get();

    // Sort in-memory to avoid composite index requirement
    final logs = snapshot.docs.map((doc) => MealLog.fromDoc(doc)).toList();
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return logs;
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
        .get();

    // Sort in-memory
    final logs = snapshot.docs.map((doc) => MealLog.fromDoc(doc)).toList();
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return logs;
  }

  /// 🔹 Get logs by date and category
  Future<List<MealLog>> getLogsByDateAndCategory(
    DateTime date,
    String category,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final String dateStr = _formatDate(date);

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('meal_logs')
        .where('date', isEqualTo: dateStr)
        .where('category', isEqualTo: category)
        .get();

    // Sort in-memory
    final logs = snapshot.docs.map((doc) => MealLog.fromDoc(doc)).toList();
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return logs;
  }

  /// 🔹 Get logs within a date range (used for week/month/custom)
  Future<List<MealLog>> getLogsInRange(DateTime start, DateTime end) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    // Generate all date strings in the range
    List<String> dateStrings = [];
    DateTime current = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);

    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      dateStrings.add(_formatDate(current));
      current = current.add(const Duration(days: 1));
    }

    // Fetch all logs that match any date in range
    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('meal_logs')
        .where(
          'date',
          whereIn: dateStrings.take(10).toList(),
        ) // Firestore limit: max 10
        .get();

    // If range > 10 days, fetch in batches
    List<MealLog> allLogs = [];
    if (dateStrings.length <= 10) {
      allLogs = snapshot.docs.map((doc) => MealLog.fromDoc(doc)).toList();
    } else {
      // For longer ranges, query each date separately (less efficient but works)
      for (String dateStr in dateStrings) {
        final batch = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('meal_logs')
            .where('date', isEqualTo: dateStr)
            .get();
        allLogs.addAll(batch.docs.map((doc) => MealLog.fromDoc(doc)));
      }
    }

    // Sort in-memory
    allLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return allLogs;
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

    return {'carbs': totalCarbs, 'proteins': totalProteins, 'fats': totalFats};
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
    DateTime date,
  ) async {
    final logs = await getLogsByDate(date);

    Map<String, List<MealLog>> grouped = {
      'Breakfast': [],
      'Lunch': [],
      'Dinner': [],
      'Snacks': [],
    };

    for (var log in logs) {
      if (grouped.containsKey(log.category)) {
        grouped[log.category]!.add(log);
      }
    }

    return grouped;
  }

  // Format date (YYYY-MM-DD) - MATCHES YOUR SAVE FORMAT
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Calculate total protein from logs
  double calculateTotalProtein(List<MealLog> logs) {
    return logs.fold(0.0, (sum, log) => sum + log.proteins);
  }

  // Calculate total carbs from logs
  double calculateTotalCarbs(List<MealLog> logs) {
    return logs.fold(0.0, (sum, log) => sum + log.carbs);
  }

  // Calculate total fat from logs
  double calculateTotalFat(List<MealLog> logs) {
    return logs.fold(0.0, (sum, log) => sum + log.fats);
  }
}
