// 📁 lib/services/food_api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class FoodApiService {
  static const String usdaApiKey = 'QGUrntEEaTNFFHkrLRk7h8Lr8Vh9Uf6O5DVGhDsV';
  static const String usdaBaseUrl = 'https://api.nal.usda.gov/fdc/v1';

  // Open Food Facts API (no key needed!)
  static const String offBaseUrl = 'https://world.openfoodfacts.org/api/v2';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================
  // USDA FOOD DATA CENTRAL
  // ============================================

  /// Search foods in USDA database
  Future<List<Map<String, dynamic>>> searchUsdaFoods(String query) async {
    try {
      final url = Uri.parse(
        '$usdaBaseUrl/foods/search?query=$query&pageSize=10&api_key=$usdaApiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final foods = data['foods'] as List;

        return foods.map((food) {
          return _parseUsdaFood(food);
        }).toList();
      } else {
        print('USDA API Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error searching USDA foods: $e');
      return [];
    }
  }

  /// Parse USDA food data to our format
  Map<String, dynamic> _parseUsdaFood(Map<String, dynamic> usdaFood) {
    final nutrients = usdaFood['foodNutrients'] as List? ?? [];

    double getUsdaNutrient(int nutrientId) {
      try {
        final nutrient = nutrients.firstWhere(
          (n) => n['nutrientId'] == nutrientId,
          orElse: () => {'value': 0.0},
        );
        return (nutrient['value'] ?? 0.0).toDouble();
      } catch (e) {
        return 0.0;
      }
    }

    // Get actual serving size from USDA data
    double servingAmount = 100.0;
    String servingUnit = 'g';

    // Check for household serving first (more user-friendly)
    if (usdaFood['householdServingFullText'] != null) {
      final householdServing = usdaFood['householdServingFullText'].toString();
      // Parse formats like "1 cup", "1 piece", "3 oz"
      final match = RegExp(
        r'(\d+\.?\d*)\s*([a-zA-Z]+)',
      ).firstMatch(householdServing);
      if (match != null) {
        servingAmount = double.tryParse(match.group(1) ?? '1') ?? 1.0;
        servingUnit = match.group(2) ?? 'serving';
      }
    } else if (usdaFood['servingSize'] != null) {
      // Fallback to servingSize in grams
      servingAmount = (usdaFood['servingSize'] is int)
          ? (usdaFood['servingSize'] as int).toDouble()
          : (usdaFood['servingSize'] as double? ?? 100.0);
      servingUnit = usdaFood['servingSizeUnit'] ?? 'g';
    }

    return {
      'name': usdaFood['description'] ?? 'Unknown',
      'brand': usdaFood['brandOwner'] ?? '',
      'calories': getUsdaNutrient(1008), // Energy (kcal)
      'carbs': getUsdaNutrient(1005), // Carbohydrates
      'protein': getUsdaNutrient(1003), // Protein
      'fat': getUsdaNutrient(1004), // Total Fat
      'servingsamount': servingAmount,
      'servingsize': servingUnit,
      'source': 'USDA',
      'usdaFdcId': usdaFood['fdcId'],
    };
  }

  // ============================================
  // OPEN FOOD FACTS
  // ============================================

  /// Search foods in Open Food Facts
  Future<List<Map<String, dynamic>>> searchOpenFoodFacts(String query) async {
    try {
      final url = Uri.parse(
        '$offBaseUrl/search?search_terms=$query&page_size=10&fields=product_name,brands,nutriments,serving_size,code',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final products = data['products'] as List? ?? [];

        return products.map((product) {
          return _parseOpenFoodFactsProduct(product);
        }).toList();
      } else {
        print('Open Food Facts API Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error searching Open Food Facts: $e');
      return [];
    }
  }

  /// Get product by barcode from Open Food Facts
  Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
    try {
      final url = Uri.parse('$offBaseUrl/product/$barcode.json');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 1) {
          return _parseOpenFoodFactsProduct(data['product']);
        }
      }
      return null;
    } catch (e) {
      print('Error getting product by barcode: $e');
      return null;
    }
  }

  /// Parse Open Food Facts product to our format
  Map<String, dynamic> _parseOpenFoodFactsProduct(
    Map<String, dynamic> product,
  ) {
    final nutriments = product['nutriments'] as Map<String, dynamic>? ?? {};

    double getNutriment(String key) {
      try {
        final value = nutriments['${key}_100g'];
        if (value == null) return 0.0;
        return (value is int) ? value.toDouble() : (value as double);
      } catch (e) {
        return 0.0;
      }
    }

    // Parse serving size from Open Food Facts
    String servingSize = 'g';
    double servingAmount = 100.0;

    if (product['serving_size'] != null) {
      final serving = product['serving_size'].toString();
      // Try to parse formats like "100g", "1 piece", "250 ml"
      final match = RegExp(r'(\d+\.?\d*)\s*([a-zA-Z]+)').firstMatch(serving);
      if (match != null) {
        servingAmount = double.tryParse(match.group(1) ?? '100') ?? 100.0;
        servingSize = match.group(2) ?? 'g';
      }
    }

    return {
      'name': product['product_name'] ?? 'Unknown',
      'brand': product['brands'] ?? '',
      'calories': getNutriment('energy-kcal'),
      'carbs': getNutriment('carbohydrates'),
      'protein': getNutriment('proteins'),
      'fat': getNutriment('fat'),
      'servingsamount': servingAmount,
      'servingsize': servingSize,
      'source': 'OpenFoodFacts',
      'barcode': product['code'],
    };
  }

  // ============================================
  // COMBINED SEARCH
  // ============================================

  /// Search both USDA and Open Food Facts
  Future<List<Map<String, dynamic>>> searchAllSources(String query) async {
    final results = <Map<String, dynamic>>[];

    // Search USDA
    final usdaResults = await searchUsdaFoods(query);
    results.addAll(usdaResults);

    // Search Open Food Facts
    final offResults = await searchOpenFoodFacts(query);
    results.addAll(offResults);

    return results;
  }

  // ============================================
  // SAVE TO FIRESTORE
  // ============================================

  /// Save food to Firestore
  Future<void> saveFoodToFirestore(Map<String, dynamic> foodData) async {
    try {
      // Remove source-specific IDs before saving
      final cleanData = Map<String, dynamic>.from(foodData);
      cleanData.remove('usdaFdcId');
      cleanData.remove('barcode');
      cleanData.remove('source');

      await _firestore.collection('foods').add(cleanData);
      print('Food saved: ${foodData['name']}');
    } catch (e) {
      print('Error saving food to Firestore: $e');
      rethrow;
    }
  }

  /// Batch import foods to Firestore
  Future<void> batchImportFoods(List<Map<String, dynamic>> foods) async {
    final batch = _firestore.batch();
    int count = 0;

    for (var food in foods) {
      final cleanData = Map<String, dynamic>.from(food);
      cleanData.remove('usdaFdcId');
      cleanData.remove('barcode');
      cleanData.remove('source');

      final docRef = _firestore.collection('foods').doc();
      batch.set(docRef, cleanData);
      count++;

      // Firestore batch limit is 500
      if (count >= 500) {
        await batch.commit();
        print('Batch committed: $count foods');
        count = 0;
      }
    }

    if (count > 0) {
      await batch.commit();
      print('Final batch committed: $count foods');
    }
  }
}
