import 'package:flutter/material.dart';
import 'package:mealmatch/services/themealdb_service.dart';
import 'package:mealmatch/services/cooked_recipes_service.dart';
import 'dart:async';
import '../services/recipe_service.dart';

// --- 1. FIREBASE IMPORTS ADDED ---
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecipeDetailsScreen extends StatefulWidget {
  final String recipeId;
  final bool isOwnRecipe;

  const RecipeDetailsScreen({
    super.key,
    required this.recipeId,
    this.isOwnRecipe = false, // Default to false
  });

  @override
  State<RecipeDetailsScreen> createState() => _RecipeDetailsScreenState();
}

class _RecipeDetailsScreenState extends State<RecipeDetailsScreen> {
  Map<String, dynamic>? data; // Changed from recipeDetails
  bool loading = true; // Changed from isLoading

  final RecipeService _recipeService = RecipeService();

  Map<int, bool> ingredientChecklist = {};

  Timer? cookingTimer;
  int timerSeconds = 0;
  int originalCookTimeSeconds = 0;
  bool isTimerRunning = false;

  Map<int, Timer?> stepTimers = {}; // Stores active timers for each step
  Map<int, int> stepTimerSeconds = {}; // Current seconds for each step
  Map<int, int> originalStepTimerSeconds = {}; // Original time for reset
  Map<int, bool> stepTimerRunning = {}; // Is timer running for this step

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
    
    // ✅ NEW: Cancel all step timers
    stepTimers.forEach((key, timer) {
      timer?.cancel();
    });
    
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
      _userId = FirebaseAuth.instance.currentUser?.uid;
      
      print('🔍 Loading recipe details for ID: ${widget.recipeId}');

      Map<String, dynamic>? details;

      // ✅ TRY USER RECIPES FIRST (Firestore)
      try {
        details = await _recipeService.getRecipeById(widget.recipeId);
        if (details != null) {
          print('✅ Found in public recipes (Firestore)');
        }
      } catch (e) {
        print('⚠️ Not found in public recipes: $e');
      }

      // If not found, try TheMealDB (API)
      if (details == null) {
        try {
          details = await TheMealDBService.getMealDetails(widget.recipeId);
          if (details != null) {
            print('✅ Found in TheMealDB (API)');
          }
        } catch (e) {
          print('⚠️ Not found in API: $e');
        }
      }

      if (details != null) {
        print('📍 Processing recipe data...');
        
        // --- Extract Servings ---
        originalServings = _extractInt(details['servings'], 1);
        currentServings = originalServings;

        // --- Extract Nutrition ---
        Map<String, dynamic> nutrition = {};
        if (details['nutrition'] != null && details['nutrition'] is Map) {
          nutrition = Map<String, dynamic>.from(details['nutrition']);
        }

        originalCalories = _parseNutritionValue(nutrition['calories'] ?? details['calories']);
        originalProtein = _parseNutritionValue(nutrition['Protein'] ?? nutrition['protein']);
        originalCarbs = _parseNutritionValue(nutrition['Carbs'] ?? nutrition['carbs']);
        originalFat = _parseNutritionValue(nutrition['Fat'] ?? nutrition['fat']);

        print('📊 Nutrition: Cal=$originalCalories, Pro=$originalProtein, Carb=$originalCarbs, Fat=$originalFat');

        // --- ✅ FIXED: Handle ingredients properly with SAFE type conversion ---
        List<Map<String, dynamic>> processedIngredients = [];
        
        try {
          if (details['ingredients'] != null) {
            final rawIngredients = details['ingredients'];
            print('🔍 Raw ingredients type: ${rawIngredients.runtimeType}');
            print('🔍 Raw ingredients: $rawIngredients');
            
            // ✅ SAFE CONVERSION: Convert to List safely
            List<dynamic> ingredientsList = [];
            
            if (rawIngredients is List) {
              // Already a list, convert List<dynamic> safely
              ingredientsList = List<dynamic>.from(rawIngredients);
              print('✅ Ingredients is List with ${ingredientsList.length} items');
            } else if (rawIngredients is String) {
              // Single string ingredient
              ingredientsList = [rawIngredients];
              print('⚠️ Ingredients is String, wrapped in list');
            } else if (rawIngredients is Map) {
              // Single map ingredient
              ingredientsList = [rawIngredients];
              print('⚠️ Ingredients is Map, wrapped in list');
            } else {
              // Unknown type, try to convert to string
              ingredientsList = [rawIngredients.toString()];
              print('⚠️ Unknown ingredients type: ${rawIngredients.runtimeType}');
            }
            
            // Now process each ingredient safely
            for (int i = 0; i < ingredientsList.length; i++) {
              try {
                final ing = ingredientsList[i];
                final ingredientMap = <String, dynamic>{};

                print('🔍 Processing ingredient $i: type=${ing.runtimeType}, value=$ing');

                if (ing is Map) {
                  // Already a map, copy it
                  ingredientMap.addAll(Map<String, dynamic>.from(ing));
                  print('✅ Ingredient $i is Map');
                } else if (ing is String) {
                  // Just a string, create basic structure
                  ingredientMap['name'] = ing;
                  ingredientMap['original'] = ing;
                  ingredientMap['measure'] = '';
                  print('✅ Ingredient $i is String: $ing');
                } else {
                  // Unknown type, convert to string
                  final stringValue = ing.toString();
                  ingredientMap['name'] = stringValue;
                  ingredientMap['original'] = stringValue;
                  ingredientMap['measure'] = '';
                  print('⚠️ Ingredient $i converted to String: $stringValue');
                }

                // Ensure required fields exist
                if (!ingredientMap.containsKey('name') || ingredientMap['name'] == null) {
                  ingredientMap['name'] = ingredientMap['original'] ?? 'Ingredient';
                }
                if (!ingredientMap.containsKey('original') || ingredientMap['original'] == null) {
                  ingredientMap['original'] = ingredientMap['name'] ?? 'Ingredient';
                }
                if (!ingredientMap.containsKey('measure')) {
                  ingredientMap['measure'] = '';
                }

                ingredientMap['parsedAmount'] = _parseIngredientAmount(
                  ingredientMap['original']?.toString() ?? '',
                );

                processedIngredients.add(ingredientMap);
                ingredientChecklist[i] = false;
                print('✅ Ingredient $i processed successfully');
              } catch (e, stackTrace) {
                print('⚠️ Error processing ingredient $i: $e');
                print('⚠️ Stack trace: $stackTrace');
                continue;
              }
            }
          } else {
            print('⚠️ No ingredients found in recipe data');
          }
        } catch (e, stackTrace) {
          print('❌ ERROR processing ingredients list: $e');
          print('❌ Stack trace: $stackTrace');
        }

        details['ingredients'] = processedIngredients;
        print('✅ Processed ${processedIngredients.length} ingredients');

        // --- Extract Prep Time (if available) ---
        String prepTimeMinutes = _extractString(details['prepTime'], '0');
        print('⏱️ Prep time: $prepTimeMinutes min');

        // --- Extract Cook Time ---
        String cookTimeMinutes = _extractString(details['cookTime'], '30');
        originalCookTimeSeconds = _minutesToSeconds(cookTimeMinutes);
        timerSeconds = originalCookTimeSeconds;
        print('⏱️ Cook time: $cookTimeMinutes min');

        // Load favorite and cooked status
        final isFav = await _checkFavoriteStatus();
        final hasCooked = await _checkCookedStatus();

        setState(() {
          data = details;
          _isFavorite = isFav;
          _hasCooked = hasCooked;
          loading = false;
        });

        print('✅ Recipe loaded successfully');
      } else {
        print('❌ Recipe not found in any source');
        setState(() => loading = false);
      }
    } catch (e, stackTrace) {
      print('❌ Error loading recipe: $e');
      print('Stack Trace: $stackTrace');
      setState(() => loading = false);
    }
  }
  
  int _extractInt(dynamic value, int defaultValue) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    if (value is double) return value.toInt();
    return defaultValue;
  }

  // ✅ NEW: Helper to safely extract string
  String _extractString(dynamic value, String defaultValue) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    if (value is int) return value.toString();
    return defaultValue;
  }

  /// Safely parses a number from a string like "52g" or "400".
  double _parseNutritionValue(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    
    String stringValue = value.toString().toLowerCase().trim();
    
    // Remove common units
    stringValue = stringValue.replaceAll(RegExp(r'[a-z%]'), '').trim();
    
    if (stringValue.isEmpty) return 0.0;
    
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

  // ignore: unused_element
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

  // ✅ NEW: Safely extract string value (handles List<dynamic>)
  String _getStringValue(dynamic value, String defaultValue) {
    if (value == null) return defaultValue;
    
    if (value is String) {
      return value;
    } else if (value is List) {
      if (value.isEmpty) return defaultValue;
      return value[0].toString();
    }
    
    return value.toString();
  }

  // ✅ ADD: Delete recipe function
  Future<void> _deleteRecipe() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recipe'),
        content: const Text('Are you sure you want to delete this recipe? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    // Show loading
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deleting recipe...')),
      );
    }
    
    // Delete recipe
    final result = await _recipeService.deleteRecipe(widget.recipeId);
    
    if (mounted) {
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Recipe deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Go back to profile
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to delete recipe'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ NEW: Helper to convert minutes string to seconds
  int _minutesToSeconds(String? minutesStr) {
    if (minutesStr == null || minutesStr.isEmpty || minutesStr == '0') return 0;
    final minutes = int.tryParse(minutesStr) ?? 0;
    return minutes * 60;
  }

  // ✅ NEW: Helper to format MM:SS to readable format
  String _formatCookTime(String? minutesStr) {
    if (minutesStr == null || minutesStr.isEmpty) return '0 min';
    final minutes = int.tryParse(minutesStr) ?? 0;
    if (minutes == 0) return '0 min';
    if (minutes < 60) return '$minutes min${minutes > 1 ? 's' : ''}';
    
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '$hours h${hours > 1 ? '' : ''}';
    return '$hours h ${mins}m';
  }

  // ✅ NEW: Convert timer string "MM:SS" to seconds
  int _timeStringToSeconds(String timerStr) {
    try {
      final parts = timerStr.split(':');
      if (parts.length != 2) return 0;
      
      final minutes = int.tryParse(parts[0]) ?? 0;
      final seconds = int.tryParse(parts[1]) ?? 0;
      
      return (minutes * 60) + seconds;
    } catch (e) {
      return 0;
    }
  }

  // ✅ NEW: Format step timer seconds to MM:SS
  String _formatStepTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  // ✅ NEW: Toggle step timer (start/pause)
  void _toggleStepTimer(int stepIndex) {
    if (stepTimerRunning[stepIndex] == true) {
      // Pause timer
      stepTimers[stepIndex]?.cancel();
      setState(() {
        stepTimerRunning[stepIndex] = false;
      });
    } else {
      // Start timer
      if ((stepTimerSeconds[stepIndex] ?? 0) == 0) {
        stepTimerSeconds[stepIndex] = originalStepTimerSeconds[stepIndex] ?? 0;
      }
      
      setState(() {
        stepTimerRunning[stepIndex] = true;
      });
      
      stepTimers[stepIndex] = Timer.periodic(const Duration(seconds: 1), (timer) {
        if ((stepTimerSeconds[stepIndex] ?? 0) > 0) {
          setState(() {
            stepTimerSeconds[stepIndex] = (stepTimerSeconds[stepIndex] ?? 1) - 1;
          });
        } else {
          // Timer finished
          timer.cancel();
          setState(() {
            stepTimerRunning[stepIndex] = false;
          });
          
          // Optional: Show notification
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('⏰ Step ${stepIndex + 1} timer finished!'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      });
    }
  }

  // ✅ NEW: Reset step timer
  void _resetStepTimer(int stepIndex) {
    stepTimers[stepIndex]?.cancel();
    setState(() {
      stepTimerSeconds[stepIndex] = originalStepTimerSeconds[stepIndex] ?? 0;
      stepTimerRunning[stepIndex] = false;
    });
  }

  List<Widget> _buildInstructionSteps(dynamic instructions) {
    if (instructions == null) {
      return [
        Text(
          'No instructions available.',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ];
    }

    List<dynamic> instructionsList = [];
    
    if (instructions is String) {
      instructionsList = [instructions];
    } else if (instructions is List) {
      instructionsList = instructions;
    } else {
      instructionsList = [instructions.toString()];
    }

    List<Widget> widgets = [];

    for (int i = 0; i < instructionsList.length; i++) {
      try {
        final step = instructionsList[i];
        String text = '';
        String? timerStr;

        if (step is Map) {
          text = step['text']?.toString() ?? '';
          timerStr = step['timer']?.toString();
        } else if (step is String) {
          text = step;
        } else {
          text = step.toString();
        }

        if (text.isEmpty) continue;

        // ✅ INITIALIZE STEP TIMER if it has a timer
        if (timerStr != null && timerStr.isNotEmpty && timerStr != '00:00') {
          if (!stepTimerSeconds.containsKey(i)) {
            final seconds = _timeStringToSeconds(timerStr);
            stepTimerSeconds[i] = seconds;
            originalStepTimerSeconds[i] = seconds;
            stepTimerRunning[i] = false;
          }
        }

        String formattedText = text
            .replaceAll('tblsp', 'tbsp')
            .replaceAll('Tblsp', 'Tbsp')
            .replaceAll(RegExp(r'<[^>]*>'), '');

        List<String> lines = formattedText
            .split('\r\n')
            .where((s) => s.trim().isNotEmpty)
            .toList();

        for (int lineIdx = 0; lineIdx < lines.length; lineIdx++) {
          String line = lines[lineIdx].trim();
          String cleanLine = line.replaceFirst(
            RegExp(r'^(STEP\s*\d+|^\d+[\.)])\s*:*\s*', caseSensitive: false),
            '',
          );
          if (cleanLine.isEmpty) continue;

          widgets.add(
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: primaryGreen,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // ✅ SHOW TIMER IF AVAILABLE
                      if (timerStr != null && timerStr.isNotEmpty && timerStr != '00:00')
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              children: [
                                // Timer Display
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.timer_outlined,
                                      size: 16,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _formatStepTime(stepTimerSeconds[i] ?? 0),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                
                                // Timer Controls
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Start/Pause Button
                                    InkWell(
                                      onTap: () => _toggleStepTimer(i),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: stepTimerRunning[i] == true
                                              ? Colors.red.shade400
                                              : Colors.green.shade400,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              stepTimerRunning[i] == true
                                                  ? Icons.pause
                                                  : Icons.play_arrow,
                                              size: 14,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              stepTimerRunning[i] == true
                                                  ? 'Pause'
                                                  : 'Start',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    
                                    // Reset Button
                                    InkWell(
                                      onTap: () => _resetStepTimer(i),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade400,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.refresh,
                                              size: 14,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Reset',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cleanLine,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      } catch (e) {
        print('⚠️ Error processing instruction: $e');
        continue;
      }
    }

    return widgets.isEmpty
        ? [
            Text(
              'No instructions available.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ]
        : widgets;
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
        // ✅ ADD: Edit/Delete buttons for own recipes
        actions: widget.isOwnRecipe
            ? [
                IconButton(
                  onPressed: () {
                    // TODO: Navigate to edit screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Edit feature coming soon!')),
                    );
                  },
                  icon: const Icon(Icons.edit, color: Colors.white),
                  tooltip: 'Edit Recipe',
                ),
                IconButton(
                  onPressed: _deleteRecipe,
                  icon: const Icon(Icons.delete, color: Colors.white),
                  tooltip: 'Delete Recipe',
                ),
              ]
            : null,
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
                          'By ${_getStringValue(data!['author'], 'Unknown Author')}',
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
                                _formatCookTime(data!['prepTime']),
                                'Prep Time',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInfoCard(
                                Icons.schedule,
                                _formatCookTime( data!['cookTime']),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Cooking Instructions',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ..._buildInstructionSteps(data!['instructions']),
                            ],
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
