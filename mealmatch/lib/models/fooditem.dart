// 📁 lib/models/food_item.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class FoodItem {
  final String id; // Document ID from Firestore
  final String name;
  final String brand;
  final double calories;
  final double carbs;
  final double protein;
  final double fat;
  final double servingsamount;
  final String servingsize;

  FoodItem({
    required this.id,
    required this.name,
    required this.brand,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.servingsamount,
    required this.servingsize,
  });

  // Convert to Map for saving to Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'brand': brand,
      'calories': calories,
      'carbs': carbs,
      'protein': protein,
      'fat': fat,
      'servingsamount': servingsamount,
      'servingsize': servingsize,
    };
  }

  // Create FoodItem from Firestore document
  factory FoodItem.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FoodItem(
      id: doc.id,
      name: data['name'] ?? '',
      brand: data['brand'] ?? '',
      calories: (data['calories'] ?? 0).toDouble(),
      carbs: (data['carbs'] ?? 0).toDouble(),
      protein: (data['protein'] ?? 0).toDouble(),
      fat: (data['fat'] ?? 0).toDouble(),
      servingsamount: (data['servingsamount'] ?? 0).toDouble(),
      servingsize: data['servingsize'] ?? '',
    );
  }
}
