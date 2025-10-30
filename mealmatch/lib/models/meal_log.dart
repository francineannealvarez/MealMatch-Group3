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
  final String serving;
  final DateTime timestamp;
  final String date;
  final bool isVerified;
  final String source;

  MealLog({
    required this.id,
    required this.category,
    required this.foodName,
    this.brand = '',
    required this.calories,
    required this.carbs,
    required this.fats,
    required this.proteins,
    required this.serving,
    required this.timestamp,
    required this.date,
    this.isVerified = false,
    this.source = 'Local',
  });

// Create MealLog from Firestore document
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
      serving: data['serving'] ?? '1 serving', // Match field name from logfood
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      date: data['date'] ?? '',
      isVerified: data['isVerified'] ?? false,
      source: data['source'] ?? 'Local',
    );
  }

  // Convert to Map for saving to Firestore
  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'foodName': foodName,
      'brand': brand,
      'calories': calories,
      'carbs': carbs,
      'fats': fats,
      'proteins': proteins,
      'serving': serving,
      'timestamp': Timestamp.fromDate(timestamp),
      'date': date,
      'isVerified': isVerified,
      'source': source,
    };
  }
}