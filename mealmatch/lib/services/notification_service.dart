// 📁 lib/services/notification_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ✅ Generate and save a notification to Firestore
  Future<void> _saveNotification({
    required String title,
    required String description,
    required String details,
    required String icon,
    required String iconColor,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .add({
        'title': title,
        'description': description,
        'details': details,
        'icon': icon,
        'iconColor': iconColor,
        'isUnread': true,
        'timestamp': Timestamp.fromDate(now), 
        'createdAt': now.toIso8601String(),
      });

      print('✅ Notification saved: $title - $description');
    } catch (e) {
      print('❌ Error saving notification: $e');
    }
  }

  // 🔥 [FIXED] CHECK CALORIE GOAL STATUS AND GENERATE NOTIFICATIONS
  // This checks calorie status and sends appropriate notifications based on user goals
  // NOW: Prevents duplicate notifications by checking SPECIFIC description (not just title)
  Future<void> checkDailyCalorieGoalAndNotify() async {
    print('🔍 START: checkDailyCalorieGoalAndNotify()');
    
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No user logged in');
        return;
      }
      print('✅ User logged in: ${user.uid}');

      // Get user data (goals, calorie goal)
      print('🔍 Fetching user document...');
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        print('❌ User document does not exist');
        return;
      }
      print('✅ User document found');

      final userData = userDoc.data()!;
      print('📊 All user data fields: ${userData.keys.toList()}');
      
      // 🆕 FIXED: Safely get goals array
      List<String> goals = [];
      try {
        if (userData.containsKey('goals') && userData['goals'] != null) {
          goals = List<String>.from(userData['goals']);
          print('✅ Goals found: $goals');
        } else {
          print('⚠️ No goals field found in user document');
        }
      } catch (e) {
        print('❌ Error parsing goals: $e');
        print('   Goals field type: ${userData['goals'].runtimeType}');
        print('   Goals field value: ${userData['goals']}');
      }
      
      // 🆕 FIXED: Get daily calorie goal (your field name is dailyCalorieGoal)
      int calorieGoal = 2000; // default fallback
      if (userData.containsKey('dailyCalorieGoal') && userData['dailyCalorieGoal'] != null) {
        calorieGoal = (userData['dailyCalorieGoal'] as num).toInt();
        print('✅ Found dailyCalorieGoal: $calorieGoal');
      } else if (userData.containsKey('calorieGoal') && userData['calorieGoal'] != null) {
        calorieGoal = (userData['calorieGoal'] as num).toInt();
        print('✅ Found calorieGoal: $calorieGoal');
      } else if (userData.containsKey('goalCalories') && userData['goalCalories'] != null) {
        calorieGoal = (userData['goalCalories'] as num).toInt();
        print('✅ Found goalCalories: $calorieGoal');
      } else {
        print('⚠️ No calorie goal field found, using default: $calorieGoal');
      }

      print('📊 Final values - Calorie Goal: $calorieGoal, Goals: $goals');

      // Determine user's weight goal type
      bool wantsToGainWeight = goals.any(
        (g) =>
            g.toLowerCase().contains('gain') ||
            g.toLowerCase().contains('muscle'),
      );
      bool wantsToLoseWeight = goals.any(
        (g) =>
            g.toLowerCase().contains('lose') ||
            g.toLowerCase().contains('weight loss'),
      );
      bool wantsToMaintain = goals.any(
        (g) => g.toLowerCase().contains('maintain'),
      );

      print('📊 Wants to gain: $wantsToGainWeight, lose: $wantsToLoseWeight, maintain: $wantsToMaintain');

      // 🆕 FIXED: If user has no relevant goals, skip calorie notifications
      if (!wantsToGainWeight && !wantsToLoseWeight && !wantsToMaintain) {
        print('ℹ️ User has no weight-related goals, skipping calorie notification');
        return;
      }

      // Get today's total calories consumed
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final todayLogs = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('meal_logs')
          .where('date', isEqualTo: dateStr)
          .get();

      print('📊 Today\'s meal logs count: ${todayLogs.docs.length}');

      int totalCalories = 0;
      Map<String, int> categoryCalories = {
        'Breakfast': 0,
        'Lunch': 0,
        'Dinner': 0,
        'Snacks': 0,
      };

      for (var doc in todayLogs.docs) {
        final data = doc.data();
        final calories = (data['calories'] as num).toInt();
        final category = data['category'] as String? ?? 'Snacks';

        totalCalories += calories;
        if (categoryCalories.containsKey(category)) {
          categoryCalories[category] = categoryCalories[category]! + calories;
        }
      }

      final remaining = calorieGoal - totalCalories;

      print('📊 Total calories consumed: $totalCalories');
      print('📊 Remaining calories: $remaining');

      // 🎯 NOTIFICATION LOGIC BASED ON GOALS

      // ✅ Goal Met (within ±50 calories of target)
      if (remaining.abs() <= 50) {
        // 🆕 FIXED: Check for this SPECIFIC notification, not just any calorie notification
        final existingNotif = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .where('description', isEqualTo: 'You\'ve hit your daily calorie goal!')
            .where('createdAt', isGreaterThan: '${dateStr}T00:00:00')
            .limit(1)
            .get();
        
        if (existingNotif.docs.isNotEmpty) {
          print('ℹ️ Goal reached notification already sent today');
          return;
        }

        await _saveNotification(
          title: 'Calorie Tracker Update',
          description: 'You\'ve hit your daily calorie goal!',
          details:
              'Congratulations! You\'ve successfully reached your daily calorie goal of ${calorieGoal.toStringAsFixed(0)} calories.\n\n'
              'Today\'s breakdown:\n'
              '• Breakfast: ${categoryCalories['Breakfast']} cal\n'
              '• Lunch: ${categoryCalories['Lunch']} cal\n'
              '• Dinner: ${categoryCalories['Dinner']} cal\n'
              '• Snacks: ${categoryCalories['Snacks']} cal\n\n'
              'Keep up the great work maintaining your healthy eating habits!',
          icon: 'bolt_outlined',
          iconColor: '0xFF4DD0E1',
        );
        return; // Goal met, no need for further notifications
      }

      // 🟢 GAIN WEIGHT: Need to eat MORE
      if (wantsToGainWeight && remaining > 50) {
        if (remaining >= 400) {
          // 🆕 FIXED: Check for this specific notification type
          final existingNotif = await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('notifications')
              .where('description', isEqualTo: 'Your daily calorie goal is not yet met—check out recipes to fill the gap.')
              .where('createdAt', isGreaterThan: '${dateStr}T00:00:00')
              .limit(1)
              .get();
          
          if (existingNotif.docs.isEmpty) {
            // Far from goal
            await _saveNotification(
              title: 'Calorie Tracker Update',
              description:
                  'Your daily calorie goal is not yet met—check out recipes to fill the gap.',
              details:
                  'You still have ${remaining.toStringAsFixed(0)} calories left to reach your daily goal of ${calorieGoal.toStringAsFixed(0)} calories.\n\n'
                  'To gain weight effectively, try to meet your calorie target. '
                  'Why not try one of these high-calorie recipes:\n'
                  '• Protein Smoothie Bowl (450 cal)\n'
                  '• Peanut Butter Toast (380 cal)\n'
                  '• Greek Yogurt Parfait (320 cal)',
              icon: 'bolt_outlined',
              iconColor: '0xFFFF9800',
            );
          }
        } else if (remaining >= 200) {
          // 🆕 FIXED: Check for this specific notification type
          final existingNotif = await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('notifications')
              .where('description', isEqualTo: 'You\'re close to reaching your calorie target today.')
              .where('createdAt', isGreaterThan: '${dateStr}T00:00:00')
              .limit(1)
              .get();
          
          if (existingNotif.docs.isEmpty) {
            // Close to goal
            await _saveNotification(
              title: 'Calorie Tracker Update',
              description: 'You\'re close to reaching your calorie target today.',
              details:
                  'You\'re doing great! You\'ve consumed ${totalCalories.toStringAsFixed(0)} calories so far.\n\n'
                  'You have ${remaining.toStringAsFixed(0)} calories remaining to reach your daily goal of ${calorieGoal.toStringAsFixed(0)} calories. '
                  'Consider a light snack or small meal to meet your target for healthy weight gain.',
              icon: 'bolt_outlined',
              iconColor: '0xFF4DD0E1',
            );
          }
        } else {
          // 🆕 FIXED: Check for this specific notification type
          final existingNotif = await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('notifications')
              .where('description', isEqualTo: 'Still room in your calories—why not try a snack?')
              .where('createdAt', isGreaterThan: '${dateStr}T00:00:00')
              .limit(1)
              .get();
          
          if (existingNotif.docs.isEmpty) {
            // Very close (50-200 remaining)
            await _saveNotification(
              title: 'Calorie Tracker Update',
              description: 'Still room in your calories—why not try a snack?',
              details:
                  'You have ${remaining.toStringAsFixed(0)} calories remaining for today. Perfect opportunity to have a healthy snack!\n\n'
                  'Recommended snacks:\n'
                  '• Handful of nuts (150 cal)\n'
                  '• Banana with peanut butter (180 cal)\n'
                  '• Protein bar (200 cal)',
              icon: 'restaurant_outlined',
              iconColor: '0xFFFFB74D',
            );
          }
        }
      }

      // 🟠 MAINTAIN WEIGHT: Should stay near goal
      if (wantsToMaintain) {
        if (remaining > 200) {
          // 🆕 FIXED: Check for this specific notification type
          final existingNotif = await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('notifications')
              .where('description', isEqualTo: 'Reach your calorie goal to maintain your weight.')
              .where('createdAt', isGreaterThan: '${dateStr}T00:00:00')
              .limit(1)
              .get();
          
          if (existingNotif.docs.isEmpty) {
            // Under target
            await _saveNotification(
              title: 'Calorie Tracker Update',
              description: 'Reach your calorie goal to maintain your weight.',
              details:
                  'You\'ve consumed ${totalCalories.toStringAsFixed(0)} calories today.\n\n'
                  'You have ${remaining.toStringAsFixed(0)} calories remaining to reach your maintenance goal of ${calorieGoal.toStringAsFixed(0)} calories. '
                  'Try to meet your target to maintain your current weight.',
              icon: 'bolt_outlined',
              iconColor: '0xFF4DD0E1',
            );
          }
        } else if (remaining < -200) {
          // 🆕 FIXED: Check for this specific notification type
          final existingNotif = await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('notifications')
              .where('description', isEqualTo: 'You\'ve exceeded your maintenance calorie goal.')
              .where('createdAt', isGreaterThan: '${dateStr}T00:00:00')
              .limit(1)
              .get();
          
          if (existingNotif.docs.isEmpty) {
            // Over target (eating too much)
            await _saveNotification(
              title: 'Calorie Tracker Update',
              description: 'You\'ve exceeded your maintenance calorie goal.',
              details:
                  'You\'ve consumed ${totalCalories.toStringAsFixed(0)} calories today, which is ${remaining.abs().toStringAsFixed(0)} calories over your maintenance goal of ${calorieGoal.toStringAsFixed(0)} calories.\n\n'
                  'If maintaining weight is your goal, try to stay closer to your target tomorrow.',
              icon: 'warning_amber_rounded',
              iconColor: '0xFFFF9800',
            );
          }
        }
      }

      // 🔴 LOSE WEIGHT: Under goal is GOOD, over goal is BAD
      if (wantsToLoseWeight) {
        if (remaining < -200) {
          // 🆕 FIXED: Check for this specific notification type
          final existingNotif = await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('notifications')
              .where('description', isEqualTo: 'You\'ve gone over your calorie goal today.')
              .where('createdAt', isGreaterThan: '${dateStr}T00:00:00')
              .limit(1)
              .get();
          
          if (existingNotif.docs.isEmpty) {
            // Over target (ate too much - BAD for weight loss)
            await _saveNotification(
              title: 'Calorie Tracker Update',
              description: 'You\'ve gone over your calorie goal today.',
              details:
                  'You\'ve consumed ${totalCalories.toStringAsFixed(0)} calories today, which is ${remaining.abs().toStringAsFixed(0)} calories over your goal of ${calorieGoal.toStringAsFixed(0)} calories.\n\n'
                  'To lose weight effectively, try to stay within or below your calorie target. '
                  'Tomorrow is a new day—you\'ve got this! 💪',
              icon: 'warning_amber_rounded',
              iconColor: '0xFFFF5252',
            );
          }
        }
        // 🆕 FIXED: If under goal (remaining > 0), it's GOOD for weight loss—no notification needed
      }
    } catch (e) {
      print('❌ checkDailyCalorieGoalAndNotify error: $e');
    }
  }

  // 🔔 [FIXED] CHECK IF USER HASN'T LOGGED ANY MEALS TODAY (reminder)
  // This should be called around 2 PM
  // NOW: Prevents duplicate notifications by checking if one was already sent today
  Future<void> checkMealLoggingAndNotify() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // 🆕 PREVENT DUPLICATE NOTIFICATIONS - Check if already sent today
      final existingNotif = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('description', isEqualTo: 'You haven\'t logged any meals yet.')
          .where('createdAt', isGreaterThan: '${dateStr}T00:00:00')
          .limit(1)
          .get();
      
      if (existingNotif.docs.isNotEmpty) {
        print('ℹ️ Meal reminder already sent today, skipping');
        return;
      }

      // Get today's logs
      final todayLogs = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('meal_logs')
          .where('date', isEqualTo: dateStr)
          .limit(1)
          .get();

      // If no logs yet, send reminder
      if (todayLogs.docs.isEmpty) {
        final hour = now.hour;
        String timeMessage = 'It\'s already ${hour > 12 ? hour - 12 : hour}:00 ${hour >= 12 ? 'PM' : 'AM'}';

        await _saveNotification(
          title: 'Reminders',
          description: 'You haven\'t logged any meals yet.',
          details:
              '$timeMessage and you haven\'t logged any meals today.\n\n'
              'Remember, consistent tracking is key to reaching your health goals. '
              'Take a moment to log what you\'ve eaten so far.',
          icon: 'lightbulb_outline',
          iconColor: '0xFFFFE082',
        );
      } else {
        print('ℹ️ User has already logged meals today, no reminder needed');
      }
    } catch (e) {
      print('❌ checkMealLoggingAndNotify error: $e');
    }
  }

  // 🔥 [FIXED] CHECK MEAL LOGGING STREAK AND NOTIFY
  // NOW: Only notifies on significant milestones (7, 14, 21, 30, 60, 90, 180, 365 days)
  // REMOVED: Spam notifications on every meal log
  Future<void> checkStreakAndNotify() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Calculate current streak
      int streak = await _calculateStreak();

      // 🆕 FIXED: Only notify on specific milestones to avoid spam
      final milestones = [7, 14, 21, 30, 60, 90, 180, 365];
      
      if (milestones.contains(streak)) {
        // 🆕 PREVENT DUPLICATE NOTIFICATIONS - Check if milestone already celebrated
        final now = DateTime.now();
        final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        
        final existingNotif = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .where('title', isEqualTo: 'Streak Update')
            .where('description', isEqualTo: 'New streak milestone unlocked — keep it up!')
            .where('createdAt', isGreaterThan: '${dateStr}T00:00:00')
            .limit(1)
            .get();
        
        if (existingNotif.docs.isNotEmpty) {
          print('ℹ️ Streak milestone notification already sent today, skipping');
          return;
        }

        // Milestone achievement
        await _saveNotification(
          title: 'Streak Update',
          description: 'New streak milestone unlocked — keep it up!',
          details:
              '🎉 MILESTONE ACHIEVED! 🎉\n\n'
              'You\'ve maintained a $streak-day meal logging streak! '
              '${streak >= 30 ? 'You\'re unstoppable! 💪' : 'Keep up the amazing work! 🔥'}',
          icon: 'emoji_events_outlined',
          iconColor: '0xFFFFC107',
        );
      }

      // 🆕 IMPROVED: Check if user is at risk of breaking streak (after 8 PM, no logs today)
      final now = DateTime.now();
      if (streak > 0 && now.hour >= 20) {
        final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

        final todayLogs = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('meal_logs')
            .where('date', isEqualTo: dateStr)
            .limit(1)
            .get();

        if (todayLogs.docs.isEmpty) {
          // 🆕 PREVENT DUPLICATE NOTIFICATIONS
          final existingWarning = await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('notifications')
              .where('description', isEqualTo: 'Keep your streak! Log a meal to continue your progress.')
              .where('createdAt', isGreaterThan: '${dateStr}T00:00:00')
              .limit(1)
              .get();
          
          if (existingWarning.docs.isEmpty) {
            await _saveNotification(
              title: 'Reminders',
              description: 'Keep your streak! Log a meal to continue your progress.',
              details:
                  'You\'re on a $streak-day meal logging streak! 🔥\n\n'
                  'Don\'t break your amazing streak now. Log at least one meal today to keep your streak alive.',
              icon: 'access_alarm',
              iconColor: '0xFF4DB6AC',
            );
          }
        }
      }
    } catch (e) {
      print('❌ checkStreakAndNotify error: $e');
    }
  }

  // 📊 Calculate user's current meal logging streak
  Future<int> _calculateStreak() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      int streak = 0;
      DateTime currentDate = DateTime.now();

      // Check backwards day by day
      for (int i = 0; i < 365; i++) {
        final dateStr =
            '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}';

        final logs = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('meal_logs')
            .where('date', isEqualTo: dateStr)
            .limit(1)
            .get();

        if (logs.docs.isEmpty) {
          break; // Streak broken
        }

        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      }

      return streak;
    } catch (e) {
      print('❌ _calculateStreak error: $e');
      return 0;
    }
  }

  // 📖 GET ALL NOTIFICATIONS FOR CURRENT USER
  Stream<List<Map<String, dynamic>>> getNotifications() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // ✅ MARK NOTIFICATION AS READ
  Future<void> markAsRead(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'isUnread': false});
    } catch (e) {
      print('❌ markAsRead error: $e');
    }
  }

  // ✅ MARK ALL NOTIFICATIONS AS READ
  Future<void> markAllAsRead() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('isUnread', isEqualTo: true)
          .get();

      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isUnread': false});
      }

      await batch.commit();
    } catch (e) {
      print('❌ markAllAsRead error: $e');
    }
  }

  // 🗑️ DELETE A NOTIFICATION
  Future<void> deleteNotification(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      print('❌ deleteNotification error: $e');
    }
  }

  // 🗑️ CLEAR ALL NOTIFICATIONS
  Future<void> clearAllNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .get();

      for (var doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('❌ clearAllNotifications error: $e');
    }
  }
}