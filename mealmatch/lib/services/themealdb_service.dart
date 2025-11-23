import 'dart:convert';
import 'package:http/http.dart' as http;

class TheMealDBService {
  static const String baseUrl = 'https://www.themealdb.com/api/json/v1/1';
  
  // Generates consistent cooking time based on meal name and ID
  // Same recipe = same cook time always
  static int _generateCookingTime(String mealName, String mealId) {
    final name = mealName.toLowerCase();
    
    // Use meal ID hash to generate a consistent pseudo-random number (0-99)
    final idHash = mealId.hashCode.abs() % 100;
    
    int baseTime;
    int variation;

    if (name.contains('sandwich') || name.contains('salad') || 
        name.contains('toast') || name.contains('smoothie')) {
      baseTime = 15;
      variation = 10; // Will be 15-25 minutes
    }
    else if (name.contains('pasta') || name.contains('stir') || 
        name.contains('fried') || name.contains('noodle')) {
      baseTime = 25;
      variation = 20; // Will be 25-45 minutes
    }
    else if (name.contains('roast') || name.contains('bake') || 
        name.contains('stew') || name.contains('curry')) {
      baseTime = 45;
      variation = 45; // Will be 45-90 minutes
    }
    else {
      baseTime = 30;
      variation = 20; // Will be 30-50 minutes (default)
    }
    
    // Use hash to determine variation (consistent per recipe)
    final calculatedTime = baseTime + ((idHash * variation) ~/ 100);
    return _roundToNearestFive(calculatedTime);
  }

  // Generates consistent servings (2-6) based on meal ID
  static int _generateServings(String mealId) {
    // Use meal ID hash for consistent servings (2-6)
    final idHash = mealId.hashCode.abs() % 5;
    return 2 + idHash;
  }

  // Generates consistent nutrition based on meal type and ID
  // ⚠️ NOTE: This is estimated data - TheMealDB API doesn't provide nutrition info
  static Map<String, dynamic> _generateNutrition(String mealName, String mealId) {
    final name = mealName.toLowerCase();
    
    // Use meal ID hash for consistent variation
    final idHash = mealId.hashCode.abs() % 100;
    
    int calories;
    int protein;
    int carbs;
    int fat;

    // High protein meals
    if (name.contains('chicken') || name.contains('beef') || 
        name.contains('pork') || name.contains('fish') || 
        name.contains('lamb') || name.contains('steak')) {
      calories = 450 + ((idHash * 200) ~/ 100);
      protein = 35 + ((idHash * 20) ~/ 100);
      carbs = 20 + ((idHash * 30) ~/ 100);
      fat = 15 + ((idHash * 15) ~/ 100);
    }
    // Pasta/Carb heavy
    else if (name.contains('pasta') || name.contains('rice') || 
            name.contains('noodle') || name.contains('pizza')) {
      calories = 500 + ((idHash * 250) ~/ 100);
      protein = 15 + ((idHash * 15) ~/ 100);
      carbs = 60 + ((idHash * 40) ~/ 100);
      fat = 12 + ((idHash * 18) ~/ 100);
    }
    // Salads/Light meals
    else if (name.contains('salad') || name.contains('soup') || 
            name.contains('sandwich')) {
      calories = 250 + ((idHash * 200) ~/ 100);
      protein = 12 + ((idHash * 18) ~/ 100);
      carbs = 25 + ((idHash * 25) ~/ 100);
      fat = 8 + ((idHash * 12) ~/ 100);
    }
    // Desserts/Sweets
    else if (name.contains('cake') || name.contains('pie') || 
            name.contains('pudding') || name.contains('cookie')) {
      calories = 350 + ((idHash * 300) ~/ 100);
      protein = 4 + ((idHash * 6) ~/ 100);
      carbs = 45 + ((idHash * 40) ~/ 100);
      fat = 15 + ((idHash * 20) ~/ 100);
    }
    // Default meals
    else {
      calories = 400 + ((idHash * 250) ~/ 100);
      protein = 25 + ((idHash * 20) ~/ 100);
      carbs = 35 + ((idHash * 30) ~/ 100);
      fat = 12 + ((idHash * 18) ~/ 100);
    }

    return {
      'calories': calories,
      'protein': '${protein}g',
      'carbs': '${carbs}g',
      'fat': '${fat}g',
    };
  }

  // Intelligently parses instructions into numbered steps and handles both pre-numbered steps and long paragraphs
  static List<Map<String, String>> _parseInstructions(String? rawInstructions) {
    if (rawInstructions == null || rawInstructions.isEmpty) {
      return [];
    }

    // Clean up the text
    String cleaned = rawInstructions
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .trim();

    List<String> steps = [];

    // Method 1: Check if already numbered (STEP 1, Step 1, 1., etc.)
    final stepPattern = RegExp(
      r'(?:STEP\s*\d+|Step\s*\d+|\d+\.)\s*[:\-]?\s*',
      caseSensitive: false,
    );

    if (stepPattern.hasMatch(cleaned)) {
      // Split by step numbers
      final parts = cleaned.split(stepPattern);
      steps = parts
          .where((s) => s.trim().isNotEmpty)
          .map((s) => s.trim())
          .toList();
    } else {
      // Method 2: Split by periods followed by capital letters (sentence detection)
      final sentences = cleaned.split(RegExp(r'\.\s+(?=[A-Z])'));
      
      // Group sentences into logical steps (max 2-3 sentences per step)
      List<String> currentStep = [];
      
      for (var sentence in sentences) {
        sentence = sentence.trim();
        if (sentence.isEmpty) continue;
        
        currentStep.add(sentence);
        
        // Create a new step every 2 sentences, or if sentence is long
        if (currentStep.length >= 2 || sentence.length > 150) {
          steps.add(currentStep.join('. ') + '.');
          currentStep = [];
        }
      }
      
      // Add remaining sentences
      if (currentStep.isNotEmpty) {
        steps.add(currentStep.join('. ') + '.');
      }
    }

    // Convert to Map format with step numbers
    return steps.asMap().entries.map((entry) {
      return {
        'text': entry.value,
        'timer': '00:00', // No timer data available from API
      };
    }).toList();
  }

  // Rounds an integer to the nearest multiple of 5
  static int _roundToNearestFive(int number) {
    return (number / 5).round() * 5;
  }

  // Find recipes by ingredients
  static Future<List<Map<String, dynamic>>> findByIngredients(
    List<String> ingredients, 
    {int number = 10}
  ) async {
    if (ingredients.isEmpty) return [];

    try {
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

        final results = meals.take(number).map((meal) {
          final mealName = meal['strMeal'] ?? 'Unknown Recipe';
          final mealId = meal['idMeal']?.toString() ?? '';
          print('  - $mealName (ID: $mealId)');

          return {
            'id': mealId,
            'title': mealName,
            'image': meal['strMealThumb'] ?? '',
            'missedIngredientCount': 0,
            'missedIngredients': [],
            'readyInMinutes': _generateCookingTime(mealName, mealId),
            'servings': _generateServings(mealId),
            'nutrition': _generateNutrition(mealName, mealId),
          };
        }).toList();

        print('✅ Returning ${results.length} recipes with data');
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

  /// Get detailed information about a specific meal
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
          
          // Generate consistent cook time
          final cookTime = _generateCookingTime(mealName, mealId);
          
          // Parse instructions into steps
          final instructions = _parseInstructions(meal['strInstructions']);

          return {
            'id': meal['idMeal'],
            'title': mealName,
            'image': meal['strMealThumb'],
            'instructions': instructions, // ✅ Now a List of steps
            'ingredients': ingredients,
            'category': meal['strCategory'] ?? '',
            'area': meal['strArea'] ?? '',
            'youtubeUrl': meal['strYoutube'] ?? '',
            'sourceUrl': meal['strSource'] ?? '',
            
            // ⚠️ ESTIMATED DATA (API doesn't provide these):
            'prepTime': '10', // Fixed estimate
            'cookTime': cookTime.toString(),
            'readyInMinutes': cookTime,
            'servings': _generateServings(mealId),
            'nutrition': _generateNutrition(mealName, mealId),
            'rating': 4.0 + ((mealId.hashCode.abs() % 100) / 100),
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

  /// Search recipes by name
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
          final mealId = meal['idMeal'].toString();

          return {
            'id': mealId,
            'title': mealName,
            'category': meal['strCategory'] ?? '',
            'area': meal['strArea'] ?? '',
            'image': meal['strMealThumb'],
            'readyInMinutes': _generateCookingTime(mealName, mealId),
            'servings': _generateServings(mealId),
            'rating': 4.0 + ((mealId.hashCode.abs() % 100) / 100),
            'author': ['Foodista', 'Tasty', 'AllRecipes'][mealId.hashCode.abs() % 3],
            'nutrition': _generateNutrition(mealName, mealId),
          };
        }).toList();
      }
      
      return [];
    } catch (e) {
      print('❌ Error searching recipes: $e');
      return [];
    }
  }

  /// Get random meals (loads in parallel for better performance)
  static Future<List<Map<String, dynamic>>> getRandomMeals(int count) async {
    try {
      print('🎲 Loading $count random meals in parallel...');
      
      // Create multiple API requests at once
      final requests = List.generate(
        count,
        (_) => http.get(Uri.parse('$baseUrl/random.php')).timeout(
          const Duration(seconds: 10),
        ),
      );
      
      // Wait for all requests to complete together
      final responses = await Future.wait(requests);
      final meals = <Map<String, dynamic>>[];
      
      for (final response in responses) {
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['meals'] != null && (data['meals'] as List).isNotEmpty) {
            final meal = data['meals'][0];
            final mealName = meal['strMeal'] ?? 'Unknown Recipe';
            final mealId = meal['idMeal'].toString();

            meals.add({
              'id': mealId,
              'title': mealName,
              'category': meal['strCategory'] ?? '',
              'area': meal['strArea'] ?? '',
              'image': meal['strMealThumb'],
              'readyInMinutes': _generateCookingTime(mealName, mealId),
              'servings': _generateServings(mealId),
              'rating': 4.0 + ((mealId.hashCode.abs() % 100) / 100),
              'author': ['Foodista', 'Tasty', 'AllRecipes'][mealId.hashCode.abs() % 3],
              'nutrition': _generateNutrition(mealName, mealId),
            });
          }
        }
      }
      
      print('✅ Loaded ${meals.length} random meals in parallel');
      return meals;
      
    } catch (e) {
      print('❌ Error getting random meals: $e');
      return [];
    }
  }

  /// Get meals by category with full details
  static Future<List<Map<String, dynamic>>> getMealsByCategory(
    String category, {
    int number = 6,
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

        // Fetch details in parallel for faster loading
        final detailRequests = meals
            .take(number)
            .map((meal) => getMealDetails(meal['idMeal']))
            .toList();
        
        final detailsResults = await Future.wait(detailRequests);
        
        final detailedMeals = detailsResults
            .where((details) => details != null)
            .cast<Map<String, dynamic>>()
            .toList();
        
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