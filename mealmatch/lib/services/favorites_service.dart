import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Loads the current user's favorite recipe ids from Firestore.
  /// Returns an empty list when the user is not logged in or
  /// when no favorites have been stored yet.
  static Future<List<String>> loadFavoriteIds() async {
    final user = _auth.currentUser;
    if (user == null) {
      print('FavoritesService: No authenticated user.');
      return [];
    }

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        await _firestore.collection('users').doc(user.uid).set(
          {'favoriteRecipeIds': []},
          SetOptions(merge: true),
        );
        return [];
      }

      final data = doc.data();
      if (data == null) return [];

      final favorites = data['favoriteRecipeIds'];
      if (favorites is List) {
        return List<String>.from(favorites);
      }

      return [];
    } catch (e) {
      print('FavoritesService: Error loading favorites -> $e');
      return [];
    }
  }
}

