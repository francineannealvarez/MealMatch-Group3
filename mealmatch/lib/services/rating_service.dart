// lib/services/rating_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RatingService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ⭐ Save or update a user's rating for a recipe
  Future<Map<String, dynamic>> submitRating({
    required String recipeId,
    required double ratingValue, // 1-5 stars
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return {'success': false, 'message': 'User not logged in'};
      }

      // Validate rating
      if (ratingValue < 1 || ratingValue > 5) {
        return {'success': false, 'message': 'Rating must be between 1-5'};
      }

      // 📍 STEP 1: Get the public recipe to find the author
      final publicRecipeDoc = await _firestore
          .collection('public_recipes')
          .doc(recipeId)
          .get();

      if (!publicRecipeDoc.exists) {
        return {'success': false, 'message': 'Recipe not found'};
      }

      final publicData = publicRecipeDoc.data()!;
      final authorId = publicData['authorId'] as String?;
      final privateRecipeId = publicData['privateRecipeId'] as String?;

      print('🔍 Recipe Info: authorId=$authorId, privateRecipeId=$privateRecipeId');

      // Rating data
      final ratingData = {
        'userId': userId,
        'ratingValue': ratingValue,
        'ratedAt': FieldValue.serverTimestamp(),
      };

      // 📍 STEP 2: Save to PUBLIC recipe ratings
      await _firestore
          .collection('public_recipes')
          .doc(recipeId)
          .collection('ratings')
          .doc(userId)
          .set(ratingData);

      print('✅ Rating saved to public_recipes: $recipeId - $ratingValue stars');

      // 📍 STEP 3: ALSO save to PRIVATE recipe ratings (if exists)
      if (authorId != null && privateRecipeId != null) {
        try {
          await _firestore
              .collection('users')
              .doc(authorId)
              .collection('recipes')
              .doc(privateRecipeId)
              .collection('ratings')
              .doc(userId)
              .set(ratingData);

          print('✅ Rating ALSO saved to private recipe: users/$authorId/recipes/$privateRecipeId/ratings/$userId');
        } catch (e) {
          print('⚠️ Could not save to private recipe (may not exist): $e');
        }
      }

      // 📍 STEP 4: Update aggregates for BOTH collections
      await _updateRecipeRatingAggregate(recipeId);
      
      if (authorId != null && privateRecipeId != null) {
        await _updatePrivateRecipeRatingAggregate(authorId, privateRecipeId);
      }

      return {
        'success': true,
        'message': 'Rating submitted successfully!',
        'rating': ratingValue,
      };
    } on FirebaseException catch (e) {
      print('❌ Firebase Error saving rating: ${e.code} - ${e.message}');
      return {
        'success': false,
        'message': 'Failed to submit rating: ${e.message}',
      };
    } catch (e) {
      print('❌ Error saving rating: $e');
      return {
        'success': false,
        'message': 'An error occurred while saving rating',
      };
    }
  }

  // 📊 Update PUBLIC recipe aggregate
  Future<void> _updateRecipeRatingAggregate(String recipeId) async {
    try {
      final ratingsSnapshot = await _firestore
          .collection('public_recipes')
          .doc(recipeId)
          .collection('ratings')
          .get();

      if (ratingsSnapshot.docs.isEmpty) {
        await _firestore.collection('public_recipes').doc(recipeId).update({
          'averageRating': 0.0,
          'totalRatings': 0,
        });
        return;
      }

      double totalRating = 0;
      for (var doc in ratingsSnapshot.docs) {
        totalRating += doc['ratingValue'] as double;
      }

      final averageRating = totalRating / ratingsSnapshot.docs.length;
      final totalRatings = ratingsSnapshot.docs.length;

      await _firestore.collection('public_recipes').doc(recipeId).update({
        'averageRating': averageRating,
        'totalRatings': totalRatings,
        'lastRatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Public recipe aggregate updated: $averageRating avg, $totalRatings total');
    } catch (e) {
      print('❌ Error updating public aggregate: $e');
    }
  }

  // 📊 NEW: Update PRIVATE recipe aggregate
  Future<void> _updatePrivateRecipeRatingAggregate(String authorId, String privateRecipeId) async {
    try {
      final ratingsSnapshot = await _firestore
          .collection('users')
          .doc(authorId)
          .collection('recipes')
          .doc(privateRecipeId)
          .collection('ratings')
          .get();

      if (ratingsSnapshot.docs.isEmpty) {
        await _firestore
            .collection('users')
            .doc(authorId)
            .collection('recipes')
            .doc(privateRecipeId)
            .update({
          'averageRating': 0.0,
          'totalRatings': 0,
        });
        return;
      }

      double totalRating = 0;
      for (var doc in ratingsSnapshot.docs) {
        totalRating += doc['ratingValue'] as double;
      }

      final averageRating = totalRating / ratingsSnapshot.docs.length;
      final totalRatings = ratingsSnapshot.docs.length;

      await _firestore
          .collection('users')
          .doc(authorId)
          .collection('recipes')
          .doc(privateRecipeId)
          .update({
        'averageRating': averageRating,
        'totalRatings': totalRatings,
        'lastRatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Private recipe aggregate updated: $averageRating avg, $totalRatings total');
    } catch (e) {
      print('❌ Error updating private aggregate: $e');
    }
  }

  // 🔍 Get current user's rating for a recipe (if exists)
  Future<double?> getUserRatingForRecipe(String recipeId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      final doc = await _firestore
          .collection('public_recipes')
          .doc(recipeId)
          .collection('ratings')
          .doc(userId)
          .get();

      if (doc.exists) {
        return doc['ratingValue'] as double?;
      }
      return null;
    } catch (e) {
      print('❌ Error getting user rating: $e');
      return null;
    }
  }

  // 📈 Get recipe rating stats (tries public first, then private)
  Future<Map<String, dynamic>> getRecipeRatingStats(String recipeId) async {
    try {
      // Try public first
      final publicDoc = await _firestore
          .collection('public_recipes')
          .doc(recipeId)
          .get();

      if (publicDoc.exists) {
        final data = publicDoc.data() ?? {};
        return {
          'averageRating': (data['averageRating'] ?? 0.0) as double,
          'totalRatings': (data['totalRatings'] ?? 0) as int,
        };
      }

      // Fallback: Try private recipe
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final privateDoc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('recipes')
            .doc(recipeId)
            .get();

        if (privateDoc.exists) {
          final data = privateDoc.data() ?? {};
          return {
            'averageRating': (data['averageRating'] ?? 0.0) as double,
            'totalRatings': (data['totalRatings'] ?? 0) as int,
          };
        }
      }

      return {
        'averageRating': 0.0,
        'totalRatings': 0,
      };
    } catch (e) {
      print('❌ Error getting rating stats: $e');
      return {
        'averageRating': 0.0,
        'totalRatings': 0,
      };
    }
  }

  // ❌ Delete a user's rating for a recipe
  Future<bool> deleteRating(String recipeId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      // Get public recipe info
      final publicRecipeDoc = await _firestore
          .collection('public_recipes')
          .doc(recipeId)
          .get();

      // Delete from public
      await _firestore
          .collection('public_recipes')
          .doc(recipeId)
          .collection('ratings')
          .doc(userId)
          .delete();

      // Delete from private (if exists)
      if (publicRecipeDoc.exists) {
        final data = publicRecipeDoc.data();
        final authorId = data?['authorId'] as String?;
        final privateRecipeId = data?['privateRecipeId'] as String?;

        if (authorId != null && privateRecipeId != null) {
          await _firestore
              .collection('users')
              .doc(authorId)
              .collection('recipes')
              .doc(privateRecipeId)
              .collection('ratings')
              .doc(userId)
              .delete();
        }
      }

      // Update aggregates
      await _updateRecipeRatingAggregate(recipeId);

      print('✅ Rating deleted for $recipeId by $userId');
      return true;
    } catch (e) {
      print('❌ Error deleting rating: $e');
      return false;
    }
  }

  // 🎯 Get all ratings for a recipe (for analytics - optional)
  Future<List<Map<String, dynamic>>> getAllRecipeRatings(String recipeId) async {
    try {
      final ratingsSnapshot = await _firestore
          .collection('public_recipes')
          .doc(recipeId)
          .collection('ratings')
          .orderBy('ratedAt', descending: true)
          .get();

      return ratingsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'userId': data['userId'],
          'ratingValue': data['ratingValue'],
          'ratedAt': (data['ratedAt'] as Timestamp?)?.toDate(),
        };
      }).toList();
    } catch (e) {
      print('❌ Error getting all ratings: $e');
      return [];
    }
  }

  // 🔄 Get user's all ratings (for their rating history - optional)
  Future<List<Map<String, dynamic>>> getUserRatings() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      final ratingsSnapshot = await _firestore
          .collectionGroup('ratings')
          .where('userId', isEqualTo: userId)
          .orderBy('ratedAt', descending: true)
          .get();

      return ratingsSnapshot.docs.map((doc) {
        return {
          'recipeId': doc.reference.parent.parent?.id,
          'ratingValue': doc['ratingValue'],
          'ratedAt': (doc['ratedAt'] as Timestamp?)?.toDate(),
        };
      }).toList();
    } catch (e) {
      print('❌ Error getting user ratings: $e');
      return [];
    }
  }
}