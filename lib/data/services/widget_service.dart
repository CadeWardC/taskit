import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class WidgetService {
  static const _channel = MethodChannel('com.taskit.widget');

  /// Update the widget configuration (user ID, display mode, list ID)
  static Future<void> updateWidgetConfig({
    String? userId,
    String? displayMode,
    int? listId,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    
    try {
      await _channel.invokeMethod('setWidgetConfig', {
        if (userId != null) 'userId': userId,
        if (displayMode != null) 'displayMode': displayMode,
        if (listId != null) 'listId': listId,
      });
    } catch (e) {
      // Widget may not be available (e.g., running on simulator without widget)
      print('Widget update failed: $e');
    }
  }

  /// Get current widget configuration
  static Future<Map<String, dynamic>?> getWidgetConfig() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return null;
    
    try {
      final result = await _channel.invokeMethod('getWidgetConfig');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return null;
    }
  }

  /// Convenience: sync user ID to widget when it changes
  static Future<void> syncUserId(String userId) async {
    await updateWidgetConfig(userId: userId);
  }

  /// Clear widget configuration (call on logout)
  static Future<void> clearWidgetConfig() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;

    try {
      await _channel.invokeMethod('clearWidgetConfig');
    } catch (e) {
      print('Widget clear failed: $e');
    }
  }
}
