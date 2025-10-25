// 📁 lib/models/meal_log.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class MealLog {
  final String id;
  final String category;
  final String foodName;
  final String brand;
  final double calories;
  final double carbs;
  final double fats;
  final double proteins;
  final double servings;
  final String servingSize;
  final DateTime timestamp;
  final String date;

  MealLog({
    required this.id,
    required this.category,
    required this.foodName,
    required this.brand,
    required this.calories,
    required this.carbs,
    required this.fats,
    required this.proteins,
    required this.servings,
    required this.servingSize,
    required this.timestamp,
    required this.date,
  });

  factory MealLog.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MealLog(
      id: doc.id,
      category: data['category'] ?? '',
      foodName: data['foodName'] ?? '',
      brand: data['brand'] ?? '',
      calories: (data['calories'] ?? 0).toDouble(),
      carbs: (data['carbs'] ?? 0).toDouble(),
      fats: (data['fats'] ?? 0).toDouble(),
      proteins: (data['proteins'] ?? 0).toDouble(),
      servings: (data['servings'] ?? 0).toDouble(),
      servingSize: data['servingSize'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      date: data['date'] ?? '',
    );
  }
}