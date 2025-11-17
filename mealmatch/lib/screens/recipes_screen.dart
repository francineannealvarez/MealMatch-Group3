import 'package:flutter/material.dart';
import 'package:mealmatch/services/themealdb_service.dart';
import 'package:mealmatch/screens/recipe_details_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> recipes = []; // For search results
  
  // Lists for each category
  List<Map<String, dynamic>> popularRecipes = [];
  List<Map<String, dynamic>> highProteinRecipes = [];
  List<Map<String, dynamic>> vegetarianRecipes = [];
  List<Map<String, dynamic>> dessertRecipes = [];

  // Loading states for each category
  bool isLoadingPopular = true;
  bool isLoadingProtein = true;
  bool isLoadingVegetarian = true;
  bool isLoadingDesserts = true;
  
  bool isSearching = false;
  bool showSearchResults = false;

  // State for Favorites
  List<String> _savedRecipeIds = []; // Stores IDs of saved recipes
  List<Map<String, dynamic>> _favoriteRecipes = []; // Stores full data for favorites
  bool _isLoadingFavorites = false;

  final Color primaryGreen = const Color(0xFF4CAF50);
  final Color pageBg = const Color(0xFFFFF6D7);
  
  late TabController _tabController;
  int _selectedFilterIndex = 0;
  int _bottomNavIndex = 1; // 1 = Recipes (for the bottom bar)

 @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _initializeData(); // <-- NEW helper function
  }

  Future<void> _initializeData() async {
    // 1. Load the user's saved favorites *first*
    await _loadUserFavorites();
    
    // 2. Now that we know what's saved, load the recipe categories
    _loadAllRecipes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.index == 1 && !_tabController.indexIsChanging) {
      _loadFavorites();
    }
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  Future<void> _loadAllRecipes() async {
    _loadPopularRecipes();
    _loadHighProteinRecipes();
    _loadCategoryRecipes('Vegetarian', (meals) => vegetarianRecipes = meals, (loading) => isLoadingVegetarian = loading);
    _loadCategoryRecipes('Dessert', (meals) => dessertRecipes = meals, (loading) => isLoadingDesserts = loading);
  }

  Future<void> _loadPopularRecipes() async {
    setState(() => isLoadingPopular = true);
    try {
      final meals = await TheMealDBService.getRandomMeals(6);
      setState(() {
        popularRecipes = meals;
        isLoadingPopular = false;
      });
    } catch (e) {
      print('Error loading random recipes: $e');
      setState(() => isLoadingPopular = false);
    }
  }

  Future<void> _loadHighProteinRecipes() async {
    setState(() => isLoadingProtein = true);
    try {
      final results = await Future.wait([
        TheMealDBService.getMealsByCategory('Chicken', number: 2),
        TheMealDBService.getMealsByCategory('Beef', number: 2),
        TheMealDBService.getMealsByCategory('Pork', number: 2),
      ]);

      final allProteinRecipes = <Map<String, dynamic>>[];
      for (var list in results) {
        allProteinRecipes.addAll(list);
      }
      allProteinRecipes.shuffle();

      setState(() {
        highProteinRecipes = allProteinRecipes;
        isLoadingProtein = false;
      });
    } catch (e) {
      print('Error loading high protein recipes: $e');
      setState(() => isLoadingProtein = false);
    }
  }

  Future<void> _loadCategoryRecipes(
    String category,
    void Function(List<Map<String, dynamic>>) setMeals,
    void Function(bool) setLoading,
  ) async {
    setState(() => setLoading(true));
    try {
      final meals = await TheMealDBService.getMealsByCategory(category, number: 6);
      setState(() {
        setMeals(meals);
        setLoading(false);
      });
    } catch (e) {
      print('Error loading category $category: $e');
      setState(() => setLoading(false));
    }
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoadingFavorites = true);
    try {
      final loadedFavs = <Map<String, dynamic>>[];
      for (String id in _savedRecipeIds) {
        final details = await TheMealDBService.getMealDetails(id);
        if (details != null) {
          loadedFavs.add(details);
        }
      }
      setState(() {
        _favoriteRecipes = loadedFavs;
        _isLoadingFavorites = false;
      });
    } catch (e) {
      print('Error loading favorites: $e');
      setState(() => _isLoadingFavorites = false);
    }
  }

  Future<void> _loadUserFavorites() async {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      print("No user logged in, cannot load favorites.");
      return; // No user, so no favorites to load
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data.containsKey('favoriteRecipeIds')) {
          // Get the list from Firebase and convert it (it's List<dynamic>)
          final firebaseList = List<String>.from(data['favoriteRecipeIds']);
          setState(() {
            _savedRecipeIds = firebaseList;
          });
        }
      } else {
        // This is the user's first time, so we can create their document
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'favoriteRecipeIds': [] // Start with an empty list
        });
      }
    } catch (e) {
      print("Error loading user favorites: $e");
    }
  }

  void _toggleFavorite(String recipeId) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      // Show an error if the user isn't logged in
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to save favorites')),
      );
      return;
    }

    // Get the reference to the user's document
    final docRef = FirebaseFirestore.instance.collection('users').doc(userId);

    if (_savedRecipeIds.contains(recipeId)) {
      // --- REMOVE FROM FAVORITES ---
      
      // 1. Update Firebase
      docRef.update({
        'favoriteRecipeIds': FieldValue.arrayRemove([recipeId])
      });
      
      // 2. Update local state
      setState(() {
        _savedRecipeIds.remove(recipeId);
      });

    } else {
      // --- ADD TO FAVORITES ---

      // 1. Update Firebase
      docRef.update({
        'favoriteRecipeIds': FieldValue.arrayUnion([recipeId])
      });

      // 2. Update local state
      setState(() {
        _savedRecipeIds.add(recipeId);
      });
    }
  }

  Future<void> _searchRecipes(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        showSearchResults = false;
        recipes = [];
      });
      return;
    }

    setState(() {
      isSearching = true;
      showSearchResults = true;
    });

    try {
      final results = await TheMealDBService.searchRecipes(query);
      setState(() {
        recipes = results;
        isSearching = false;
      });
    } catch (e) {
      print('Error searching recipes: $e');
      setState(() {
        isSearching = false;
      });
    }
  }

  Widget _buildGridRecipeCard(Map<String, dynamic> recipe, bool isSaved) {
    final String title = recipe['title'] ?? 'Recipe Name';
    final String author = recipe['author'] ?? 'By Author';
    final int cookTime = recipe['readyInMinutes'] ?? 0;
    final int calories = recipe['nutrition']?['calories'] ?? 0;
    final double rating = recipe['rating']?.toDouble() ?? 4.5;
    
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailsScreen(
              recipeId: recipe['id'].toString(),
            ),
          ),
        );

        await _loadUserFavorites();

        if (_tabController.index == 1) {
          _loadFavorites();
        }
      },

      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              Positioned.fill(
                child: recipe['image'] != null && recipe['image'] != ''
                    ? Image.network(
                        recipe['image'],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_not_supported, size: 40),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.restaurant, size: 40),
                      ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.9),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0, 0.3, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () {
                    _toggleFavorite(recipe['id'].toString());
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSaved ? Icons.favorite : Icons.favorite_border,
                      color: isSaved ? Colors.red : Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        shadows: [Shadow(blurRadius: 2, color: Colors.black)],
                      ),
                    ),
                    Text(
                      author,
                      maxLines: 1,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        shadows: [Shadow(blurRadius: 2, color: Colors.black)],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$calories kcal',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$cookTime mins',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 2),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeGrid(List<Map<String, dynamic>> recipeList) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: recipeList.length,
      itemBuilder: (context, index) {
        final recipe = recipeList[index];
        final isSaved = _savedRecipeIds.contains(recipe['id'].toString());
        return _buildGridRecipeCard(recipe, isSaved);
      },
    );
  }

  Widget _buildCategorySection({
    required String title,
    required bool isLoading,
    required List<Map<String, dynamic>> recipeList,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        if (isLoading)
          const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
        else if (recipeList.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No recipes found.')))
        else
          _buildRecipeGrid(recipeList),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDiscoverTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16), // Add spacing from TabBar
          
          if (showSearchResults) ...[
            // --- Search Results ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${_capitalizeFirstLetter(_searchController.text)} Recipes', 
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (isSearching)
              const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
            else if (recipes.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Text('No recipes found.'),
                ),
              )
            else
              _buildRecipeGrid(recipes),
              
          ] else ...[
            // --- Show all category sections ---
            _buildCategorySection(
              title: 'Popular Recipes',
              isLoading: isLoadingPopular,
              recipeList: popularRecipes,
            ),
            _buildCategorySection(
              title: 'Discover High Protein Recipes',
              isLoading: isLoadingProtein,
              recipeList: highProteinRecipes,
            ),
            _buildCategorySection(
              title: 'Discover Vegetarian Recipes',
              isLoading: isLoadingVegetarian,
              recipeList: vegetarianRecipes,
            ),
            _buildCategorySection(
              title: 'Discover Desserts',
              isLoading: isLoadingDesserts,
              recipeList: dessertRecipes,
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFilterChip(int index, String label) {
    bool isSelected = _selectedFilterIndex == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This filter is not supported by the free API.'),
              backgroundColor: Colors.orange,
            ),
          );
        },
        backgroundColor: primaryGreen.withOpacity(0.1),
        selectedColor: primaryGreen.withOpacity(0.3),
        labelStyle: TextStyle(
          color: primaryGreen,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: primaryGreen.withOpacity(0.2),
          ),
        ),
        showCheckmark: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      // --- 1. APPBAR ADDED ---
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text(
          'Recipes',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      // --- 2. BODY IS NOW A COLUMN ---
      body: Column(
        children: [
          // --- Search Bar ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for recipes...',
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () {
                    // TODO: Show filter dialog
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              onSubmitted: _searchRecipes,
            ),
          ),
          
          // --- Filter Chips ---
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip(0, 'All'),
                _buildFilterChip(1, 'High-Protein'),
                _buildFilterChip(2, 'Vegetarian'),
                _buildFilterChip(3, 'Gluten-Free'),
                _buildFilterChip(4, 'Low-Carbs'),
              ],
            ),
          ),

          // --- TabBar (Discover/Favorites) ---
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: primaryGreen,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              tabs: const [
                Tab(text: 'Discover'),
                Tab(text: 'Favorites'),
              ],
            ),
          ),

          // --- TabBarView (Fills remaining space) ---
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // --- Discover Tab ---
                _buildDiscoverTab(),
                
                // --- Favorites Tab ---
                _isLoadingFavorites
                    ? const Center(child: CircularProgressIndicator())
                    : _favoriteRecipes.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.favorite_border, size: 80, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'Your saved recipes will appear here.',
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: _buildRecipeGrid(_favoriteRecipes),
                            ),
                          ),
              ],
            ),
          ),
        ],
      ),
      // --- 3. BOTTOMNAVBAR FIXED ---
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomNavIndex, // This is 1 (Recipes)
        onTap: (index) {
          // Don't do anything if we tap the current screen (Recipes)
          if (index == _bottomNavIndex) return;

          // Handle navigation for other taps
          switch (index) {
            case 0:
              // Home: Pop this screen to return to the homepage
              Navigator.pop(context);
              break;
            case 1:
              // Recipes: We are already here, do nothing.
              break;
            case 2:
              // Upload:
              Navigator.pushNamed(context, '/upload');
              break;
            case 3:
              // Log History:
              Navigator.pushNamed(context, '/history');
              break;
            case 4:
              // Profile:
              Navigator.pushNamed(context, '/profile');
              break;
          }
        },
        type: BottomNavigationBarType.fixed, // Shows all labels
        selectedItemColor: primaryGreen,
        unselectedItemColor: Colors.grey[700],
        showUnselectedLabels: true,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu_outlined),
            activeIcon: Icon(Icons.restaurant_menu),
            label: 'Recipes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle, size: 36),
            label: '', // No label for add button
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Log History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
