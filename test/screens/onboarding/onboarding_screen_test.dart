import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kharcha/screens/onboarding/onboarding_screen.dart';
import 'package:kharcha/utils/constants/app_strings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'checkPermissionStatus') {
          return 1;
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

  Widget createWidgetUnderTest() {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => const MaterialApp(
        home: OnboardingScreen(),
      ),
    );
  }

  testWidgets('Onboarding flow navigates through all pages including permissions', (WidgetTester tester) async {
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exception is FlutterError &&
          details.exception.toString().contains('RenderFlex overflowed')) {
        return;
      }
      FlutterError.presentError(details);
    };

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Page 1
    expect(find.byType(RichText), findsWidgets);
    await tester.tap(find.text(AppStrings.next));
    await tester.pumpAndSettle();

    // Page 2
    expect(find.text(AppStrings.onBoardingTitle2), findsOneWidget);
    await tester.tap(find.text(AppStrings.next));
    await tester.pumpAndSettle();

    // Page 3
    expect(find.text(AppStrings.onBoardingTitle3), findsOneWidget);
    await tester.tap(find.text(AppStrings.next));
    await tester.pumpAndSettle();

    // Page 4: SMS Permission
    expect(find.text('SMS Permission Required'), findsOneWidget);
    await tester.tap(find.text('Grant SMS Permission'));
    await tester.pumpAndSettle();

    // Page 5: Notification Permission
    expect(find.text('Never Miss a Transaction'), findsOneWidget);
    await tester.tap(find.text('Grant Notification Permission'));
    await tester.pumpAndSettle();

    // Page 6: Battery Optimization
    expect(find.text('Keep Kharcha Awake'), findsOneWidget);
  });
}
