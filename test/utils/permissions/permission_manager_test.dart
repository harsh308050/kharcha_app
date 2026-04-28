import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kharcha/utils/permissions/permission_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PermissionManager permissionManager;

  setUp(() {
    permissionManager = PermissionManager();
    
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'checkPermissionStatus') {
          return 1; // 1 = granted in permission_handler
        } else if (methodCall.method == 'requestPermissions') {
          final List<dynamic> args = methodCall.arguments as List<dynamic>;
          final Map<int, int> result = {};
          for (var arg in args) {
            result[arg as int] = 1;
          }
          return result;
        } else if (methodCall.method == 'openAppSettings') {
          return true;
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      null,
    );
  });

  test('requestSmsPermission returns true when granted', () async {
    final result = await permissionManager.requestSmsPermission();
    expect(result, isTrue);
  });

  test('requestNotificationPermission returns true when granted', () async {
    final result = await permissionManager.requestNotificationPermission();
    expect(result, isTrue);
  });

  test('requestBatteryOptimizationWhitelist returns true when granted', () async {
    final result = await permissionManager.requestBatteryOptimizationWhitelist();
    expect(result, isTrue);
  });

  test('hasSmsPermission returns true', () async {
    final result = await permissionManager.hasSmsPermission();
    expect(result, isTrue);
  });

  test('hasNotificationPermission returns true', () async {
    final result = await permissionManager.hasNotificationPermission();
    expect(result, isTrue);
  });

  test('isBatteryOptimizationDisabled returns true', () async {
    final result = await permissionManager.isBatteryOptimizationDisabled();
    expect(result, isTrue);
  });

  test('openAppSettings executes without error', () async {
    await expectLater(permissionManager.openAppSettings(), completes);
  });

  test('openBatteryOptimizationSettings executes without error', () async {
    await expectLater(permissionManager.openBatteryOptimizationSettings(), completes);
  });
}
