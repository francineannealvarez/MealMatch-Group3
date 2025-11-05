// lib/screens/recipes_screen.dart
import 'package:flutter/material.dart';
import 'package:mealmatch/screens/recipes_screen.dart';
import 'package:mealmatch/services/spoonacular_services.dart';

class RecipesPage extends StatefulWidget {
  const RecipesPage({super.key});

  @override
  State<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> {
  bool isLoading = true;
  int _selectedIndex = 1;

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
      final results = await SpoonacularService.findByIngredients(
        demoIngredients,
      );

      setState(() {
        fullMatches = results
            .where((r) => (r['missedIngredientCount'] ?? 0) == 0)
            .toList();

        partialMatches = results
            .where((r) => (r['missedIngredientCount'] ?? 0) > 0)
            .toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error loading recipes: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6D7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        title: const SizedBox.shrink(),
        flexibleSpace: SafeArea(
          child: Center(
            child: Text(
              "Recipes",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRecipes,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  if (fullMatches.isNotEmpty) ...[
                    const Text(
                      "Complete Match 🎯",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...fullMatches.map((item) => recipeCard(item)),
                    const SizedBox(height: 20),
                  ],
                  if (partialMatches.isNotEmpty) ...[
                    const Text(
                      "Partial Match ✅",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                    ),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget recipeCard(Map<String, dynamic> recipe) {
    final String title = recipe['title'] ?? 'No Title';
    final String imageUrl =
        recipe['image'] ?? "https://via.placeholder.com/150?text=No+Image";

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
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
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
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
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

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          switch (index) {
            case 0: // Home
              Navigator.pushNamed(context, '/home').then((_) {
                setState(() {
                  _selectedIndex = 0;
                });
              });
              break;
            case 1: // Recipes
              Navigator.pushNamed(context, '/recipes').then((_) {
                setState(() {
                  _selectedIndex = 1;
                });
              });
              break;
            case 2: // Add
              Navigator.pushNamed(context, '/add').then((_) {
                setState(() {
                  _selectedIndex = 2;
                });
              });
              break;
            case 3: // Log History
              Navigator.pushNamed(context, '/history').then((_) {
                setState(() {
                  _selectedIndex = 3;
                });
              });
              break;
            case 4: // Profile
              Navigator.pushNamed(context, '/profile').then((_) {
                setState(() {
                  _selectedIndex = 4;
                });
              });
              break;
          }
        },

        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF4CAF50),
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        elevation: 0,
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              _selectedIndex == 0 ? Icons.home : Icons.home_outlined,
              color: _selectedIndex == 0
                  ? const Color(0xFF4CAF50)
                  : Colors.grey,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.restaurant_menu,
              color: _selectedIndex == 1
                  ? const Color(0xFF4CAF50)
                  : Colors.grey,
            ),
            label: 'Recipes',
          ),
          BottomNavigationBarItem(
            icon: Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.history,
              color: _selectedIndex == 3
                  ? const Color(0xFF4CAF50)
                  : Colors.grey,
            ),
            label: 'Log History',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.person,
              color: _selectedIndex == 4
                  ? const Color(0xFF4CAF50)
                  : Colors.grey,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
