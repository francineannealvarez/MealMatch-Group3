// lib/screens/recipe_details_screen.dart
import 'package:flutter/material.dart';
import 'package:mealmatch/services/spoonacular_services.dart';

class RecipeDetailsScreen extends StatefulWidget {
  final int recipeId;
  const RecipeDetailsScreen({super.key, required this.recipeId});

  @override
  State<RecipeDetailsScreen> createState() => _RecipeDetailsScreenState();
}

class _RecipeDetailsScreenState extends State<RecipeDetailsScreen> {
  bool loading = true;
  Map<String, dynamic>? data;
  final Color primaryGreen = const Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final info = await SpoonacularService.getRecipeInformation(widget.recipeId);
      setState(() {
        data = info;
      });
    } catch (e) {
      debugPrint("Details error: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading recipe: $e')));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6D7),
      appBar: AppBar(
        title: const Text('Recipe Details'),
        backgroundColor: primaryGreen,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : data == null
              ? const Center(child: Text('No details available'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image top
                      data!['image'] != null
                          ? Image.network(
                              data!['image'],
                              width: double.infinity,
                              height: 220,
                              fit: BoxFit.cover,
                            )
                          : Container(height: 220, color: Colors.grey[200]),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data!['title'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(children: [
                              if (data!['readyInMinutes'] != null)
                                Row(children: [
                                  const Icon(Icons.access_time, size: 16),
                                  const SizedBox(width: 6),
                                  Text('${data!['readyInMinutes']} mins'),
                                  const SizedBox(width: 12),
                                ]),
                              if (data!['servings'] != null)
                                Row(children: [
                                  const Icon(Icons.restaurant, size: 16),
                                  const SizedBox(width: 6),
                                  Text('${data!['servings']} servings'),
                                ]),
                              const Spacer(),
                              if (data!['calories'] != null && (data!['calories'] as String).isNotEmpty)
                                Text(data!['calories'], style: const TextStyle(color: Colors.grey)),
                            ]),
                            const SizedBox(height: 12),

                            const Text('Ingredients', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            ...((data!['ingredients'] ?? []) as List).map((ing) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Text("• $ing"),
                                )),

                            const SizedBox(height: 12),
                            const Text('Instructions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Text(
                              data!['instructions']?.toString().isNotEmpty == true ? data!['instructions'] : 'No instructions available',
                              style: const TextStyle(height: 1.4),
                            ),

                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.restaurant),
                                label: const Text('Start Cooking'),
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
