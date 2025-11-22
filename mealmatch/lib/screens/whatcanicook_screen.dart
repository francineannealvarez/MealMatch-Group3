// lib/screens/whatcanicook_screen.dart
import 'package:flutter/material.dart';
import 'package:mealmatch/services/themealdb_service.dart';
import 'package:mealmatch/screens/recipe_details_screen.dart';
import 'package:mealmatch/services/recipe_service.dart';
//import 'dart:math'; // <-- 1. IMPORT ADDED

class WhatCanICookScreen extends StatefulWidget {
  const WhatCanICookScreen({super.key});

  @override
  State<WhatCanICookScreen> createState() => _WhatCanICookScreenState();
}

class _WhatCanICookScreenState extends State<WhatCanICookScreen> {
  final List<String> selectedIngredients = [];
  final TextEditingController _searchController = TextEditingController();
  final RecipeService _recipeService = RecipeService();
  
  final Map<String, List<String>> categoryIngredients = {
    'Vegetables': [
      'onion', 'garlic', 'tomato', 'potato', 'carrot', 'cabbage',
      'bell pepper', 'broccoli', 'spinach', 'lettuce'
    ],
    'Fruits': [
      'apple', 'banana', 'orange', 'lemon', 'lime', 'mango',
      'strawberry', 'blueberry', 'pineapple', 'watermelon'
    ],
    'Protein/Meat': [
      'chicken', 'beef', 'pork', 'fish', 'salmon', 'shrimp', 
      'tuna', 'bacon', 'sausage', 'lamb'
    ],
    'Grains & Carbs': [
      'rice', 'pasta', 'noodles', 'bread', 'flour', 'oats',
      'quinoa', 'couscous', 'tortilla', 'cornmeal'
    ],
    'Sauces & Condiments': [
      'soy sauce', 'vinegar', 'ketchup', 'mayonnaise', 'mustard',
      'hot sauce', 'worcestershire sauce', 'fish sauce', 'olive oil', 'sesame oil'
    ],
    'Dairy & Eggs': [
      'egg', 'milk', 'cheese', 'butter', 'cream', 
      'yogurt', 'sour cream', 'parmesan', 'mozzarella', 'cheddar'
    ],
    'Spices & Herbs': [
      'salt', 'pepper', 'garlic powder', 'paprika', 'cumin',
      'oregano', 'basil', 'thyme', 'rosemary', 'ginger'
    ],
  };

  final Map<String, bool> expandedCategories = {
    'Vegetables': false,
    'Fruits': false,
    'Protein/Meat': false,
    'Grains & Carbs': false,
    'Sauces & Condiments': false,
    'Dairy & Eggs': false,
    'Spices & Herbs': false,
  };

  bool isLoading = false;
  bool showResults = false;
  List<Map<String, dynamic>> completeRecipes = [];
  List<Map<String, dynamic>> partialRecipes = [];

  final Color primaryGreen = const Color(0xFF4CAF50);
  final Color pageBg = const Color(0xFFFFF6D7);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addIngredient(String ingredient) {
    setState(() {
      final lowerIngredient = ingredient.toLowerCase().trim();
      if (!selectedIngredients.contains(lowerIngredient) && lowerIngredient.isNotEmpty) {
        selectedIngredients.add(lowerIngredient);
      }
    });
  }

  void _removeIngredient(String ingredient) {
    setState(() {
      selectedIngredients.remove(ingredient);
    });
  }

  void _addCustomIngredient() {
    final text = _searchController.text.trim();
    if (text.isNotEmpty) {
      _addIngredient(text);
      _searchController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added "$text" to your ingredients'),
          backgroundColor: primaryGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  int _getSelectedCountInCategory(String category) {
    final categoryItems = categoryIngredients[category] ?? [];
    return categoryItems.where((item) => selectedIngredients.contains(item)).length;
  }

  Future<void> _findRecipes() async {
    if (selectedIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please add at least one ingredient'),
          backgroundColor: primaryGreen,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
      showResults = false;
      completeRecipes = [];
      partialRecipes = [];
    });

    try {
      // Get recipes from TheMealDB
      final found = await TheMealDBService.findByIngredients(
        selectedIngredients,
        number: 10,
      );

      // ✅ Get user recipes with matching ingredients
      final userRecipesMatching = 
          await _recipeService.getPublicRecipesByIngredient(
            selectedIngredients,
            limit: 5,
          );
      
      // ✅ Combine both lists
      final allRecipes = [...found, ...userRecipesMatching];
      
      if (allRecipes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No recipes found. Try different ingredients.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      final complete = <Map<String, dynamic>>[];
      final partial = <Map<String, dynamic>>[];

      for (var recipe in found) {
        // Get details. The service file *already added* the fake data.
        final details = await TheMealDBService.getMealDetails(recipe['id'].toString());
        
        if (details != null) {
          final recipeIngredients = (details['ingredients'] as List)
              .map((ing) => ing['name'].toString().toLowerCase())
              .toList();

          final missingIngredients = <String>[];
          for (var recipeIng in recipeIngredients) {
            bool found = selectedIngredients.any((userIng) =>
                recipeIng.contains(userIng) || userIng.contains(recipeIng));
            if (!found) {
              missingIngredients.add(recipeIng);
            }
          }

          final recipeData = {
            'id': recipe['id'],
            'title': recipe['title'],
            'image': recipe['image'],
            'missedIngredientCount': missingIngredients.length,
            'missedIngredients': missingIngredients.take(3).toList(),
            'readyInMinutes': details['readyInMinutes'], // <-- Read from details
            'rating': details['rating'],               // <-- Read from details
            'author': details['author'],               // <-- Read from details
          };
          // ------------------------------------------

          if (missingIngredients.length <= 2) {
            complete.add(recipeData);
          } else {
            partial.add(recipeData);
          }
        }
      }

      setState(() {
        completeRecipes = complete;
        partialRecipes = partial;
        showResults = true;
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
      setState(() {
        showResults = false;
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _saveRecipe(Map<String, dynamic> recipe) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${recipe['title']} saved!'),
        backgroundColor: primaryGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _cookNow(Map<String, dynamic> recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailsScreen(
          recipeId: recipe['id'].toString(),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Vegetables':
        return Icons.eco;
      case 'Fruits':
        return Icons.apple;
      case 'Protein/Meat':
        return Icons.set_meal;
      case 'Grains & Carbs':
        return Icons.rice_bowl;
      case 'Sauces & Condiments':
        return Icons.liquor;
      case 'Dairy & Eggs':
        return Icons.egg;
      case 'Spices & Herbs':
        return Icons.grass;
      default:
        return Icons.circle;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Vegetables':
        return Colors.green;
      case 'Fruits':
        return Colors.orange;
      case 'Protein/Meat':
        return Colors.red;
      case 'Grains & Carbs':
        return Colors.brown;
      case 'Sauces & Condiments':
        return Colors.grey;
      case 'Dairy & Eggs':
        return Colors.blue;
      case 'Spices & Herbs':
        return Colors.green[700]!;
      default:
        return Colors.grey;
    }
  }

  Widget _buildCategoryBox(String category) {
    final ingredients = categoryIngredients[category] ?? [];
    final isExpanded = expandedCategories[category] ?? false;
    final selectedCount = _getSelectedCountInCategory(category);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                expandedCategories[category] = !isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    _getCategoryIcon(category),
                    color: _getCategoryColor(category),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      category,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '($selectedCount selected)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.arrow_drop_down : Icons.arrow_right,
                    color: Colors.grey[700],
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Column(
                children: ingredients.map((ingredient) {
                  final isSelected = selectedIngredients.contains(ingredient);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: CheckboxListTile(
                      value: isSelected,
                      onChanged: (val) {
                        if (val == true) {
                          _addIngredient(ingredient);
                        } else {
                          _removeIngredient(ingredient);
                        }
                      },
                      title: Text(
                        ingredient,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      activeColor: primaryGreen,
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // --- 3. UPDATED _buildRecipeCard METHOD ---
  Widget _buildRecipeCard(Map<String, dynamic> recipe, {bool isPartial = false}) {
    final missing = recipe['missedIngredients'] as List<dynamic>? ?? [];

    // Extract data with fallbacks
    final cookTime = recipe['readyInMinutes'] ?? 30;
    final author = recipe['author'] ?? recipe['userName'] ?? 'Author';
    final rating = (recipe['rating'] ?? 4.5).toDouble();
    
    // Handle nutrition for display
    int calories = 0;
    if (recipe['nutrition'] != null) {
      if (recipe['nutrition'] is Map) {
        final caloriesVal = recipe['nutrition']['calories'];
        calories = caloriesVal is int ? caloriesVal : int.tryParse(caloriesVal.toString()) ?? 0;
      }
    } else {
      calories = recipe['calories'] ?? 0;
    }
      
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: recipe['image'] != null && recipe['image'] != ''
                ? Image.network(
                    recipe['image'],
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 160,
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.restaurant, size: 40),
                      ),
                    ),
                  )
                : Container(
                    height: 160,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.restaurant, size: 40),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe['title'] ?? recipe['name'] ?? 'Recipe Name',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  author,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('$cookTime min', style: const TextStyle(fontSize: 12)),
                  ],
                ),
                if (isPartial && missing.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Missing: ${missing.join(", ")}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange[800],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _saveRecipe(recipe),
                        icon: const Icon(Icons.favorite_border, size: 16),
                        label: const Text('Save', style: TextStyle(fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _cookNow(recipe),
                        icon: const Icon(Icons.restaurant, size: 16),
                        label: const Text('Cook Now', style: TextStyle(fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (calories > 0)
                      Row(
                        children: [
                          const Icon(Icons.local_fire_department, size: 12, color: Colors.orange),
                          const SizedBox(width: 2),
                          Text('$calories kcal', style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        leading: IconButton(
          onPressed: showResults
              ? () => setState(() => showResults = false)
              : () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text(
          'What Can I Cook?',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (!showResults) ...[
                // Main white box containing everything
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      const Text(
                        'Select Available Ingredients:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Search bar
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search Ingredients...',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[100],
                          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.add_circle, color: primaryGreen),
                            onPressed: _addCustomIngredient,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _addCustomIngredient(),
                      ),
                      const SizedBox(height: 16),
                      
                      // Category boxes
                      ...categoryIngredients.keys.map((category) {
                        return _buildCategoryBox(category);
                      }),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Find Recipes Button (outside the white box)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _findRecipes,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Find Recipes (${selectedIngredients.length} selected)',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
              
              // Results page
              if (showResults) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Available Ingredients',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () => setState(() => showResults = false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primaryGreen,
                              side: BorderSide(color: primaryGreen),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text('Edit'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: selectedIngredients.map((ing) {
                          return Chip(
                            label: Text(ing),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              _removeIngredient(ing);
                              _findRecipes();
                            },
                            backgroundColor: const Color(0xFFD7F7C4),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                if (completeRecipes.isNotEmpty) ...[
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Complete Matches',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...completeRecipes.map((recipe) => _buildRecipeCard(recipe)),
                ],
                
                if (partialRecipes.isNotEmpty) ...[
                  const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(
                        'Partial Matches',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...partialRecipes.map((recipe) => _buildRecipeCard(recipe, isPartial: true)),
                ],
                
                if (completeRecipes.isEmpty && partialRecipes.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Text(
                        'No recipes found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
