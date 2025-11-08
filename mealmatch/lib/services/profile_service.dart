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

      /* Get start of current week (Monday)
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

  // 🎖️ Get achievements based on user progress
Future<List<Map<String, dynamic>>> getAchievements() async {
  try {
    final userId = currentUserId;
    if (userId == null) return [];

    // Get user data
    final streak = await getCurrentStreak();
    final recipeCount = await getUserRecipeCount();
    final totalLikes = await getTotalLikes();
    
    // Get meal logs count
    final logsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('meal_logs')
        .get();
    final totalLogs = logsSnapshot.docs.length;

    // Check viewed achievements from Firestore
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final viewedAchievements = (userDoc.data()?['viewedAchievements'] as List<dynamic>?)?.cast<String>() ?? [];

    List<Map<String, dynamic>> achievements = [];
      // Define all achievements
      if (totalLogs >= 1) {
        achievements.add({
          'id': 'first_step',
          'title': 'First Step',
          'description': 'Logged your first meal',
          'icon': '🥾',
          'isNew': !viewedAchievements.contains('first_step'),
        });
      }

      if (recipeCount >= 1) {
        achievements.add({
          'id': 'beginner_chef',
          'title': 'Beginner Chef',
          'description': 'Created your first recipe',
          'icon': '👨‍🍳',
          'isNew': !viewedAchievements.contains('beginner_chef'),
        });
      }

      if (streak >= 3) {
        achievements.add({
          'id': 'three_day_streak',
          'title': '3-Day Streak',
          'description': 'Logged food for 3 days in a row',
          'icon': '🔥',
          'isNew': !viewedAchievements.contains('three_day_streak'),
        });
      }

      if (streak >= 7) {
        achievements.add({
          'id': 'weekly_champion',
          'title': 'Weekly Champion',
          'description': 'Maintained a 7-day streak',
          'icon': '🏆',
          'isNew': !viewedAchievements.contains('weekly_champion'),
        });
      }

      if (streak >= 30) {
        achievements.add({
          'id': 'thirty_day_warrior',
          'title': '30-Day Warrior',
          'description': 'Logged for 30 consecutive days',
          'icon': '⚔️',
          'isNew': !viewedAchievements.contains('thirty_day_warrior'),
        });
      }

      if (recipeCount >= 5) {
        achievements.add({
          'id': 'recipe_creator',
          'title': 'Recipe Creator',
          'description': 'Created 5 recipes',
          'icon': '📖',
          'isNew': !viewedAchievements.contains('recipe_creator'),
        });
      }

      if (totalLikes >= 50) {
        achievements.add({
          'id': 'popular_creator',
          'title': 'Popular Creator',
          'description': 'Got 50 total likes',
          'icon': '⭐',
          'isNew': !viewedAchievements.contains('popular_creator'),
        });
      }

      return achievements;
    } catch (e) {
      print('Error getting achievements: $e');
      return [];
    }
  }

  // 🔄 Mark achievements as viewed
  Future<void> markAchievementsAsViewed(List<String> achievementIds) async {
    try {
      final userId = currentUserId;
      if (userId == null) return;

      final userDoc = await _firestore.collection('users').doc(userId).get();
      final viewedAchievements = (userDoc.data()?['viewedAchievements'] as List<dynamic>?)?.cast<String>() ?? [];
      
      // Add new achievement IDs
      viewedAchievements.addAll(achievementIds);
      
      await _firestore.collection('users').doc(userId).update({
        'viewedAchievements': viewedAchievements.toSet().toList(), // Remove duplicates
      });
    } catch (e) {
      print('Error marking achievements as viewed: $e');
    }
  }

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