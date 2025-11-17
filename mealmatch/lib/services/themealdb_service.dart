import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';

class TheMealDBService {
  static const String baseUrl = 'https://www.themealdb.com/api/json/v1/1';

  // --- REMOVED: static final Random _random = Random(); ---
  // This was causing your sync bug. We will create a seeded Random locally.

  /// Generate realistic fake cooking time based on meal type
  static int _generateCookingTime(String mealName, Random random) { // <-- Added 'random' param
    final name = mealName.toLowerCase();
    
    // Quick meals (15-25 min)
    if (name.contains('sandwich') || name.contains('salad') || 
        name.contains('toast') || name.contains('smoothie')) {
      return 15 + random.nextInt(10); // <-- Use local 'random'
    }
    
    // Medium meals (25-45 min)
    if (name.contains('pasta') || name.contains('stir') || 
        name.contains('fried') || name.contains('noodle')) {
      return 25 + random.nextInt(20); // <-- Use local 'random'
    }
    
    // Slow meals (45-90 min)
    if (name.contains('roast') || name.contains('bake') || 
        name.contains('stew') || name.contains('curry')) {
      return 45 + random.nextInt(45); // <-- Use local 'random'
    }
    
    // Default: 30-50 minutes
    return 30 + random.nextInt(20); // <-- Use local 'random'
  }

  /// Generate realistic servings (2-6 people)
  static int _generateServings(Random random) { // <-- Added 'random' param
    return 2 + random.nextInt(5); // <-- Use local 'random'
  }

  /// Generate realistic nutrition values based on meal type
  static Map<String, dynamic> _generateNutrition(String mealName, Random random) { // <-- Added 'random' param
    final name = mealName.toLowerCase();
    
    int calories;
    int protein;
    int carbs;
    int fat;

    // High protein meals
    if (name.contains('chicken') || name.contains('beef') || 
        name.contains('pork') || name.contains('fish') || 
        name.contains('lamb') || name.contains('steak')) {
      calories = 450 + random.nextInt(200); // 450-650
      protein = 35 + random.nextInt(20);   // 35-55g
      carbs = 20 + random.nextInt(30);     // 20-50g
      fat = 15 + random.nextInt(15);       // 15-30g
    }
    // Pasta/Carb heavy
    else if (name.contains('pasta') || name.contains('rice') || 
             name.contains('noodle') || name.contains('pizza')) {
      calories = 500 + random.nextInt(250); // 500-750
      protein = 15 + random.nextInt(15);   // 15-30g
      carbs = 60 + random.nextInt(40);     // 60-100g
      fat = 12 + random.nextInt(18);       // 12-30g
    }
    // Salads/Light meals
    else if (name.contains('salad') || name.contains('soup') || 
             name.contains('sandwich')) {
      calories = 250 + random.nextInt(200); // 250-450
      protein = 12 + random.nextInt(18);   // 12-30g
      carbs = 25 + random.nextInt(25);     // 25-50g
      fat = 8 + random.nextInt(12);        // 8-20g
    }
    // Desserts/Sweets
    else if (name.contains('cake') || name.contains('pie') || 
             name.contains('pudding') || name.contains('cookie')) {
      calories = 350 + random.nextInt(300); // 350-650
      protein = 4 + random.nextInt(6);     // 4-10g
      carbs = 45 + random.nextInt(40);     // 45-85g
      fat = 15 + random.nextInt(20);       // 15-35g
    }
    // Default meals
    else {
      calories = 400 + random.nextInt(250); // 400-650
      protein = 25 + random.nextInt(20);   // 25-45g
      carbs = 35 + random.nextInt(30);     // 35-65g
      fat = 12 + random.nextInt(18);       // 12-30g
    }

    return {
      'calories': calories,
      'protein': '${protein}g',
      'carbs': '${carbs}g',
      'fat': '${fat}g',
    };
  }

  // --- FIXED: This code was outside a method ---
  static Future<List<Map<String, dynamic>>> findByIngredients(List<String> ingredients, {int number = 10}) async {
    if (ingredients.isEmpty) return [];

    try {
      // Use first ingredient for search
      final mainIngredient = ingredients.first.trim();
      final url = Uri.parse('$baseUrl/filter.php?i=${Uri.encodeComponent(mainIngredient)}');
      
      print('🔍 API URL: $url');
      print('🔍 Searching for: $mainIngredient');

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      print('📡 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['meals'] == null) {
          print('❌ API returned null meals');
          return [];
        }

        final meals = (data['meals'] as List).cast<Map<String, dynamic>>();
        print('✅ Found ${meals.length} meals from API');

        // Convert to our format WITH FAKE DATA
        final results = meals.take(number).map((meal) {
          final mealName = meal['strMeal'] ?? 'Unknown Recipe';
          print('  - $mealName (ID: ${meal['idMeal']})');
          
          // --- FIX: Create seeded random for consistent fake data ---
          final random = Random(meal['idMeal'].hashCode);

          return {
            'id': meal['idMeal']?.toString() ?? '',
            'title': mealName,
            'image': meal['strMealThumb'] ?? '',
            'missedIngredientCount': 0,
            'missedIngredients': [],
            // FAKE DATA
            'readyInMinutes': _generateCookingTime(mealName, random), // Pass random
            'servings': _generateServings(random), // Pass random
            'nutrition': _generateNutrition(mealName, random), // Pass random
          };
        }).toList();

        print('✅ Returning ${results.length} recipes with fake data');
        return results;
      } else {
        print('❌ API Error: Status ${response.statusCode}');
        return [];
      }
    } catch (e, stackTrace) {
      print('❌ Exception in findByIngredients: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Get full meal details including ingredients and instructions
  // --- FIXED: Removed the duplicate getMealDetails method ---
  static Future<Map<String, dynamic>?> getMealDetails(String mealId) async {
    try {
      final url = Uri.parse('$baseUrl/lookup.php?i=$mealId');
      print('🔍 Getting details for meal ID: $mealId');
      
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] != null && (data['meals'] as List).isNotEmpty) {
          final meal = data['meals'][0] as Map<String, dynamic>;
          
          // Parse ingredients and measurements
          final ingredients = <Map<String, String>>[];
          for (int i = 1; i <= 20; i++) {
            final ingredient = meal['strIngredient$i']?.toString().trim() ?? '';
            final measure = meal['strMeasure$i']?.toString().trim() ?? '';
            
            if (ingredient.isNotEmpty) {
              ingredients.add({
                'name': ingredient,
                'measure': measure,
                'original': measure.isNotEmpty ? '$measure $ingredient' : ingredient,
              });
            }
          }

          final mealName = meal['strMeal'] ?? 'Unknown Recipe';
          print('✅ Loaded details for: $mealName');

          // --- FIX: Create seeded random for consistent fake data ---
          final random = Random(mealId.hashCode);
          
          return {
            'id': meal['idMeal'],
            'title': mealName,
            'image': meal['strMealThumb'],
            'instructions': meal['strInstructions'] ?? '',
            'ingredients': ingredients,
            'category': meal['strCategory'] ?? '',
            'area': meal['strArea'] ?? '',
            'youtubeUrl': meal['strYoutube'] ?? '',
            'sourceUrl': meal['strSource'] ?? '',
            // FAKE DATA
            'readyInMinutes': _generateCookingTime(mealName, random), // Pass random
            'servings': _generateServings(random), // Pass random
            'nutrition': _generateNutrition(mealName, random), // Pass random
            'author': (meal['strSource'] != null && meal['strSource'].isNotEmpty) 
              ? Uri.tryParse(meal['strSource'])?.host.replaceAll('www.', '') ?? 'TheMealDB'
              : 'TheMealDB Community',
          };
        }
      }
      print('❌ Failed to get meal details');
      return null;
    } catch (e) {
      print('❌ Error getting meal details: $e');
      return null;
    }
  }

  // --- REPLACE this method in mealdb_service.dart ---
  static Future<List<Map<String, dynamic>>> searchRecipes(String query) async {
    try {
      final url = Uri.parse('$baseUrl/search.php?s=${Uri.encodeComponent(query)}');
      print('🔍 Searching recipes: $query');
      
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['meals'] == null) {
          print('⚠️ No meals found for: $query');
          return [];
        }

        final meals = (data['meals'] as List).cast<Map<String, dynamic>>();
        print('✅ Found ${meals.length} recipes');
        
        return meals.map((meal) {
          final mealName = meal['strMeal'] ?? 'Unknown Recipe';
          
          // --- FIX: Create seeded random for consistent fake data ---
          final random = Random(meal['idMeal'].hashCode);

          return {
            'id': meal['idMeal'],
            'title': mealName,
            'category': meal['strCategory'] ?? '',
            'area': meal['strArea'] ?? '',
            'image': meal['strMealThumb'],
            // FAKE DATA
            'readyInMinutes': _generateCookingTime(mealName, random),
            'servings': _generateServings(random),
            'rating': 4.0 + random.nextDouble(), // Add missing rating
            'author': ['Foodista', 'Tasty', 'AllRecipes'][random.nextInt(3)], // Add missing author
            'nutrition': _generateNutrition(mealName, random), // <-- FIX: ADD NUTRITION
          };
        }).toList();
      }
      
      return [];
    } catch (e) {
      print('❌ Error searching recipes: $e');
      return [];
    }
  }

  // In lib/services/themealdb_service.dart

  static Future<List<Map<String, dynamic>>> getRandomMeals(int count) async {
    final meals = <Map<String, dynamic>>[];
    
    try {
      for (int i = 0; i < count; i++) {
        final url = Uri.parse('$baseUrl/random.php');
        final response = await http.get(url).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['meals'] != null && (data['meals'] as List).isNotEmpty) {
            final meal = data['meals'][0];
            final mealName = meal['strMeal'] ?? 'Unknown Recipe';
            
            // --- FIX: Create seeded random for consistent fake data ---
            final random = Random(meal['idMeal'].hashCode);

            meals.add({
              'id': meal['idMeal'],
              'title': mealName,
              'category': meal['strCategory'] ?? '',
              'area': meal['strArea'] ?? '',
              'image': meal['strMealThumb'],
              
              // --- FAKE DATA ---
              'readyInMinutes': _generateCookingTime(mealName, random),
              'servings': _generateServings(random),
              'rating': 4.0 + random.nextDouble(), // Add missing rating
              'author': ['Foodista', 'Tasty', 'AllRecipes'][random.nextInt(3)], // Add missing author
              'nutrition': _generateNutrition(mealName, random), // <-- THIS ADDS KCAL
            });
          }
        }
      }
      print('✅ Loaded ${meals.length} random meals');
    } catch (e) {
      print('❌ Error getting random meals: $e');
    }
    
    return meals;
  }
  

  static Future<List<Map<String, dynamic>>> getMealsByCategory(
    String category, {
    int number = 6, // Get 6 meals by default
  }) async {
    try {
      final url = Uri.parse('$baseUrl/filter.php?c=${Uri.encodeComponent(category)}');
      print('🔍 Getting meals for category: $category');
      
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['meals'] == null) {
          print('❌ API returned null meals for category $category');
          return [];
        }

        final meals = (data['meals'] as List).cast<Map<String, dynamic>>();
        print('✅ Found ${meals.length} meals from API for $category');

        // We take the first 'number' of meals and get their full details
        // so we can show fake data like cook time, calories, etc.
        final detailedMeals = <Map<String, dynamic>>[];
        
        for (var meal in meals.take(number)) {
          final details = await getMealDetails(meal['idMeal']);
          if (details != null) {
            detailedMeals.add(details);
          }
        }
        
        print('✅ Returning ${detailedMeals.length} detailed meals');
        return detailedMeals;
        
      } else {
        print('❌ API Error: Status ${response.statusCode}');
        return [];
      }
    } catch (e, stackTrace) {
      print('❌ Exception in getMealsByCategory: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }
}
