import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CookedRecipesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Mark a recipe as cooked by the current user
  Future<bool> markRecipeAsCooked({
    required String recipeId,
    required String recipeTitle,
    required String recipeImage,
    String? category,
    String? area,
    Map<String, dynamic>? nutrition,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        print('❌ No user logged in');
        return false;
      }

      final cookedRecipeData = {
        'recipeId': recipeId,
        'recipeTitle': recipeTitle,
        'recipeImage': recipeImage,
        'category': category ?? '',
        'area': area ?? '',
        'nutrition': nutrition ?? {},
        'cookedAt': FieldValue.serverTimestamp(),
        'cookedDate': DateTime.now().toIso8601String(),
      };

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('cooked_recipes')
          .doc(recipeId) // Use recipeId as document ID
          .set(cookedRecipeData, SetOptions(merge: true));

      print('✅ Recipe marked as cooked: $recipeTitle');
      return true;
    } catch (e) {
      print('❌ Error marking recipe as cooked: $e');
      return false;
    }
  }

  /// Check if user has cooked this recipe
  Future<bool> hasUserCookedRecipe(String recipeId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('cooked_recipes')
          .doc(recipeId)
          .get();

      return doc.exists;
    } catch (e) {
      print('❌ Error checking if recipe is cooked: $e');
      return false;
    }
  }

  /// Get all recipes the user has cooked (sorted by most recent)
  Future<List<Map<String, dynamic>>> getUserCookedRecipes({int limit = 50}) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('cooked_recipes')
          .orderBy('cookedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Add document ID
        return data;
      }).toList();
    } catch (e) {
      print('❌ Error getting cooked recipes: $e');
      return [];
    }
  }

  /// Get recipes cooked within a date range
  Future<List<Map<String, dynamic>>> getCookedRecipesInRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('cooked_recipes')
          .where('cookedDate', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('cookedDate', isLessThanOrEqualTo: endDate.toIso8601String())
          .orderBy('cookedDate', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ Error getting cooked recipes in range: $e');
      return [];
    }
  }

  /// Get most frequently cooked recipes
  Future<List<Map<String, dynamic>>> getMostCookedRecipes({int limit = 5}) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('cooked_recipes')
          .orderBy('cookedAt', descending: true)
          .limit(100) // Get last 100 cooked recipes
          .get();

      // Count frequency of each recipe
      final Map<String, Map<String, dynamic>> recipeFrequency = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final recipeId = data['recipeId'] as String;
        
        if (recipeFrequency.containsKey(recipeId)) {
          recipeFrequency[recipeId]!['count'] = 
              (recipeFrequency[recipeId]!['count'] as int) + 1;
        } else {
          recipeFrequency[recipeId] = {
            'recipeId': recipeId,
            'recipeTitle': data['recipeTitle'],
            'recipeImage': data['recipeImage'],
            'category': data['category'],
            'area': data['area'],
            'nutrition': data['nutrition'],
            'count': 1,
          };
        }
      }

      // Sort by frequency and return top recipes
      final sortedRecipes = recipeFrequency.values.toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      return sortedRecipes.take(limit).toList();
    } catch (e) {
      print('❌ Error getting most cooked recipes: $e');
      return [];
    }
  }

  /// Remove a recipe from cooked history
  Future<bool> removeRecipeFromCooked(String recipeId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('cooked_recipes')
          .doc(recipeId)
          .delete();

      print('✅ Recipe removed from cooked history');
      return true;
    } catch (e) {
      print('❌ Error removing recipe from cooked: $e');
      return false;
    }
  }
}