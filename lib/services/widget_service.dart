import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WidgetService {
  static const String appGroupId = 'group.com.kidastudios.ideaMessengerAdminPortal';
  static const String iOSWidgetName = 'IdeaDeDashboardWidget';

  static Future<void> updateWidgetData(Map<String, int> stats) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get previous stats for trend comparison
    final prevUsers = prefs.getInt('last_users_count') ?? stats['totalUsers'] ?? 0;
    final prevChats = prefs.getInt('last_chats_count') ?? stats['totalChats'] ?? 0;
    final prevMsgs = prefs.getInt('last_msgs_count') ?? stats['totalMessages'] ?? 0;

    // Calculate trends (-1: decrease, 0: same, 1: increase)
    final usersTrend = _calculateTrend(stats['totalUsers'] ?? 0, prevUsers);
    final chatsTrend = _calculateTrend(stats['totalChats'] ?? 0, prevChats);
    final msgsTrend = _calculateTrend(stats['totalMessages'] ?? 0, prevMsgs);

    // Save current as previous for next comparison
    await prefs.setInt('last_users_count', stats['totalUsers'] ?? 0);
    await prefs.setInt('last_chats_count', stats['totalChats'] ?? 0);
    await prefs.setInt('last_msgs_count', stats['totalMessages'] ?? 0);

    // Push to HomeWidget UserDefaults (via App Group)
    await HomeWidget.setAppGroupId(appGroupId);
    await HomeWidget.saveWidgetData('users_count', stats['totalUsers'] ?? 0);
    await HomeWidget.saveWidgetData('users_trend', usersTrend);
    await HomeWidget.saveWidgetData('chats_count', stats['totalChats'] ?? 0);
    await HomeWidget.saveWidgetData('chats_trend', chatsTrend);
    await HomeWidget.saveWidgetData('msgs_count', stats['totalMessages'] ?? 0);
    await HomeWidget.saveWidgetData('msgs_trend', msgsTrend);

    // Trigger iOS to reload widget timeline
    await HomeWidget.updateWidget(
      iOSName: iOSWidgetName,
    );
  }

  static int _calculateTrend(int current, int previous) {
    if (current > previous) return 1;
    if (current < previous) return -1;
    return 0;
  }
}
