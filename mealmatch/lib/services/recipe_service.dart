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

  // ✅ IMPROVED: Save user recipe with better error handling
  Future<Map<String, dynamic>> saveUserRecipe(UserRecipe recipe) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'message': 'User not logged in',
        };
      }

      // ✅ FIXED: Consistent Firebase path structure
      final recipesRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('recipes');

      // ✅ ADDED: Calculate total calories before saving
      final recipeData = recipe.toMap();
      
      // ✅ ADDED: Auto-calculate calories from nutrients
      final calories = _calculateCalories(recipe.nutrients);
      recipeData['calories'] = calories;

      // ✅ IMPROVED: Use Firestore timestamp for consistency
      recipeData['createdAt'] = FieldValue.serverTimestamp();

      // Save to Firestore
      final docRef = await recipesRef.add(recipeData);

      print('✅ Recipe saved successfully with ID: ${docRef.id}');

      return {
        'success': true,
        'message': 'Recipe uploaded successfully!',
        'recipeId': docRef.id,
      };
    } on FirebaseException catch (e) {
      // ✅ IMPROVED: Better Firebase error handling
      print('❌ Firebase Error: ${e.code} - ${e.message}');
      return {
        'success': false,
        'message': 'Failed to upload recipe: ${e.message}',
      };
    } catch (e) {
      // ✅ IMPROVED: Catch all other errors
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
}