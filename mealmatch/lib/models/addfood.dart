// 📁 lib/models/addfood.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class MealLog {
  final String category;
  final String foodName;
  final double calories;
  final double carbs;
  final double fats;
  final double proteins;
  final double servings;
  final String servingSize;
  final DateTime timestamp;
  final String date; // formatted like '2025-10-19'

  MealLog({
    required this.category,
    required this.foodName,
    required this.calories,
    required this.carbs,
    required this.fats,
    required this.proteins,
    required this.servings,
    required this.servingSize,
    required this.timestamp,
    required this.date,
  });

  // 🔹 Convert to Map (for saving to Firestore)
  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'foodName': foodName,
      'calories': calories,
      'carbs': carbs,
      'fats': fats,
      'proteins': proteins,
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
      category: data['category'] ?? '',
      foodName: data['foodName'] ?? '',
      calories: data['calories'] ?? 0,
      carbs: data['carbs'] ?? 0,
      fats: data['fats'] ?? 0,
      proteins: data['proteins'] ?? 0,
      servings: (data['servings'] is double)
          ? (data['servings'] as double).toDouble()
          : (data['servings'] ?? 0.0),
      servingSize: data['servingSize'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      date: data['date'] ?? '',
    );
  }
}
