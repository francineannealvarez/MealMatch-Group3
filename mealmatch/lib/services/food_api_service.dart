// 📁 lib/services/food_api_service.dart
// ============================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class FoodApiService {
  static const String usdaApiKey = 'QGUrntEEaTNFFHkrLRk7h8Lr8Vh9Uf6O5DVGhDsV';
  static const String usdaBaseUrl = 'https://api.nal.usda.gov/fdc/v1';
  static const String offBaseUrl = 'https://world.openfoodfacts.org/cgi';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Search foods in USDA database
  Future<List<Map<String, dynamic>>> searchUsdaFoods(String query) async {
    try {
      final url = Uri.parse(
        '$usdaBaseUrl/foods/search?query=$query&pageSize=10&api_key=$usdaApiKey',
      );

      print('🔍 Searching USDA: $query');

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final foods = data['foods'] as List;

        print('✅ USDA found ${foods.length} items');

        return foods.map((food) {
          return _parseUsdaFood(food);
        }).toList();
      } else {
        print('❌ USDA API Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error searching USDA foods: $e');
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

    double servingAmount = 100.0;
    String servingUnit = 'g';

    if (usdaFood['householdServingFullText'] != null) {
      final householdServing = usdaFood['householdServingFullText'].toString();
      final match = RegExp(
        r'(\d+\.?\d*)\s*([a-zA-Z]+)',
      ).firstMatch(householdServing);
      if (match != null) {
        servingAmount = double.tryParse(match.group(1) ?? '1') ?? 1.0;
        servingUnit = match.group(2) ?? 'serving';
      }
    } else if (usdaFood['servingSize'] != null) {
      servingAmount = (usdaFood['servingSize'] is int)
          ? (usdaFood['servingSize'] as int).toDouble()
          : (usdaFood['servingSize'] as double? ?? 100.0);
      servingUnit = usdaFood['servingSizeUnit'] ?? 'g';
    }

    return {
      'name': usdaFood['description'] ?? 'Unknown',
      'brand': usdaFood['brandOwner'] ?? '',
      'calories': getUsdaNutrient(1008),
      'carbs': getUsdaNutrient(1005),
      'protein': getUsdaNutrient(1003),
      'fat': getUsdaNutrient(1004),
      'servingsamount': servingAmount,
      'servingsize': servingUnit,
      'source': 'USDA',
      'usdaFdcId': usdaFood['fdcId'],
    };
  }

  /// Search foods in Open Food Facts
  Future<List<Map<String, dynamic>>> searchOpenFoodFacts(String query) async {
    try {
      final url = Uri.parse(
        '$offBaseUrl/search.pl?search_terms=$query&page_size=20&json=1',
      );

      print('🔍 Searching Open Food Facts: $query');

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final products = (data['products'] as List?) ?? [];

        print('📦 OFF returned ${products.length} products');

        if (products.isEmpty) {
          print('❌ No products found');
          return [];
        }

        final parsedProducts = <Map<String, dynamic>>[];

        for (var product in products) {
          try {
            final parsed = _parseOpenFoodFactsProduct(product);

            if (parsed['name'] != 'Unknown Product' &&
                (parsed['calories'] > 0 ||
                    parsed['carbs'] > 0 ||
                    parsed['protein'] > 0)) {
              parsedProducts.add(parsed);
              print('✅ Added: ${parsed['name']} - ${parsed['calories']} cal');
            } else {
              print('⚠️ Skipped incomplete: ${parsed['name']}');
            }
          } catch (e) {
            print('❌ Error parsing product: $e');
          }
        }

        print('📋 Final count: ${parsedProducts.length} valid products');
        return parsedProducts;
      } else {
        print('❌ OFF API Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error searching Open Food Facts: $e');
      return [];
    }
  }

  /// Get product by barcode from Open Food Facts
  Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
    try {
      final url = Uri.parse(
        'https://world.openfoodfacts.org/api/v2/product/$barcode.json',
      );
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
        dynamic value = nutriments['${key}_100g'];
        if (value == null) value = nutriments['${key}-100g'];
        if (value == null) value = nutriments[key];
        if (value == null) value = nutriments['${key}_serving'];

        if (value == null) return 0.0;

        if (value is num) return value.toDouble();
        if (value is String) return double.tryParse(value) ?? 0.0;

        return 0.0;
      } catch (e) {
        return 0.0;
      }
    }

    String productName =
        product['product_name'] as String? ??
        product['product_name_en'] as String? ??
        product['generic_name'] as String? ??
        'Unknown Product';

    String brand =
        product['brands'] as String? ?? product['brand_owner'] as String? ?? '';

    String servingSize = 'g';
    double servingAmount = 100.0;

    if (product['serving_size'] != null) {
      final serving = product['serving_size'].toString();
      final match = RegExp(r'(\d+\.?\d*)\s*([a-zA-Z]+)').firstMatch(serving);
      if (match != null) {
        servingAmount = double.tryParse(match.group(1) ?? '100') ?? 100.0;
        servingSize = match.group(2) ?? 'g';
      }
    } else if (product['quantity'] != null) {
      final quantity = product['quantity'].toString();
      final match = RegExp(r'(\d+\.?\d*)\s*([a-zA-Z]+)').firstMatch(quantity);
      if (match != null) {
        servingAmount = double.tryParse(match.group(1) ?? '100') ?? 100.0;
        servingSize = match.group(2) ?? 'g';
      }
    }

    double calories = getNutriment('energy-kcal');
    if (calories == 0) {
      double energyKj = getNutriment('energy-kj');
      if (energyKj > 0) {
        calories = energyKj / 4.184;
      } else {
        calories = getNutriment('energy') / 4.184;
      }
    }

    return {
      'name': productName,
      'brand': brand,
      'calories': calories,
      'carbs': getNutriment('carbohydrates'),
      'protein': getNutriment('proteins'),
      'fat': getNutriment('fat'),
      'servingsamount': servingAmount,
      'servingsize': servingSize,
      'source': 'OpenFoodFacts',
      'barcode': product['code']?.toString() ?? '',
    };
  }

  /// Search both USDA and Open Food Facts
  Future<List<Map<String, dynamic>>> searchAllSources(String query) async {
    final results = <Map<String, dynamic>>[];

    final usdaResults = await searchUsdaFoods(query);
    results.addAll(usdaResults);

    final offResults = await searchOpenFoodFacts(query);
    results.addAll(offResults);

    print('🎯 Total results from all sources: ${results.length}');

    return results;
  }

  /// Save food to Firestore
  Future<void> saveFoodToFirestore(Map<String, dynamic> foodData) async {
    try {
      final cleanData = Map<String, dynamic>.from(foodData);
      cleanData.remove('usdaFdcId');
      cleanData.remove('barcode');

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

      final docRef = _firestore.collection('foods').doc();
      batch.set(docRef, cleanData);
      count++;

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
