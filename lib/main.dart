import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kharcha/bloc/sms/sms_bloc.dart';
import 'package:kharcha/firebase_options.dart';
import 'package:kharcha/screens/auth/bloc/auth_bloc.dart';
import 'package:kharcha/screens/splash/splash_screen.dart';
import 'package:kharcha/utils/background/flutter_startup_reader.dart';
import 'package:kharcha/utils/constants/app_colors.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Process pending transactions from background SMS receiver
  // This also handles note updates from notification actions
  // This runs before the UI is rendered to ensure transactions are available
  // Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7
  try {
    print('=== MAIN: Processing pending transactions and note updates ===');
    final FlutterStartupReader startupReader = FlutterStartupReader();
    await startupReader.processPendingTransactions();
    print('=== MAIN: Processing complete ===');
  } catch (e, stackTrace) {
    // Don't block app startup if processing fails
    print('=== MAIN: Failed to process pending transactions: $e ===');
    print('=== MAIN: Stack trace: $stackTrace ===');
  }

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiBlocProvider(
          providers: <BlocProvider<dynamic>>[
            BlocProvider<SmsBloc>(create: (_) => SmsBloc()),
            BlocProvider<AuthBloc>(create: (_) => AuthBloc()),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              fontFamily: 'FunnelDisplay',
              textSelectionTheme: TextSelectionThemeData(
                cursorColor: AppColors.primary,
                selectionColor: AppColors.primary.withValues(alpha: 0.25),
                selectionHandleColor: AppColors.primary,
              ),
            ),
            home: SplashScreen(),
          ),
        );
      },
    );
  }
}
