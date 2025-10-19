// 📁 lib/models/meal_log.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class MealLog {
  final String foodName;
  final String category;
  final int calories;
  final double servings;
  final String servingSize;
  final DateTime timestamp;
  final String date; // formatted like '2025-10-19'

  MealLog({
    required this.foodName,
    required this.category,
    required this.calories,
    required this.servings,
    required this.servingSize,
    required this.timestamp,
    required this.date,
  });

  // 🔹 Convert to Map (for saving to Firestore)
  Map<String, dynamic> toMap() {
    return {
      'foodName': foodName,
      'category': category,
      'calories': calories,
      'servings': servings,
      'servingSize': servingSize,
      'timestamp': timestamp,
      'date': date,
    };
  }

  // 🔹 Create a MealLog from Firestore document
  factory MealLog.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MealLog(
      foodName: data['foodName'] ?? '',
      category: data['category'] ?? '',
      calories: data['calories'] ?? 0,
      servings: (data['servings'] is int)
          ? (data['servings'] as int).toDouble()
          : (data['servings'] ?? 0.0),
      servingSize: data['servingSize'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      date: data['date'] ?? '',
    );
  }
}
