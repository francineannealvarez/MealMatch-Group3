import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // 📧 Get user email from Firebase Auth
  String getUserEmail() {
    return _auth.currentUser?.email ?? 'No email';
  }

  // 👤 Get user name from Firestore
  Future<String> getUserName() async {
    try {
      final userId = currentUserId;
      if (userId == null) return 'User';

      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['name'] ?? 'User';
      }
      return 'User';
    } catch (e) {
      print('Error getting user name: $e');
      return 'User';
    }
  }

  // 🔥 Get current streak (consecutive days of logging)
  Future<int> getCurrentStreak() async {
    try {
      final userId = currentUserId;
      if (userId == null) return 0;

      // Get all meal logs sorted by date descending
      final logsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('meal_logs')
          .orderBy('timestamp', descending: true)
          .get();

      if (logsSnapshot.docs.isEmpty) return 0;

      // Group logs by date
      Map<String, bool> loggedDates = {};
      for (var doc in logsSnapshot.docs) {
        final timestamp = (doc.data()['timestamp'] as Timestamp).toDate();
        final dateKey = '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
        loggedDates[dateKey] = true;
      }

      // Calculate streak starting from today
      int streak = 0;
      DateTime currentDate = DateTime.now();

      while (true) {
        final dateKey = '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}';
        
        if (loggedDates.containsKey(dateKey)) {
          streak++;
          currentDate = currentDate.subtract(const Duration(days: 1));
        } else {
          // If it's today and no log yet, don't break streak
          if (streak == 0 && _isToday(currentDate)) {
            currentDate = currentDate.subtract(const Duration(days: 1));
            continue;
          }
          break;
        }
      }

      return streak;
    } catch (e) {
      print('Error calculating streak: $e');
      return 0;
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  // Helper: Format date as YYYY-MM-DD
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // 📊 Get average daily calories (last 7 days)
  Future<int> getAvgDailyCalories() async {
    try {
      final userId = currentUserId;
      if (userId == null) return 0;

      // Get logs from last 7 days
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      
      final logsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('meal_logs')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
          .get();

      if (logsSnapshot.docs.isEmpty) return 0;

      // Group by date and calculate daily totals
      Map<String, double> dailyCalories = {};
      
      for (var doc in logsSnapshot.docs) {
        final data = doc.data();
        final timestamp = (data['timestamp'] as Timestamp).toDate();
        final dateKey = '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
        final calories = (data['calories'] ?? 0).toDouble();

        dailyCalories[dateKey] = (dailyCalories[dateKey] ?? 0) + calories;
      }

      // Calculate average
      if (dailyCalories.isEmpty) return 0;
      
      final total = dailyCalories.values.reduce((a, b) => a + b);
      final average = total / dailyCalories.length;

      return average.round();
    } catch (e) {
      print('Error calculating avg calories: $e');
      return 0;
    }
  }

  // 📅 Get weekly goal progress (days logged this week)
  Future<Map<String, dynamic>> getWeeklyGoalProgress() async {
    try {
      final userId = currentUserId;
      if (userId == null) return {'daysLogged': 0, 'totalDays': 7};

      /* Get start of current week (if want to  start at Monday)
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartMidnight = DateTime(weekStart.year, weekStart.month, weekStart.day);*/

      // Get start of current week (Sunday)
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday % 7));
      final weekStartMidnight = DateTime(weekStart.year, weekStart.month, weekStart.day);

      final logsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('meal_logs')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStartMidnight))
          .get();

      // Get unique days logged
      Set<String> uniqueDays = {};
      for (var doc in logsSnapshot.docs) {
        final timestamp = (doc.data()['timestamp'] as Timestamp).toDate();
        final dateKey = '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
        uniqueDays.add(dateKey);
      }

      return {
        'daysLogged': uniqueDays.length,
        'totalDays': 7,
      };
    } catch (e) {
      print('Error getting weekly goal: $e');
      return {'daysLogged': 0, 'totalDays': 7};
    }
  }

  // 🍳 Get user's recipe count
  Future<int> getUserRecipeCount() async {
    try {
      final userId = currentUserId;
      if (userId == null) return 0;

      final recipesSnapshot = await _firestore
          .collection('recipes')
          .where('authorId', isEqualTo: userId)
          .get();

      return recipesSnapshot.docs.length;
    } catch (e) {
      print('Error getting recipe count: $e');
      return 0;
    }
  }

  // ❤️ Get total likes on user's recipes
  Future<int> getTotalLikes() async {
    try {
      final userId = currentUserId;
      if (userId == null) return 0;

      final recipesSnapshot = await _firestore
          .collection('recipes')
          .where('authorId', isEqualTo: userId)
          .get();

      int totalLikes = 0;
      for (var doc in recipesSnapshot.docs) {
        final data = doc.data();
        final likes = data['likes'] ?? 0;
        totalLikes += (likes is int ? likes : 0);
      }

      return totalLikes;
    } catch (e) {
      print('Error getting total likes: $e');
      return 0;
    }
  }

  // ✅ NEW: Get unique days logged
  Future<int> _getUniqueDaysLogged() async {
    try {
      final userId = currentUserId;
      if (userId == null) return 0;

      final logsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('meal_logs')
          .get();

      Set<String> uniqueDays = {};
      for (var doc in logsSnapshot.docs) {
        final timestamp = (doc.data()['timestamp'] as Timestamp).toDate();
        final dateKey = _formatDate(timestamp);
        uniqueDays.add(dateKey);
      }

      return uniqueDays.length;
    } catch (e) {
      print('Error getting unique days: $e');
      return 0;
    }
  }

  // ✅ NEW: Check if user logged all meals in a day
  Future<bool> _hasLoggedAllMealsToday() async {
    try {
      final userId = currentUserId;
      if (userId == null) return false;

      final today = _formatDate(DateTime.now());

      final logsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('meal_logs')
          .where('date', isEqualTo: today)
          .get();

      Set<String> categories = {};
      for (var doc in logsSnapshot.docs) {
        final category = doc.data()['category'];
        if (category != null) categories.add(category.toString().toLowerCase());
      }

      return categories.contains('breakfast') && 
             categories.contains('lunch') && 
             categories.contains('dinner');
    } catch (e) {
      print('Error checking all meals: $e');
      return false;
    }
  }

  // 🎖️ Get achievements (with subcollection support)
  Future<List<Map<String, dynamic>>> getAchievements() async {
    try {
      final userId = currentUserId;
      if (userId == null) return [];

      // Get user stats
      final results = await Future.wait([
        getCurrentStreak(),
        getUserRecipeCount(),
        getTotalLikes(),
        _firestore.collection('users').doc(userId).collection('meal_logs').get(),
        _getUniqueDaysLogged(),
        _hasLoggedAllMealsToday(),
      ]);

      final streak = results[0] as int;
      final recipeCount = results[1] as int;
      final totalLikes = results[2] as int;
      final logsSnapshot = results[3] as QuerySnapshot;
      final uniqueDays = results[4] as int;
      final hasAllMeals = results[5] as bool;

      final totalLogs = logsSnapshot.docs.length;

      // Define all achievements
      final allAchievements = [
        // 🥾 Getting Started
        {
          'id': 'first_step',
          'title': 'First Step',
          'description': 'Logged your first meal',
          'icon': '🥾',
          'category': 'getting_started',
          'requirement': totalLogs >= 1,
        },
        {
          'id': 'five_meals',
          'title': '5 Meals',
          'description': 'Logged 5 meals',
          'icon': '🍽️',
          'category': 'milestones',
          'requirement': totalLogs >= 5,
        },
        {
          'id': 'ten_meals',
          'title': '10 Meals',
          'description': 'Logged 10 meals',
          'icon': '🎯',
          'category': 'milestones',
          'requirement': totalLogs >= 10,
        },
        {
          'id': 'fifty_meals',
          'title': '50 Meals',
          'description': 'Logged 50 meals',
          'icon': '🌟',
          'category': 'milestones',
          'requirement': totalLogs >= 50,
        },
        {
          'id': 'century_club',
          'title': 'Century Club',
          'description': 'Logged 100 meals',
          'icon': '💯',
          'category': 'milestones',
          'requirement': totalLogs >= 100,
        },

        // 🔥 Streaks
        {
          'id': 'three_day_streak',
          'title': '3-Day Streak',
          'description': 'Logged food for 3 days in a row',
          'icon': '🔥',
          'category': 'streaks',
          'requirement': streak >= 3,
        },
        {
          'id': 'weekly_champion',
          'title': 'Weekly Champion',
          'description': 'Maintained a 7-day streak',
          'icon': '🏆',
          'category': 'streaks',
          'requirement': streak >= 7,
        },
        {
          'id': 'two_week_warrior',
          'title': '14-Day Warrior',
          'description': 'Logged for 14 consecutive days',
          'icon': '⚔️',
          'category': 'streaks',
          'requirement': streak >= 14,
        },
        {
          'id': 'thirty_day_warrior',
          'title': '30-Day Warrior',
          'description': 'Logged for 30 consecutive days',
          'icon': '👑',
          'category': 'streaks',
          'requirement': streak >= 30,
        },

        // 📔 Consistency
        {
          'id': 'food_diary',
          'title': 'Food Diary',
          'description': 'Logged meals for 30 unique days',
          'icon': '📔',
          'category': 'consistency',
          'requirement': uniqueDays >= 30,
        },
        {
          'id': 'dedicated_tracker',
          'title': 'Dedicated Tracker',
          'description': 'Logged meals for 60 unique days',
          'icon': '📚',
          'category': 'consistency',
          'requirement': uniqueDays >= 60,
        },
        {
          'id': 'balanced_diet',
          'title': 'Balanced Day',
          'description': 'Log all 3 meals in one day',
          'icon': '⚖️',
          'category': 'consistency',
          'requirement': hasAllMeals,
        },

        // 👨‍🍳 Recipes
        {
          'id': 'beginner_chef',
          'title': 'Beginner Chef',
          'description': 'Created your first recipe',
          'icon': '👨‍🍳',
          'category': 'recipes',
          'requirement': recipeCount >= 1,
        },
        {
          'id': 'recipe_creator',
          'title': 'Recipe Creator',
          'description': 'Created 5 recipes',
          'icon': '📖',
          'category': 'recipes',
          'requirement': recipeCount >= 5,
        },
        {
          'id': 'recipe_master',
          'title': 'Recipe Master',
          'description': 'Created 10 recipes',
          'icon': '📚',
          'category': 'recipes',
          'requirement': recipeCount >= 10,
        },

        // ⭐ Social
        {
          'id': 'first_fan',
          'title': 'First Fan',
          'description': 'Got your first like',
          'icon': '❤️',
          'category': 'social',
          'requirement': totalLikes >= 1,
        },
        {
          'id': 'popular_creator',
          'title': 'Popular Creator',
          'description': 'Got 50 total likes',
          'icon': '⭐',
          'category': 'social',
          'requirement': totalLikes >= 50,
        },
        {
          'id': 'super_star',
          'title': 'Super Star',
          'description': 'Got 100 total likes',
          'icon': '🌟',
          'category': 'social',
          'requirement': totalLikes >= 100,
        },
      ];

      // Get unlocked achievements from subcollection
      final achievementsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .get();

      Map<String, Map<String, dynamic>> unlockedAchievements = {};
      for (var doc in achievementsSnapshot.docs) {
        unlockedAchievements[doc.id] = doc.data();
      }

      // Process achievements
      List<Map<String, dynamic>> earnedAchievements = [];

      for (var achievement in allAchievements) {
        final id = achievement['id'] as String;
        final isEarned = achievement['requirement'] as bool;

        if (isEarned) {
          final unlockedData = unlockedAchievements[id];
          final isNew = unlockedData == null;

          // If new achievement, unlock it
          if (isNew) {
            await _unlockAchievement(id);
          }

          earnedAchievements.add({
            'id': id,
            'title': achievement['title'],
            'description': achievement['description'],
            'icon': achievement['icon'],
            'category': achievement['category'],
            'isNew': isNew,
            'unlockedAt': unlockedData?['unlockedAt'],
          });
        }
      }

      // Sort: new first, then by unlock date
      earnedAchievements.sort((a, b) {
        if (a['isNew'] != b['isNew']) {
          return (b['isNew'] as bool) ? 1 : -1;
        }
        
        final timestampA = a['unlockedAt'] as Timestamp?;
        final timestampB = b['unlockedAt'] as Timestamp?;
        
        if (timestampA == null || timestampB == null) return 0;
        return timestampB.compareTo(timestampA);
      });

      return earnedAchievements;
    } catch (e) {
      print('Error getting achievements: $e');
      return [];
    }
  }

  // ✅ NEW: Unlock achievement (save to subcollection)
  Future<void> _unlockAchievement(String achievementId) async {
    try {
      final userId = currentUserId;
      if (userId == null) return;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .doc(achievementId)
          .set({
        'unlockedAt': FieldValue.serverTimestamp(),
        'viewedAt': null,
      });

      print('✅ Unlocked achievement: $achievementId');
    } catch (e) {
      print('Error unlocking achievement: $e');
    }
  }

  // 🔄 Mark achievements as viewed
  Future<void> markAchievementsAsViewed(List<String> achievementIds) async {
    try {
      final userId = currentUserId;
      if (userId == null) return;

      if (achievementIds.isEmpty) return;

      final batch = _firestore.batch();

      for (var id in achievementIds) {
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('achievements')
            .doc(id);

        batch.update(docRef, {
          'viewedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      print('✅ Marked ${achievementIds.length} achievements as viewed');
    } catch (e) {
      print('Error marking achievements as viewed: $e');
    }
  }

  // 🔔 Check if user has new achievements
  Future<bool> hasNewAchievements() async {
    try {
      final achievements = await getAchievements();
      return achievements.any((achievement) => achievement['isNew'] == true);
    } catch (e) {
      print('Error checking new achievements: $e');
      return false;
    }
  }

  // SOON: Method to check if user has new achievements (for notification badge)
  /*Future<bool> hasNewAchievements() async {
    try {
      final achievements = await getAchievements();
      return achievements.any((achievement) => achievement['isNew'] == true);
    } catch (e) {
      print('Error checking new achievements: $e');
      return false;
    }
  }*/

  // 🖼️ Get user avatar (placeholder - will be implemented later in settings)
  Future<String?> getUserAvatar() async {
    try {
      final userId = currentUserId;
      if (userId == null) return null;

      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['avatar'];
      }
      return null;
    } catch (e) {
      print('Error getting avatar: $e');
      return null;
    }
  }

  // 🔄 Get all profile data at once (optimization - single function call)
  Future<Map<String, dynamic>> getProfileData() async {
    try {
      // FIXED: Now properly awaiting all async operations
      final email = getUserEmail();
      final name = await getUserName();
      final streak = await getCurrentStreak();
      final avgCalories = await getAvgDailyCalories();
      final weeklyGoal = await getWeeklyGoalProgress();
      final recipeCount = await getUserRecipeCount();
      final totalLikes = await getTotalLikes();
      final avatar = await getUserAvatar();

      return {
        'email': email,
        'name': name,
        'streak': streak,
        'avgCalories': avgCalories,
        'weeklyGoalDays': weeklyGoal['daysLogged'],
        'weeklyGoalTotal': weeklyGoal['totalDays'],
        'recipeCount': recipeCount,
        'totalLikes': totalLikes,
        'avatar': avatar, // Can be null
      };
    } catch (e) {
      print('Error getting profile data: $e');
      // Return default values on error
      return {
        'email': 'No email',
        'name': 'User',
        'streak': 0,
        'avgCalories': 0,
        'weeklyGoalDays': 0,
        'weeklyGoalTotal': 7,
        'recipeCount': 0,
        'totalLikes': 0,
        'avatar': null,
      };
    }
  }
}