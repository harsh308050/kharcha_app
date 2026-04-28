import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages permissions required for background SMS transaction tracking.
///
/// Requirements: 8.1, 8.3, 9.1, 9.3
class PermissionManager {
  static const String _notificationsEnabledKey = 'push_notifications_enabled';

  /// Request SMS read permission
  Future<bool> requestSmsPermission() async {
    final PermissionStatus status = await Permission.sms.request();
    return status.isGranted;
  }

  /// Request notification permission (Android 13+)
  Future<bool> requestNotificationPermission() async {
    final PermissionStatus status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Check if SMS permission is granted
  Future<bool> hasSmsPermission() async {
    return await Permission.sms.isGranted;
  }

  /// Check if notification permission is granted
  Future<bool> hasNotificationPermission() async {
    return await Permission.notification.isGranted;
  }

  /// Get the user's push notification preference (persisted in SharedPreferences).
  ///
  /// Returns `true` by default if the key has never been set.
  Future<bool> isNotificationsEnabled() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  /// Persist the user's push notification preference.
  Future<void> setNotificationsEnabled(bool enabled) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
  }

  /// Open application settings
  Future<void> openAppSettings() async {
    await ph.openAppSettings();
  }
}
