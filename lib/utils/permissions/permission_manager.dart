import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:permission_handler/permission_handler.dart';

/// Manages permissions required for background SMS transaction tracking.
///
/// Requirements: 8.1, 8.3, 9.1, 9.3, 10.1, 10.4, 10.5
class PermissionManager {
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

  /// Request battery optimization whitelist
  Future<bool> requestBatteryOptimizationWhitelist() async {
    final PermissionStatus status = await Permission.ignoreBatteryOptimizations.request();
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

  /// Check if battery optimization is disabled (whitelisted)
  Future<bool> isBatteryOptimizationDisabled() async {
    return await Permission.ignoreBatteryOptimizations.isGranted;
  }

  /// Open application settings
  Future<void> openAppSettings() async {
    await ph.openAppSettings();
  }

  /// Open battery optimization settings
  Future<void> openBatteryOptimizationSettings() async {
    await ph.openAppSettings();
  }
}
