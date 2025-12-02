// 📁 lib/helpers/notification_trigger_helper.dart

import '../services/notification_service.dart';

class NotificationTriggerHelper {
  static final NotificationService _notificationService = NotificationService();

  // ✅ [FIXED] CALL THIS AFTER USER LOGS A MEAL
  // NOW: Checks both streak AND calorie progress after each meal
  static Future<void> afterMealLogged() async {
    // 🆕 ADDED: Check calorie goal status immediately after logging
    // This allows users to see if they've reached/exceeded their goal in real-time
    await _notificationService.checkDailyCalorieGoalAndNotify();
    
    // Check if user reached a streak milestone (7, 14, 21, 30, etc.)
    await _notificationService.checkStreakAndNotify();
    
    print('✅ Calorie goal and streak checks triggered after meal logged');
  }

  // ✅ CALL THIS AT END OF DAY (9 PM - 11 PM)
  // Checks if user met their calorie goal based on their weight goals
  static Future<void> endOfDayCheck() async {
    await _notificationService.checkDailyCalorieGoalAndNotify();
    
    print('✅ End-of-day calorie goal notification check completed');
  }

  // ✅ CALL THIS AROUND 2 PM
  // Reminds users to log meals if they haven't yet
  static Future<void> afternoonMealReminder() async {
    await _notificationService.checkMealLoggingAndNotify();
    
    print('✅ Afternoon meal logging reminder check completed');
  }

  // ✅ [NEW] CALL THIS WHEN USER OPENS THE APP
  // Automatically triggers time-based notifications
  static Future<void> onAppOpen() async {
    final now = DateTime.now();
    
    // Check if it's afternoon (2 PM - 8 PM) - send meal logging reminder if needed
    if (now.hour >= 14 && now.hour < 20) {
      await afternoonMealReminder();
    }
    
    // Check if it's evening (8 PM - 11:59 PM) - check calorie goals
    if (now.hour >= 20) {
      await endOfDayCheck();
    }
    
    print('✅ App open notification checks completed at ${now.hour}:${now.minute}');
  }
}