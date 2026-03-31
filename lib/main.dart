import 'package:flutter/material.dart';
import 'package:kharcha/screens/splash/splash_screen.dart';
import 'package:kharcha/utils/constants/app_colors.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // Adjust as needed based on Figma
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
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
        );
      },
    );
  }
}
