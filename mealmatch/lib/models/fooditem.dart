// 📁 lib/models/fooditem.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class FoodItem {
  final String id;
  final String name;
  final String brand;
  final double calories;
  final double carbs;
  final double protein;
  final double fat;
  final String servingsize;
  final List<String> servingOptions;
  final bool isVerified; // ← NEW: Verified mark
  final String source; // ← NEW: Track source (USDA, OFF, Local)

  FoodItem({
    required this.id,
    required this.name,
    required this.brand,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.servingsize,
    this.servingOptions = const [],
    this.isVerified = false,
    this.source = 'Local',
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
      'servingsize': servingsize,
      'servingOptions': servingOptions,
      'isVerified': isVerified,
      'source': source,
    };
  }

  // Create FoodItem from Firestore document
  factory FoodItem.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FoodItem(
      id: doc.id,
      name: _toTitleCase(data['name'] ?? ''),
      brand: _normalizeBrand(data['brand'] ?? ''),
      calories: (data['calories'] ?? 0).toDouble(),
      carbs: (data['carbs'] ?? 0).toDouble(),
      protein: (data['protein'] ?? 0).toDouble(),
      fat: (data['fat'] ?? 0).toDouble(),
      servingsize: data['servingsize'] ?? '',
      servingOptions: List<String>.from(data['servingOptions'] ?? []),
      isVerified: data['isVerified'] ?? false,
      source: data['source'] ?? 'Local',
    );
  }

  // Create FoodItem from API data
  factory FoodItem.fromApiData(Map<String, dynamic> data) {
    final amount = data['servingsamount'] ?? 100;
    final size = data['servingsize'] ?? 'g';
    final serving = '$amount $size';
    final source = data['source'] ?? 'Unknown';

    // API foods are always verified
    final isVerified = source == 'USDA' || source == 'OpenFoodFacts';

    List<String> options = [];

    if (data['servings'] != null && data['servings'] is List) {
      options = (data['servings'] as List)
          .map((s) => '${s['amount']} ${s['unit']}')
          .toList()
          .cast<String>();
    }

    if (options.isEmpty) {
      options = _generateServingOptions(serving);
    }

    return FoodItem(
      id: 'api_${data['name']}_${DateTime.now().millisecondsSinceEpoch}',
      name: _toTitleCase(data['name'] ?? ''),
      brand: _normalizeBrand(data['brand'] ?? ''),
      calories: (data['calories'] ?? 0).toDouble(),
      carbs: (data['carbs'] ?? 0).toDouble(),
      protein: (data['protein'] ?? 0).toDouble(),
      fat: (data['fat'] ?? 0).toDouble(),
      servingsize: serving,
      servingOptions: options,
      isVerified: isVerified,
      source: source,
    );
  }

  // Create FoodItem from meal log data
  factory FoodItem.fromMealLog(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final serving = data['serving'] ?? '100 g';
    List<String> options = _generateServingOptions(serving);

    return FoodItem(
      id: doc.id,
      name: _toTitleCase(data['foodName'] ?? ''),
      brand: _normalizeBrand(data['brand'] ?? ''),
      calories: (data['calories'] ?? 0).toDouble(),
      carbs: (data['carbs'] ?? 0).toDouble(),
      protein: (data['proteins'] ?? 0).toDouble(),
      fat: (data['fats'] ?? 0).toDouble(),
      servingsize: serving,
      servingOptions: options,
      isVerified: data['isVerified'] ?? false,
      source: data['source'] ?? 'Local',
    );
  }

  // Helper to generate serving options based on unit
  static List<String> _generateServingOptions(String serving) {
    final parts = serving.split(' ');
    if (parts.length < 2) return ['1 serving', '2 servings', '3 servings'];

    final unit = parts[1];

    if (unit == 'g' || unit == 'gram') {
      return ['50 g', '100 g', '150 g', '200 g', '250 g', '300 g'];
    } else if (unit == 'ml') {
      return ['100 ml', '200 ml', '250 ml', '500 ml', '750 ml', '1000 ml'];
    } else if (unit == 'cup' || unit == 'cups') {
      return ['0.5 cup', '1 cup', '1.5 cups', '2 cups', '3 cups'];
    } else if (unit == 'piece' || unit == 'pieces') {
      return ['1 piece', '2 pieces', '3 pieces', '4 pieces', '5 pieces'];
    } else if (unit == 'bowl' || unit == 'bowls') {
      return ['0.5 bowl', '1 bowl', '1.5 bowls', '2 bowls'];
    } else if (unit == 'plate' || unit == 'plates') {
      return ['0.5 plate', '1 plate', '1.5 plates', '2 plates'];
    } else {
      return [
        '0.5 $unit',
        '1 $unit',
        '1.5 $unit',
        '2 $unit',
        '3 $unit',
        '4 $unit',
      ];
    }
  }

  // Text normalization helpers
  static String _toTitleCase(String text) {
    if (text.isEmpty) return text;

    text = text.trim();

    final lowercaseWords = {'and', 'or', 'with', 'in', 'of', 'the', 'a', 'an'};
    final words = text.split(' ');
    final result = <String>[];

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      if (word.isEmpty) continue;

      if (word.length <= 3 && word == word.toUpperCase()) {
        result.add(word);
        continue;
      }

      if (i == 0) {
        result.add(word[0].toUpperCase() + word.substring(1).toLowerCase());
        continue;
      }

      if (lowercaseWords.contains(word.toLowerCase())) {
        result.add(word.toLowerCase());
        continue;
      }

      result.add(word[0].toUpperCase() + word.substring(1).toLowerCase());
    }

    return result.join(' ');
  }

  static String _normalizeBrand(String brand) {
    if (brand.isEmpty) return brand;

    final brandLower = brand.toLowerCase();

    // Filipino brands
    if (brandLower.contains('nissin')) return 'Nissin';
    if (brandLower.contains('lucky me')) return 'Lucky Me!';
    if (brandLower.contains('payless')) return 'Payless';
    if (brandLower.contains('jack n jill')) return "Jack 'n Jill";
    if (brandLower.contains('monde')) return 'Monde Nissin';
    if (brandLower.contains('liwayway')) return 'Liwayway';
    if (brandLower.contains('energen')) return 'Energen';
    if (brandLower.contains('maggi')) return 'Maggi';
    if (brandLower.contains('knorr')) return 'Knorr';
    if (brandLower.contains('del monte')) return 'Del Monte';
    if (brandLower.contains('san miguel')) return 'San Miguel';
    if (brandLower.contains('coca cola') || brandLower.contains('coca-cola'))
      return 'Coca-Cola';
    if (brandLower.contains('pepsi')) return 'Pepsi';
    if (brandLower.contains('nestle')) return 'Nestlé';

    return _toTitleCase(brand);
  }
}
