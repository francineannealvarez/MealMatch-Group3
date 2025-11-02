// lib/screens/what_can_i_cook_screen.dart
import 'package:flutter/material.dart';
import 'package:mealmatch/services/spoonacular_services.dart';
import 'recipes_screen.dart';

class WhatCanICookScreen extends StatefulWidget {
  const WhatCanICookScreen({super.key});

  @override
  State<WhatCanICookScreen> createState() => _WhatCanICookScreenState();
}

class _WhatCanICookScreenState extends State<WhatCanICookScreen> {
  // controllers for each category (multiple ingredients per field separated by commas)
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _vegController = TextEditingController();
  final TextEditingController _grainsController = TextEditingController();
  final TextEditingController _saucesController = TextEditingController();
  final TextEditingController _dairyController = TextEditingController();
  final TextEditingController _spicesController = TextEditingController();

  bool isLoading = false;
  bool showResults = false;

  List<Map<String, dynamic>> completeRecipes = [];
  List<Map<String, dynamic>> partialRecipes = [];

  final Color primaryGreen = const Color(0xFF4CAF50);
  final Color pageBg = const Color(0xFFFFF6D7);

  @override
  void dispose() {
    _proteinController.dispose();
    _vegController.dispose();
    _grainsController.dispose();
    _saucesController.dispose();
    _dairyController.dispose();
    _spicesController.dispose();
    super.dispose();
  }

  List<String> _collectIngredients() {
    // split by commas, trim, remove empties
    final combinedText = [
      _proteinController.text,
      _vegController.text,
      _grainsController.text,
      _saucesController.text,
      _dairyController.text,
      _spicesController.text,
    ].join(',');

    final parts = combinedText
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    // dedupe (lowercase)
    final seen = <String>{};
    final result = <String>[];
    for (var p in parts) {
      final lower = p.toLowerCase();
      if (!seen.contains(lower)) {
        seen.add(lower);
        result.add(p);
      }
    }
    return result;
  }

  Future<void> _findRecipes() async {
    final ingredients = _collectIngredients();
    if (ingredients.isEmpty) {
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
      // call Spoonacular
      final found = await SpoonacularService.findByIngredients(ingredients, number: 10);

      // classify into complete vs partial by missedIngredientCount
      final complete = <Map<String, dynamic>>[];
      final partial = <Map<String, dynamic>>[];

      for (var r in found) {
        final missed = (r['missedIngredientCount'] ?? 0) as int;
        final mapped = {
          'id': r['id'],
          'name': r['title'],
          'image': r['image'],
          'missed': missed,
          'missingIngredients': r['missedIngredients'] ?? [],
        };
        if (missed == 0) complete.add(mapped);
        else partial.add(mapped);
      }

      setState(() {
        completeRecipes = complete;
        partialRecipes = partial;
        showResults = true;
      });
    } catch (e) {
      debugPrint("Find error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching recipes: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildInputField(String label, String hint, TextEditingController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Icon(Icons.circle, color: primaryGreen, size: 18),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[600]),
                  onPressed: () {
                    controller.clear();
                    setState(() {});
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe, {bool isPartial = false}) {
    final missing = recipe['missingIngredients'] as List<dynamic>? ?? [];
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.12), blurRadius: 6)],
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: recipe['image'] != null && recipe['image'] != ""
                  ? Image.network(
                      recipe['image'],
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: const Center(child: Icon(Icons.image_not_supported)),
                      ),
                    )
                  : Container(color: Colors.grey[200], child: const Center(child: Icon(Icons.image))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(recipe['name'] ?? '',
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              if (isPartial)
                Text(
                  'Missing: ${missing.join(", ")}',
                  style: const TextStyle(fontSize: 12, color: Colors.orange),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ]),
          )
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
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text('What Can I Cook?'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card containing inputs
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Select Your Available Ingredients:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF424242))),
                  const SizedBox(height: 12),
                  // Search hint (not implemented complexity - just UI)
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search ingredients...',
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Input fields (multiple per field separated by commas)
                  _buildInputField('Protein / Meat', 'e.g. chicken, pork, beef', _proteinController),
                  _buildInputField('Vegetables', 'e.g. onion, garlic, tomato', _vegController),
                  _buildInputField('Grains & Carbs', 'e.g. rice, noodles, pasta', _grainsController),
                  _buildInputField('Sauces & Condiments', 'e.g. soy sauce, vinegar', _saucesController),
                  _buildInputField('Dairy & Eggs', 'e.g. eggs, milk, cheese', _dairyController),
                  _buildInputField('Spices & Herbs', 'e.g. salt, pepper, bay leaf', _spicesController),
                ]),
              ),

              const SizedBox(height: 18),

              // Find Recipes button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.search),
                  label: Text(isLoading ? 'Searching...' : 'Find Recipes (${_collectIngredients().length} selected)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: isLoading ? null : _findRecipes,
                ),
              ),

              // Results (same screen)
              if (showResults) ...[
                const SizedBox(height: 20),
                if (completeRecipes.isNotEmpty) ...[
                  const Text('✅ Complete Matches', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: completeRecipes.length,
                      itemBuilder: (context, index) {
                        final r = completeRecipes[index];
                        return GestureDetector(
                          onTap: () {
                            // navigate to details
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RecipeDetailsScreen(recipeId: r['id']),
                              ),
                            );
                          },
                          child: _buildRecipeCard(r, isPartial: false),
                        );
                      },
                    ),
                  ),
                ] else
                  const SizedBox.shrink(),

                const SizedBox(height: 20),

                if (partialRecipes.isNotEmpty) ...[
                  const Text('⚠️ Partial Matches', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: partialRecipes.length,
                      itemBuilder: (context, index) {
                        final r = partialRecipes[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RecipeDetailsScreen(recipeId: r['id']),
                              ),
                            );
                          },
                          child: _buildRecipeCard(r, isPartial: true),
                        );
                      },
                    ),
                  ),
                ] else
                  const SizedBox.shrink(),
              ],

              const SizedBox(height: 40)
            ],
          ),
        ),
      ),
    );
  }
}
