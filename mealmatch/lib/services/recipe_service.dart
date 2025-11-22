// lib/services/recipe_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_recipe.dart';

class RecipeService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // App ID constant for consistency
  static const String appId = 'mealmatch-app';

  // Save user recipe both private and public
  Future<Map<String, dynamic>> saveUserRecipe(UserRecipe recipe) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'User not logged in'};
      }

      final recipeData = recipe.toMap();
      final calories = _calculateCalories(recipe.nutrients);
      recipeData['calories'] = calories;
      recipeData['createdAt'] = FieldValue.serverTimestamp();
      recipeData['userId'] = user.uid;
      recipeData['userName'] = user.displayName ?? 'Anonymous';
      recipeData['userEmail'] = user.email ?? '';

      // ✅ IMPORTANT: Ensure ingredients are in correct format
      if (recipeData['ingredients'] is List) {
        final ingredients = recipeData['ingredients'] as List;
        recipeData['ingredients'] = ingredients.map((ing) {
          if (ing is String) {
            // Convert string to proper map format
            return {
              'name': ing,
              'original': ing,
              'measure': '',
            };
          } else if (ing is Map) {
            // Ensure map has required fields
            final ingMap = Map<String, dynamic>.from(ing);
            if (!ingMap.containsKey('name')) {
              ingMap['name'] = ingMap['original'] ?? 'Ingredient';
            }
            if (!ingMap.containsKey('original')) {
              ingMap['original'] = ingMap['name'] ?? 'Ingredient';
            }
            if (!ingMap.containsKey('measure')) {
              ingMap['measure'] = '';
            }
            return ingMap;
          }
          return ing;
        }).toList();
      }

      // ✅ Ensure nutrition is in correct format
      if (recipeData['nutrients'] != null) {
        recipeData['nutrition'] = recipeData['nutrients'];
      }

      recipeData['isPublic'] = true;
      recipeData['source'] = 'public';

      // Save to private collection (user's own recipes)
      final privateRecipesRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('recipes');

      final privateDocRef = await privateRecipesRef.add(recipeData);
      print('✅ Recipe saved to private collection: ${privateDocRef.id}');

      // Also save to PUBLIC collection (all users can see)
      final publicRecipesRef = _firestore.collection('public_recipes');
      recipeData['privateRecipeId'] = privateDocRef.id;
      
      final publicDocRef = await publicRecipesRef.add(recipeData);
      print('✅ Recipe saved to public collection: ${publicDocRef.id}');

      return {
        'success': true,
        'message': 'Recipe uploaded and shared publicly!',
        'recipeId': publicDocRef.id,
      };
    } on FirebaseException catch (e) {
      print('❌ Firebase Error: ${e.code} - ${e.message}');
      return {
        'success': false,
        'message': 'Failed to upload recipe: ${e.message}',
      };
    } catch (e) {
      print('❌ Unexpected Error: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  // Helper function to calculate total calories
  int _calculateCalories(Map<String, double> nutrients) {
    final protein = nutrients['Protein'] ?? 0.0;
    final carbs = nutrients['Carbs'] ?? 0.0;
    final fat = nutrients['Fat'] ?? 0.0;

    // Standard calorie calculation:
    // Protein: 4 cal/g, Carbs: 4 cal/g, Fat: 9 cal/g
    return ((protein * 4) + (carbs * 4) + (fat * 9)).round();
  }

  // Fetch user recipes with better error handling
  Future<List<Map<String, dynamic>>> getUserRecipes() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('⚠️ No user logged in');
        return [];
      }

      final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('recipes')
        .orderBy('createdAt', descending: true)
        .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;

        if (!data.containsKey('calories') && data['nutrients'] != null) {
          final nutrients = Map<String, double>.from(data['nutrients']);
          data['calories'] = _calculateCalories(nutrients);
        }

        // ✅ Normalize field names
        _normalizeRecipeData(data);

        return data;
      }).toList();
    } on FirebaseException catch (e) {
      print('❌ Error fetching recipes: ${e.code} - ${e.message}');
      return [];
    } catch (e) {
      print('❌ Unexpected error fetching recipes: $e');
      return [];
    }
  }

  // Get a specific recipe by ID (works for both API and user recipes)
  Future<Map<String, dynamic>?> getRecipeById(String recipeId) async {
    try {
      // Try to get from public_recipes first
      final publicDoc = await _firestore
          .collection('public_recipes')
          .doc(recipeId)
          .get();

      if (publicDoc.exists) {
        final data = publicDoc.data()!;
        data['id'] = recipeId;
        
        if (!data.containsKey('calories') && data['nutrients'] != null) {
          final nutrients = Map<String, double>.from(data['nutrients']);
          data['calories'] = _calculateCalories(nutrients);
        }
        
        // ✅ Normalize field names
        _normalizeRecipeData(data);
        
        return data;
      }

      return null;
    } catch (e) {
      print('❌ Error fetching recipe by ID: $e');
      return null;
    }
  }

  // Delete a recipe
  Future<Map<String, dynamic>> deleteRecipe(String recipeId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'User not logged in'};
      }

      await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('recipes')
        .doc(recipeId)
        .delete();

      print('✅ Recipe deleted: $recipeId');
      return {'success': true, 'message': 'Recipe deleted successfully'};
    } catch (e) {
      print('❌ Error deleting recipe: $e');
      return {'success': false, 'message': 'Failed to delete recipe'};
    }
  }

  // ✅ ADDED: Update a recipe
  Future<Map<String, dynamic>> updateRecipe(
    String recipeId,
    UserRecipe recipe,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'User not logged in'};
      }

      final recipeData = recipe.toMap();
      recipeData['calories'] = _calculateCalories(recipe.nutrients);
      recipeData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('recipes')
        .doc(recipeId)
        .update(recipeData);

      print('✅ Recipe updated: $recipeId');
      return {'success': true, 'message': 'Recipe updated successfully'};
    } catch (e) {
      print('❌ Error updating recipe: $e');
      return {'success': false, 'message': 'Failed to update recipe'};
    }
  }

  // Fetch all public recipes
  Future<List<Map<String, dynamic>>> getPublicRecipes({int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('public_recipes')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        
        if (!data.containsKey('calories') && data['nutrients'] != null) {
          final nutrients = Map<String, double>.from(data['nutrients']);
          data['calories'] = _calculateCalories(nutrients);
        }
        
        // ✅ Normalize field names
        _normalizeRecipeData(data);
        
        return data;
      }).toList();
    } on FirebaseException catch (e) {
      print('❌ Error fetching public recipes: ${e.code}');
      return [];
    } catch (e) {
      print('❌ Unexpected error: $e');
      return [];
    }
  }

  // Search public recipes by name
  Future<List<Map<String, dynamic>>> searchPublicRecipes(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      final snapshot = await _firestore
          .collection('public_recipes')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: query + 'z')
          .limit(20)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        
        _normalizeRecipeData(data);
        
        return data;
      }).toList();
    } catch (e) {
      print('❌ Error searching recipes: $e');
      return [];
    }
  }

  // Get public recipes by ingredient
  Future<List<Map<String, dynamic>>> getPublicRecipesByIngredient(
    List<String> ingredients, {
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('public_recipes')
          .limit(100)
          .get();

      final matching = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final recipeIngredients = 
            (data['ingredients'] as List<dynamic>? ?? [])
                .map((ing) {
                  if (ing is String) return ing.toLowerCase();
                  if (ing is Map) return (ing['name'] ?? ing['original'] ?? '').toString().toLowerCase();
                  return ing.toString().toLowerCase();
                })
                .toList();

        bool hasMatch = ingredients.any((userIng) =>
            recipeIngredients.any((recipeIng) =>
                recipeIng.contains(userIng.toLowerCase()) ||
                userIng.toLowerCase().contains(recipeIng)));

        if (hasMatch) {
          data['id'] = doc.id;
          
          _normalizeRecipeData(data);
          
          matching.add(data);
          if (matching.length >= limit) break;
        }
      }

      return matching;
    } catch (e) {
      print('❌ Error getting recipes by ingredient: $e');
      return [];
    }
  }

  // ✅ NEW: Helper function to normalize recipe data fields
  void _normalizeRecipeData(Map<String, dynamic> data) {
    // ✅ FIX: Safely handle title field
    if (!data.containsKey('title') && data.containsKey('name')) {
      data['title'] = data['name']?.toString() ?? 'Recipe';
    }
    if (data['title'] == null) {
      data['title'] = data['name']?.toString() ?? 'Recipe';
    }
    
    // ✅ FIX: Safely handle author field
    if (!data.containsKey('author')) {
      data['author'] = data['userName']?.toString() ?? 'Public Recipe';
    }
    if (data['author'] is List) {
      // If author is accidentally a List, take first item
      data['author'] = (data['author'] as List).isNotEmpty 
          ? (data['author'] as List)[0].toString() 
          : 'Public Recipe';
    }
    
    // ✅ FIX: Safely handle readyInMinutes
    if (!data.containsKey('readyInMinutes')) {
      final cookTime = data['cookTime'];
      if (cookTime is int) {
        data['readyInMinutes'] = cookTime;
      } else if (cookTime is String) {
        data['readyInMinutes'] = int.tryParse(cookTime) ?? 30;
      } else {
        data['readyInMinutes'] = 30;
      }
    }
    
    // Ensure rating exists
    if (!data.containsKey('rating')) {
      data['rating'] = 4.5;
    }
    
    // Ensure servings exists
    if (!data.containsKey('servings')) {
      data['servings'] = 4;
    }
    
    // Normalize nutrition field
    if (data['nutrients'] != null && data['nutrition'] == null) {
      data['nutrition'] = data['nutrients'];
    }
    
    // ✅ FIX: Ensure ingredients is a List of Maps (handle List<dynamic> safely)
    if (data['ingredients'] != null) {
      try {
        // Convert List<dynamic> to List safely
        final ingredientsRaw = data['ingredients'];
        
        if (ingredientsRaw is List) {
          // ✅ Safe conversion from List<dynamic>
          final ingredientsList = List.from(ingredientsRaw);
          
          data['ingredients'] = ingredientsList.map((ing) {
            if (ing is String) {
              return {
                'name': ing,
                'original': ing,
                'measure': '',
              };
            } else if (ing is Map) {
              final ingMap = Map<String, dynamic>.from(ing);
              
              // Ensure name is a String, not List
              if (ingMap['name'] is List) {
                ingMap['name'] = (ingMap['name'] as List).isNotEmpty
                    ? (ingMap['name'] as List)[0].toString()
                    : 'Ingredient';
              }
              
              if (!ingMap.containsKey('name') || ingMap['name'] == null) {
                ingMap['name'] = ingMap['original']?.toString() ?? 'Ingredient';
              }
              
              if (!ingMap.containsKey('original') || ingMap['original'] == null) {
                ingMap['original'] = ingMap['name']?.toString() ?? 'Ingredient';
              }
              
              if (!ingMap.containsKey('measure')) {
                ingMap['measure'] = '';
              }
              
              return ingMap;
            }
            // Unknown type, convert to string
            return {
              'name': ing.toString(),
              'original': ing.toString(),
              'measure': '',
            };
          }).toList();
        }
      } catch (e) {
        print('⚠️ Error normalizing ingredients: $e');
        // Set empty list as fallback
        data['ingredients'] = [];
      }
    }
    
    // ✅ FIX: Ensure instructions is safe
    if (data['instructions'] != null) {
      if (data['instructions'] is List) {
        // Keep as is
      } else if (data['instructions'] is String) {
        // Keep as string
      } else {
        data['instructions'] = data['instructions'].toString();
      }
    }
  }
}
