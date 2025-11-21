// lib/services/recipe_service.dart
// ✅ NEW: Dedicated service for recipe operations

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_recipe.dart';

class RecipeService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ ADDED: App ID constant for consistency
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
      recipeData['userId'] = user.uid; // ✅ IMPORTANT: Track owner
      recipeData['userName'] = user.displayName ?? 'Anonymous'; // Add user name
      recipeData['userEmail'] = user.email ?? ''; // Add email for contact

      // ✅ NEW: Save to private collection (user's own recipes)
      final privateRecipesRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('recipes');

      final privateDocRef = await privateRecipesRef.add(recipeData);
      print('✅ Recipe saved to private collection: ${privateDocRef.id}');

      // ✅ NEW: Also save to PUBLIC collection (all users can see)
      final publicRecipesRef = _firestore.collection('public_recipes');
      recipeData['privateRecipeId'] = privateDocRef.id; // Link to private copy
      
      final publicDocRef = await publicRecipesRef.add(recipeData);
      print('✅ Recipe saved to public collection: ${publicDocRef.id}');

      return {
        'success': true,
        'message': 'Recipe uploaded and shared with community!',
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

  // ✅ ADDED: Helper function to calculate total calories
  int _calculateCalories(Map<String, double> nutrients) {
    final protein = nutrients['Protein'] ?? 0.0;
    final carbs = nutrients['Carbs'] ?? 0.0;
    final fat = nutrients['Fat'] ?? 0.0;

    // Standard calorie calculation:
    // Protein: 4 cal/g, Carbs: 4 cal/g, Fat: 9 cal/g
    return ((protein * 4) + (carbs * 4) + (fat * 9)).round();
  }

  // ✅ IMPROVED: Fetch user recipes with better error handling
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

      // ✅ IMPROVED: Convert documents to list with proper data handling
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Add document ID

        // ✅ ADDED: Ensure calories field exists
        if (!data.containsKey('calories') && data['nutrients'] != null) {
          final nutrients = Map<String, double>.from(data['nutrients']);
          data['calories'] = _calculateCalories(nutrients);
        }

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

  // ✅ ADDED: Delete a recipe
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
        
        // Ensure calories exist
        if (!data.containsKey('calories') && data['nutrients'] != null) {
          final nutrients = Map<String, double>.from(data['nutrients']);
          data['calories'] = _calculateCalories(nutrients);
        }
        
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

  // ✅ NEW: Search public recipes by name
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
        return data;
      }).toList();
    } catch (e) {
      print('❌ Error searching recipes: $e');
      return [];
    }
  }

  // ✅ NEW: Get public recipes by ingredient (for "What Can I Cook")
  Future<List<Map<String, dynamic>>> getPublicRecipesByIngredient(
    List<String> ingredients, {
    int limit = 10,
  }) async {
    try {
      // Get all public recipes and filter locally
      // (Firestore doesn't support array-contains multiple values)
      final snapshot = await _firestore
          .collection('public_recipes')
          .limit(100)
          .get();

      final matching = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final recipeIngredients = 
            (data['ingredients'] as List<dynamic>? ?? [])
                .map((ing) => ing.toString().toLowerCase())
                .toList();

        // Check if any user ingredient matches recipe ingredient
        bool hasMatch = ingredients.any((userIng) =>
            recipeIngredients.any((recipeIng) =>
                recipeIng.contains(userIng.toLowerCase()) ||
                userIng.toLowerCase().contains(recipeIng)));

        if (hasMatch) {
          data['id'] = doc.id;
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

}