import 'package:flutter/material.dart';
import 'package:mealmatch/services/themealdb_service.dart';
import 'package:mealmatch/services/cooked_recipes_service.dart';
import 'dart:async';

// --- 1. FIREBASE IMPORTS ADDED ---
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecipeDetailsScreen extends StatefulWidget {
  final String recipeId;
  const RecipeDetailsScreen({super.key, required this.recipeId});

  @override
  State<RecipeDetailsScreen> createState() => _RecipeDetailsScreenState();
}

class _RecipeDetailsScreenState extends State<RecipeDetailsScreen> {
  Map<String, dynamic>? data; // Changed from recipeDetails
  bool loading = true; // Changed from isLoading

  Map<int, bool> ingredientChecklist = {};

  Timer? cookingTimer;
  int timerSeconds = 0;
  int originalCookTimeSeconds = 0;
  bool isTimerRunning = false;

  int originalServings = 1;
  int currentServings = 1;

  double originalCalories = 0;
  double originalProtein = 0;
  double originalCarbs = 0;
  double originalFat = 0;

  final Color primaryGreen = const Color(0xFF4CAF50);

  // --- 2. NEW STATE VARIABLES FOR FAVORITES ---
  bool _isFavorite = false;
  String? _userId;
  // ------------------------------------------

  // Cooked recipes tracking
  bool _hasCooked = false;
  final CookedRecipesService _cookedService = CookedRecipesService();
  bool _isMarkingCooked = false;

  @override
  void initState() {
    super.initState();
    _loadRecipeDetails();
  }

  @override
  void dispose() {
    cookingTimer?.cancel();
    super.dispose();
  }

  // --- 3. NEW HELPER TO CHECK FIREBASE ---
  Future<bool> _checkFavoriteStatus() async {
    _userId = FirebaseAuth.instance.currentUser?.uid;
    if (_userId == null) return false;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .get();
      if (doc.exists) {
        final favorites = List<String>.from(
          doc.data()!['favoriteRecipeIds'] ?? [],
        );
        return favorites.contains(widget.recipeId);
      }
      return false;
    } catch (e) {
      print("Error checking favorite status: $e");
      return false;
    }
  }

  // NEW: Check if user has cooked this recipe
  Future<bool> _checkCookedStatus() async {
    return await _cookedService.hasUserCookedRecipe(widget.recipeId);
  }

  // --- 4. UPDATED TO LOAD FAVORITE STATUS ---
  Future<void> _loadRecipeDetails() async {
    setState(() => loading = true);
    try {
      // Load details and check status at the same time
      final detailsFuture = TheMealDBService.getMealDetails(widget.recipeId);
      final isFavFuture = _checkFavoriteStatus();
      final hasCookedFuture = _checkCookedStatus();

      final details = await detailsFuture;
      final isFav = await isFavFuture; // Get the boolean result
      final hasCooked = await hasCookedFuture;

      if (details != null) {
        // --- Nutrition Parsing ---
        originalServings = details['servings'] ?? 1;
        currentServings = originalServings;
        originalCalories = _parseNutritionValue(
          details['nutrition']?['calories'],
        );
        originalProtein = _parseNutritionValue(
          details['nutrition']?['protein'],
        );
        originalCarbs = _parseNutritionValue(details['nutrition']?['carbs']);
        originalFat = _parseNutritionValue(details['nutrition']?['fat']);

        // --- Ingredient Parsing ---
        final originalIngredients = details['ingredients'] as List;
        final newIngredientsList = <Map<String, dynamic>>[];

        for (int i = 0; i < originalIngredients.length; i++) {
          final newIngredientMap = Map<String, dynamic>.from(
            originalIngredients[i],
          );
          newIngredientMap['parsedAmount'] = _parseIngredientAmount(
            newIngredientMap['original'] ?? '',
          );
          newIngredientsList.add(newIngredientMap);
          ingredientChecklist[i] = false;
        }

        details['ingredients'] = newIngredientsList;

        // --- Initialize Countdown Timer ---
        int cookTimeMinutes = (details['readyInMinutes'] ?? 0).toInt();
        originalCookTimeSeconds = cookTimeMinutes * 60;
        timerSeconds = originalCookTimeSeconds;
      }

      setState(() {
        data = details;
        _isFavorite = isFav; 
        _hasCooked = hasCooked;
        loading = false;
      });
    } catch (e, stackTrace) {
      print('Error loading recipe: $e');
      print('Stack Trace: $stackTrace');
      setState(() => loading = false);
    }
  }

  /// Safely parses a number from a string like "52g" or "400".
  double _parseNutritionValue(dynamic value) {
    if (value == null) return 0.0;
    String stringValue = value.toString();
    final match = RegExp(r'(\d*\.?\d+)').firstMatch(stringValue);
    if (match == null) return 0.0;
    return double.tryParse(match.group(1) ?? '') ?? 0.0;
  }

  void _toggleIngredient(int index) {
    setState(() {
      ingredientChecklist[index] = !ingredientChecklist[index]!;
    });
  }

  void _startStopTimer() {
    if (isTimerRunning) {
      cookingTimer?.cancel();
      setState(() => isTimerRunning = false);
    } else {
      if (timerSeconds == 0) {
        timerSeconds = originalCookTimeSeconds;
      }
      setState(() => isTimerRunning = true);
      cookingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (timerSeconds > 0) {
          setState(() => timerSeconds--);
        } else {
          cookingTimer?.cancel();
          setState(() => isTimerRunning = false);
        }
      });
    }
  }

  void _resetTimer() {
    cookingTimer?.cancel();
    setState(() {
      timerSeconds = originalCookTimeSeconds;
      isTimerRunning = false;
    });
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _formatInstructions(String? instructions) {
    if (instructions == null || instructions.isEmpty)
      return 'No instructions available.';

    String fixedInstructions = instructions
        .replaceAll('tblsp', 'tbsp')
        .replaceAll('Tblsp', 'Tbsp')
        .replaceAll(RegExp(r'<[^>]*>'), '');

    List<String> lines = fixedInstructions
        .split('\r\n')
        .where((s) => s.trim().isNotEmpty)
        .toList();

    List<String> formattedSteps = [];
    int stepCounter = 1;
    for (String line in lines) {
      String cleanLine = line.trim().replaceFirst(
        RegExp(r'^(STEP\s*\d+|^\d+[\.)])\s*:*\s*', caseSensitive: false),
        '',
      );
      if (cleanLine.isNotEmpty) {
        formattedSteps.add('Step $stepCounter: $cleanLine');
        stepCounter++;
      }
    }
    return formattedSteps.join('\n\n');
  }

  // --- 5. NEW FUNCTION TO SAVE TO FIREBASE ---
  void _toggleFavorite() {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to save favorites'),
        ),
      );
      return;
    }

    final docRef = FirebaseFirestore.instance.collection('users').doc(_userId!);

    if (_isFavorite) {
      // Remove from favorites
      docRef.update({
        'favoriteRecipeIds': FieldValue.arrayRemove([widget.recipeId]),
      });
      setState(() {
        _isFavorite = false;
      });
    } else {
      // Add to favorites
      docRef.update({
        'favoriteRecipeIds': FieldValue.arrayUnion([widget.recipeId]),
      });
      setState(() {
        _isFavorite = true;
      });
    }
  }

  // Mark recipe as cooked
  Future<void> _markAsCooked() async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to track cooked recipes'),
        ),
      );
      return;
    }

    if (data == null) return;

    setState(() => _isMarkingCooked = true);

    final success = await _cookedService.markRecipeAsCooked(
      recipeId: widget.recipeId,
      recipeTitle: data!['title'] ?? 'Unknown Recipe',
      recipeImage: data!['image'] ?? '',
      category: data!['category'],
      area: data!['area'],
      nutrition: data!['nutrition'],
    );

    setState(() => _isMarkingCooked = false);

    if (success) {
      setState(() => _hasCooked = true);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Great job! Recipe added to your cooking history 🎉',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: primaryGreen,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark recipe as cooked. Try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  // -------------------------------------------

  num _parseIngredientAmount(String original) {
    if (original.isEmpty) return 1.0;
    original = original.trim();
    if (original.startsWith('1/2')) return 0.5;
    if (original.startsWith('1/4')) return 0.25;
    if (original.startsWith('3/4')) return 0.75;
    if (original.startsWith('1 1/2')) return 1.5;
    final match = RegExp(r'^(\d*\.?\d+)').firstMatch(original);
    if (match == null) {
      return 1.0;
    }
    return num.tryParse(match.group(1)!) ?? 1.0;
  }

  String _formatNumber(num n) {
    if (n == 0.5) return '1/2';
    if (n == 0.25) return '1/4';
    if (n == 0.75) return '3/4';
    if (n == 1.5) return '1 1/2';
    if (n == n.round()) {
      return n.round().toString();
    }
    return n.toStringAsFixed(1);
  }

  double _getMultiplier() {
    if (originalServings == 0) return 1.0;
    return currentServings / originalServings;
  }

  void _adjustServings(int newServings) {
    if (newServings < 1) return;
    setState(() => currentServings = newServings);
  }

  @override
  Widget build(BuildContext context) {
    final multiplier = _getMultiplier();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6D7),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text(
          'Recipe Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : data == null
          ? const Center(
              child: Text('Recipe not found', style: TextStyle(fontSize: 18)),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Image ---
                  if (data!['image'] != null && data!['image'] != '')
                    Image.network(
                      data!['image'],
                      width: double.infinity,
                      height: 250,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 250,
                        color: Colors.grey[300],
                        child: const Icon(Icons.restaurant, size: 80),
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- 6. UPDATED TITLE AND SAVE BUTTON ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                data!['title'] ?? 'Unknown Recipe',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: _toggleFavorite,
                              icon: Icon(
                                _isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: _isFavorite
                                    ? Colors.red
                                    : Colors.grey[700],
                                size: 20,
                              ),
                              label: Text(
                                _isFavorite ? 'Saved' : 'Save',
                                style: TextStyle(
                                  color: _isFavorite
                                      ? Colors.red
                                      : Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _isFavorite
                                    ? Colors.red
                                    : Colors.grey[700],
                                side: BorderSide(
                                  color: _isFavorite
                                      ? Colors.red.withOpacity(0.5)
                                      : Colors.grey[400]!,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // -------------------------------------
                        const SizedBox(height: 8),

                        // Author
                        Text(
                          'By ${data!['author'] ?? 'Unknown Author'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),

                        const SizedBox(height: 16),
                        // NEW: "I Cooked This" Button
                        if (!_hasCooked)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 16),
                            child: ElevatedButton.icon(
                              onPressed: _isMarkingCooked ? null : _markAsCooked,
                              icon: _isMarkingCooked
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Icon(Icons.restaurant_menu, size: 22),
                              label: Text(
                                _isMarkingCooked ? 'Saving...' : 'I Cooked This!',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ),

                        // Show badge if already cooked
                        if (_hasCooked)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: primaryGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: primaryGreen.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: primaryGreen,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'You\'ve cooked this recipe! 🎉',
                                    style: TextStyle(
                                      color: primaryGreen,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Info Cards Row
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoCard(
                                Icons.schedule,
                                '${data!['readyInMinutes']} min',
                                'Cook Time',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: _buildServingsCard()),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Nutrition
                        if (data!['nutrition'] != null &&
                            (data!['nutrition'] as Map).isNotEmpty) ...[
                          const Text(
                            'Nutrition (per serving)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                if (currentServings != originalServings) ...[
                                  _buildBadge(
                                    "Adjusted for $currentServings ${currentServings > 1 ? 'servings' : 'serving'}",
                                    Colors.green,
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildNutritionItem(
                                      'Calories',
                                      _formatNumber(
                                        (originalCalories * multiplier),
                                      ),
                                      'kcal',
                                      Colors.orange,
                                    ),
                                    _buildNutritionItem(
                                      'Protein',
                                      _formatNumber(
                                        (originalProtein * multiplier),
                                      ),
                                      'g',
                                      Colors.red,
                                    ),
                                    _buildNutritionItem(
                                      'Carbs',
                                      _formatNumber(
                                        (originalCarbs * multiplier),
                                      ),
                                      'g',
                                      Colors.blue,
                                    ),
                                    _buildNutritionItem(
                                      'Fat',
                                      _formatNumber((originalFat * multiplier)),
                                      'g',
                                      Colors.purple,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        const SizedBox(height: 24),

                        // Ingredients
                        const Text(
                          'Ingredients',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              if (currentServings != originalServings) ...[
                                _buildBadge(
                                  "Amounts adjusted x${_getMultiplier().toStringAsFixed(1)}",
                                  Colors.blue,
                                ),
                                const SizedBox(height: 8),
                              ],
                              ...List.generate(
                                (data!['ingredients'] as List).length,
                                (index) {
                                  final ing =
                                      (data!['ingredients'] as List)[index];
                                  final isChecked =
                                      ingredientChecklist[index] ?? false;

                                  final originalText =
                                      ing['original'] as String;
                                  final originalAmount =
                                      ing['parsedAmount'] as num;

                                  final match = RegExp(
                                    r'^(\d*\.?\d+|1/2|1/4|3/4|1 1/2)',
                                  ).firstMatch(originalText.trim());
                                  String unit = originalText;
                                  if (match != null) {
                                    unit = originalText
                                        .substring(match.end)
                                        .trim();
                                  } else {
                                    unit = originalText
                                        .replaceFirst(RegExp(r'^\d+'), '')
                                        .trim();
                                  }

                                  final adjustedAmount =
                                      originalAmount * multiplier;
                                  String newAmountStr = _formatNumber(
                                    adjustedAmount,
                                  );
                                  final newSubtitle = '$newAmountStr $unit'
                                      .trim();

                                  return CheckboxListTile(
                                    value: isChecked,
                                    onChanged: (_) => _toggleIngredient(index),
                                    title: Text(
                                      ing['name'] ?? 'Unknown Ingredient',
                                      style: TextStyle(
                                        decoration: isChecked
                                            ? TextDecoration.lineThrough
                                            : null,
                                        color: isChecked
                                            ? Colors.grey
                                            : Colors.black,
                                      ),
                                    ),
                                    subtitle: Text(
                                      newSubtitle,
                                      style: TextStyle(
                                        color: isChecked
                                            ? Colors.grey
                                            : Colors.black54,
                                        fontWeight:
                                            currentServings != originalServings
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    activeColor: primaryGreen,
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                    visualDensity: VisualDensity.compact,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Instructions
                        const Text(
                          'Instructions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            _formatInstructions(data!['instructions']),
                            style: const TextStyle(fontSize: 15, height: 1.6),
                          ),
                        ),

                        // Timer
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.timer, color: Colors.orange),
                                  SizedBox(width: 8),
                                  Text(
                                    'Cooking Timer',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _formatTime(timerSeconds),
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _startStopTimer,
                                    icon: Icon(
                                      isTimerRunning
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                    ),
                                    label: Text(
                                      isTimerRunning ? 'Pause' : 'Start',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryGreen,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    onPressed: _resetTimer,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Reset'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey[600],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: primaryGreen, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildServingsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.restaurant, color: primaryGreen, size: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                color: Colors.grey[600],
                iconSize: 24,
                onPressed: () => _adjustServings(currentServings - 1),
              ),
              Text(
                currentServings.toString(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                color: primaryGreen,
                iconSize: 24,
                onPressed: () => _adjustServings(currentServings + 1),
              ),
            ],
          ),
          Text(
            'Servings',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              height: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color.shade700,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildNutritionItem(
    String label,
    String value,
    String unit,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.circle, color: color, size: 8),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(unit, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }
}
