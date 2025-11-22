import 'package:flutter/material.dart';
import '../services/profile_service.dart';
import 'package:mealmatch/screens/recipe_details_screen.dart';
import '../services/recipe_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final RecipeService _recipeService = RecipeService();

  int _selectedTab = 0;
  int _selectedIndex = 4;
  bool isLoading = true;

  // Profile Data
  String userName = 'Loading...';
  String userEmail = 'loading@example.com';
  int currentStreak = 0;
  int avgDailyCalories = 0;
  int weeklyGoalDays = 0;
  int recipeCount = 0;
  int totalLikes = 0;
  String? avatarPath;

  // Lists
  List<Map<String, dynamic>> achievements = [];
  List<Map<String, dynamic>> _userRecipes = []; // Fetched from Firebase

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (mounted) {
      _loadProfileData();
    }
  }

  Future<void> _loadProfileData() async {
    if (achievements.isEmpty && _userRecipes.isEmpty) {
      setState(() => isLoading = true);
    }

    try {
      // 1. Load Profile Stats
      final profileData = await _profileService.getProfileData();

      // 2. Load User Recipes from RecipeService
      final recipes = await _recipeService.getUserRecipes();

      // 3. Load Achievements
      final loadedAchievements = await _profileService.getAchievements();

      // 4. Find new achievements to show "NEW" badge logic
      final newAchievements = loadedAchievements
          .where((a) => a['isNew'] == true)
          .toList();

      if (mounted) {
        setState(() {
          userName = profileData['name'] ?? 'User';
          userEmail = profileData['email'] ?? 'No email';
          currentStreak = profileData['streak'] ?? 0;
          avgDailyCalories = profileData['avgCalories'] ?? 0;
          weeklyGoalDays = profileData['weeklyGoalDays'] ?? 0;
          totalLikes = profileData['totalLikes'] ?? 0;
          avatarPath = profileData['avatar'];
          
          // Update recipe data
          _userRecipes = recipes;
          recipeCount = recipes.length;

          achievements = loadedAchievements;
          isLoading = false;
        });

        // Handle "New Achievement" badge removal delay
        if (newAchievements.isNotEmpty) {
          await Future.delayed(const Duration(seconds: 2));
          final idsToMark = newAchievements.map((a) => a['id'] as String).toList();
          await _profileService.markAchievementsAsViewed(idsToMark);
          
          if (mounted) {
            setState(() {
              for (var achievement in achievements) {
                if (idsToMark.contains(achievement['id'])) {
                  achievement['isNew'] = false;
                }
              }
            });
          }
        }
      }
    } catch (e) {
      print('Error loading profile: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5CF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () async {
              final result = await Navigator.pushNamed(context, '/settings');
              if (result == true && mounted) {
                _loadProfileData();
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? _buildSkeletonProfileScreen()
          : RefreshIndicator(
              color: const Color(0xFF4CAF50),
              onRefresh: _loadProfileData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildProfileHeader(),
                    const SizedBox(height: 16),
                    _buildTabSelector(),
                    const SizedBox(height: 16),
                    if (_selectedTab == 0) _buildProgressTab(),
                    if (_selectedTab == 1) _buildMyRecipesTab(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ==========================================
  // UI: SKELETON SCREEN (Restored)
  // ==========================================
  Widget _buildSkeletonProfileScreen() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Skeleton Header
          Column(
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFC107), width: 3),
                  color: Colors.grey[300],
                ),
              ),
              const SizedBox(height: 12),
              Container(width: 150, height: 24, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 8),
              Container(width: 200, height: 16, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 60, height: 40, color: Colors.grey[300]),
                  const SizedBox(width: 48),
                  Container(width: 60, height: 40, color: Colors.grey[300]),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Skeleton Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Expanded(child: Container(height: 40, color: Colors.grey[300])),
              const SizedBox(width: 10),
              Expanded(child: Container(height: 40, color: Colors.grey[200])),
            ]),
          ),
          const SizedBox(height: 20),
          // Skeleton Cards
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 120,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          ),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 120,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // UI: HEADER
  // ==========================================
  Widget _buildProfileHeader() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFFC107), width: 3),
            color: Colors.grey[300],
          ),
          child: ClipOval(
            child: avatarPath != null
                ? Image.asset(
                    avatarPath!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildAvatarPlaceholder(),
                  )
                : _buildAvatarPlaceholder(),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          userName,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 4),
        Text(
          userEmail,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StatItem(label: 'Recipes', value: '$recipeCount'),
            const SizedBox(width: 48),
            _StatItem(label: 'Likes', value: '$totalLikes'),
            // Optional: Add Followers if backend supports it, otherwise hidden
            // const SizedBox(width: 48),
            // const _StatItem(label: 'Followers', value: '0'),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: const Icon(Icons.person, size: 40, color: Colors.grey),
    );
  }

  // ==========================================
  // UI: TABS
  // ==========================================
  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _selectedTab == 0 ? const Color(0xFF4CAF50) : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  'Progress',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _selectedTab == 0 ? Colors.black : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _selectedTab == 1 ? const Color(0xFF4CAF50) : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  'My Recipes',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _selectedTab == 1 ? Colors.black : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // UI: PROGRESS TAB (Restored)
  // ==========================================
  Widget _buildProgressTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWeeklyGoalCard(),
          const SizedBox(height: 16),
          _buildCaloriesAndStreak(),
          const SizedBox(height: 16),
          _buildAchievementsCard(),
        ],
      ),
    );
  }

  Widget _buildWeeklyGoalCard() {
    double progress = weeklyGoalDays / 7.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Weekly Goal',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16),
              ),
              Text('$weeklyGoalDays/7 days', style: const TextStyle(color: Colors.grey, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade300,
              color: const Color(0xFF4CAF50),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            weeklyGoalDays == 0
                ? 'Start your journey today!'
                : weeklyGoalDays == 7
                    ? '🎉 Amazing! You logged every day this week!'
                    : 'Keep going! ${7 - weeklyGoalDays} more day${7 - weeklyGoalDays == 1 ? '' : 's'} to go!',
            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildCaloriesAndStreak() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Avg. Daily Kcal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                Text('$avgDailyCalories kcal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xFFFF9800))),
                const SizedBox(height: 8),
                Text(avgDailyCalories == 0 ? 'No data yet' : 'Last 7 days', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Current Streak', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                Text('$currentStreak Day${currentStreak == 1 ? '' : 's'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xFF4CAF50))),
                const SizedBox(height: 8),
                Text(
                  currentStreak == 0 ? 'Start logging!' : 'Keep it up! 🔥',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🎖 Achievements', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 120),
            child: achievements.isEmpty
                ? Center(
                    child: Column(
                      children: [
                        Icon(Icons.emoji_events_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text('No achievements yet', style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  )
                : Column(
                    children: achievements.map((achievement) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildAchievementBadge(
                          achievement['icon'],
                          achievement['title'],
                          achievement['isNew'],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementBadge(String icon, String title, bool isNew) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isNew ? const Color(0xFF4CAF50).withOpacity(0.1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNew ? const Color(0xFF4CAF50) : Colors.grey[300]!,
          width: isNew ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isNew ? FontWeight.bold : FontWeight.w600,
                color: isNew ? const Color(0xFF4CAF50) : Colors.black,
              ),
            ),
          ),
          if (isNew)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
              child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // UI: RECIPES TAB (Dynamic Data + Old UI)
  // ==========================================
  Widget _buildMyRecipesTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          if (_userRecipes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No recipes yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start creating your first recipe!',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _userRecipes.length,
              itemBuilder: (context, index) {
                return _buildClickableRecipeCard(_userRecipes[index]);
              },
            ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              await Navigator.pushNamed(context, '/upload');
              _loadProfileData();
            },
            icon: const Icon(Icons.add, color: Color(0xFF4CAF50)),
            label: const Text(
              'Add New Recipe',
              style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF4CAF50), width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // Clickable recipe card (same style as home page)
  Widget _buildClickableRecipeCard(Map<String, dynamic> recipe) {
    try {
      print('🔍 === PROFILE RECIPE CARD DEBUG ===');
      print('Recipe ID: ${recipe['id']}');
      print('Recipe ID type: ${recipe['id'].runtimeType}');

      // Extract title/name
      String title = 'Recipe Name';
      if (recipe['title'] != null && recipe['title'] is String) {
        title = recipe['title'] as String;
      } else if (recipe['name'] != null && recipe['name'] is String) {
        title = recipe['name'] as String;
      }
      print('✅ Title: $title');

      // Extract author/userName
      String author = 'By You';
      if (recipe['author'] != null && recipe['author'] is String) {
        author = recipe['author'] as String;
      } else if (recipe['userName'] != null && recipe['userName'] is String) {
        author = recipe['userName'] as String;
      }
      print('✅ Author: $author');

      // Extract cook time
      int cookTime = 0;
      if (recipe['cookTime'] != null) {
        if (recipe['cookTime'] is int) {
          cookTime = recipe['cookTime'] as int;
        } else if (recipe['cookTime'] is String) {
          cookTime = int.tryParse(recipe['cookTime'].toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        } else if (recipe['readyInMinutes'] is int) {
          cookTime = recipe['readyInMinutes'] as int;
        }
      } else if (recipe['readyInMinutes'] != null) {
        if (recipe['readyInMinutes'] is int) {
          cookTime = recipe['readyInMinutes'] as int;
        } else {
          cookTime = int.tryParse(recipe['readyInMinutes'].toString()) ?? 0;
        }
      }
      print('✅ CookTime: $cookTime');

      // Extract calories
      int calories = 0;
      if (recipe['nutrition'] != null && recipe['nutrition'] is Map) {
        final nutrition = recipe['nutrition'] as Map;
        if (nutrition['calories'] != null) {
          calories = int.tryParse(nutrition['calories'].toString()) ?? 0;
        }
      } else if (recipe['calories'] != null) {
        calories = int.tryParse(recipe['calories'].toString()) ?? 0;
      }
      print('✅ Calories: $calories');

      // Extract rating
      double rating = 5.0;
      if (recipe['rating'] != null) {
        if (recipe['rating'] is double) {
          rating = recipe['rating'] as double;
        } else if (recipe['rating'] is int) {
          rating = (recipe['rating'] as int).toDouble();
        } else {
          rating = double.tryParse(recipe['rating'].toString()) ?? 5.0;
        }
      }
      print('✅ Rating: $rating');

      // Extract image
      String image = '';
      if (recipe['image'] != null && recipe['image'] is String) {
        image = recipe['image'] as String;
      } else if (recipe['strMealThumb'] != null) {
        image = recipe['strMealThumb'].toString();
      } else if (recipe['localImagePath'] != null) {
        image = recipe['localImagePath'].toString();
      }
      print('✅ Image: ${image.isEmpty ? "No image" : image}');

      // Get the recipe ID as String
      final recipeId = recipe['id'].toString();
      print('✅ RecipeID for navigation: $recipeId');
      print('✅ All extractions complete!');

      return GestureDetector(
        onTap: () {
          print('📍 Tapping recipe: $recipeId');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeDetailsScreen(
                recipeId: recipeId,  // This will work for both public and private
                isOwnRecipe: true,
              ),
            ),
          ).then((_) {
            _loadProfileData();
          });
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
                // Background Image
                Positioned.fill(
                  child: image.isNotEmpty
                      ? Image.network(
                          image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.restaurant, size: 40),
                          ),
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.restaurant, size: 40),
                        ),
                ),

                // Gradient Overlay
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

                // "Your Recipe" Badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'YOURS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Recipe Info
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
                          if (calories > 0)
                            Text(
                              '$calories kcal',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (cookTime > 0)
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
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 14,
                              ),
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
    } catch (e, stackTrace) {
      print('❌ FATAL ERROR in profile recipe card: $e');
      print('❌ Stack trace: $stackTrace');
      print('❌ Full recipe data: $recipe');

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 32),
                const SizedBox(height: 8),
                Text(
                  'Error loading recipe',
                  style: TextStyle(fontSize: 12, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  /* ✅ IMPROVED: Recipe card with better data display
  Widget _buildRecipeCard(String name, String details, String kcal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
            child: Container(
              width: 110,
              height: 100,
              color: Colors.grey.shade300,
              child: const Center(
                child: Icon(Icons.restaurant, size: 40, color: Colors.grey),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    maxLines: 1, // ✅ ADDED: Prevent overflow
                    overflow: TextOverflow.ellipsis, // ✅ ADDED
                  ),
                  const SizedBox(height: 6),
                  Text(
                    details,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    maxLines: 1, // ✅ ADDED
                    overflow: TextOverflow.ellipsis, // ✅ ADDED
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        kcal,
                        style: const TextStyle(
                          color: Color(0xFFFF9800),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const Icon(Icons.favorite_border, color: Colors.red, size: 18),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  } */

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.2),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  // ==========================================
  // UI: BOTTOM NAVIGATION (Restored Routing)
  // ==========================================
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
          // Use Navigator for switching screens logic from previous code
          switch (index) {
            case 0: // Home
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1: // Recipes
              Navigator.pushReplacementNamed(context, '/recipes');
              break;
            case 2: // Add
              Navigator.pushNamed(context, '/upload');
              break;
            case 3: // Log History
              Navigator.pushReplacementNamed(context, '/history');
              break;
            case 4: // Profile
              if (_selectedIndex == 4) {
                _loadProfileData();
              }
              setState(() {
                _selectedIndex = 4;
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
              color: _selectedIndex == 0 ? const Color(0xFF4CAF50) : Colors.grey,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.restaurant_menu,
              color: _selectedIndex == 1 ? const Color(0xFF4CAF50) : Colors.grey,
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
              color: _selectedIndex == 3 ? const Color(0xFF4CAF50) : Colors.grey,
            ),
            label: 'Log History',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.person,
              color: _selectedIndex == 4 ? const Color(0xFF4CAF50) : Colors.grey,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Helper widget for stats
class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
