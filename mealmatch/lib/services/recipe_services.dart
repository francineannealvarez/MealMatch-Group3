// lib/screens/recipes_screen.dart
import 'package:flutter/material.dart';
import 'package:mealmatch/screens/recipes_screen.dart';
import 'package:mealmatch/services/spoonacular_services.dart';
import 'package:mealmatch/screens/recipes_screen.dart';

class RecipesPage extends StatefulWidget {
  const RecipesPage({super.key});

  @override
  State<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> {
  bool isLoading = true;

  List<Map<String, dynamic>> fullMatches = [];
  List<Map<String, dynamic>> partialMatches = [];

  // Temporary SAMPLE ingredients to show results 🔥
  // Replace later with user’s selections ✅
  final List<String> demoIngredients = ["chicken", "rice", "egg"];

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    setState(() => isLoading = true);

    try {
      final results = await SpoonacularService.findByIngredients(demoIngredients);

      setState(() {
        fullMatches = results
            .where((r) => (r['missedIngredientCount'] ?? 0) == 0)
            .toList();

        partialMatches = results
            .where((r) => (r['missedIngredientCount'] ?? 0) > 0)
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading recipes: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6D7),
      appBar: AppBar(
        title: const Text("Recipes"),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRecipes,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  if (fullMatches.isNotEmpty) ...[
                    const Text("Complete Match 🎯",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...fullMatches.map((item) => recipeCard(item)),
                    const SizedBox(height: 20),
                  ],
                  if (partialMatches.isNotEmpty) ...[
                    const Text("Partial Match ✅",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...partialMatches.map((item) => recipeCard(item)),
                  ],
                  if (fullMatches.isEmpty && partialMatches.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          "No recipes found.\nTry adding ingredients!",
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                ],
              ),
            ),
    );
  }

  Widget recipeCard(Map<String, dynamic> recipe) {
    final String title = recipe['title'] ?? 'No Title';
    final String imageUrl = recipe['image'] ??
        "https://via.placeholder.com/150?text=No+Image";

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecipeDetailsScreen(recipeId: recipe['id']),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              child: Image.network(
                imageUrl,
                width: 110,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.chevron_right),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
