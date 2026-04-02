import "package:flutter_screenutil/flutter_screenutil.dart";
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kharcha/components/common_button.dart';
import 'package:kharcha/components/common_text.dart';
import 'package:kharcha/screens/auth/bloc/auth_bloc.dart';
import 'package:kharcha/screens/auth/bloc/auth_event.dart';
import 'package:kharcha/screens/auth/bloc/auth_state.dart';
import 'package:kharcha/screens/auth/signin_screen.dart';
import 'package:kharcha/screens/permisson/permission_screen.dart';
import 'package:kharcha/utils/constants/app_colors.dart';
import 'package:kharcha/utils/constants/app_icons.dart';
import 'package:kharcha/utils/constants/app_image.dart';
import 'package:kharcha/utils/constants/app_strings.dart';
import 'package:kharcha/utils/my_cm.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static const double _infoCardHeight = 178;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (BuildContext context, AuthState state) {
        if (!(ModalRoute.of(context)?.isCurrent ?? false)) {
          return;
        }

        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          final String message = state.errorMessage!;
          if (_isVerificationEmailMessage(message)) {
            context.read<AuthBloc>().add(const AuthErrorCleared());
            return;
          }

          showSnackBar(context, state.errorMessage!, AppColors.red);
          context.read<AuthBloc>().add(const AuthErrorCleared());
        }

        if (state.isAuthenticated) {
          callNextScreenAndClearStack(context, const PermissionScreen());
        }
      },
      builder: (BuildContext context, AuthState state) {
        final bool isGoogleLoading =
            state.isLoading && state.actionType == AuthActionType.googleSignIn;

        return Scaffold(
          backgroundColor: AppColors.whiteBg,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(22, 8, 22, 10),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: Image.asset(
                              AppImage.logo,
                              height: 100.sp,
                              width: 100.sp,
                              fit: BoxFit.contain,
                            ),
                          ),
                          sb(10),
                          CommonText(
                            AppStrings.appName,
                            style: TextStyle(
                              fontSize: 30.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                      sb(20),
                      Container(
                        padding: EdgeInsets.all(26),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.greyLight,
                              blurRadius: 12,
                              offset: Offset(10, 10),
                            ),
                          ],
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: .start,
                          children: [
                            CommonText(
                              AppStrings.signInToContinue,
                              style: TextStyle(
                                fontSize: 30.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.black,
                              ),
                              textAlign: TextAlign.start,
                            ),
                            CommonText(
                              AppStrings.signInToContinueSubtitle,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w400,
                                color: AppColors.greyDark,
                              ),
                              textAlign: TextAlign.start,
                            ),
                            sb(30),
                            CustomButton(
                              onButtonPressed: () {
                                if (isGoogleLoading) {
                                  return;
                                }

                                context.read<AuthBloc>().add(
                                      const AuthSignInWithGoogleRequested(),
                                    );
                              },
                              isLoading: isGoogleLoading,
                              showPrefixIcon: true,
                              prefixImageAsset: AppImage.google,
                              prefixImageSize: 24,
                              buttonText: AppStrings.continueWithGoogle,
                              fontSize: 16.sp,
                            ),
                            sb(15),
                            CustomButton(
                              backgroundColor: AppColors.grey,
                              textColor: AppColors.greyDark,
                              onButtonPressed: () {
                                callNextScreen(context, const SigninScreen());
                              },
                              showPrefixIcon: true,
                              prefixIcon: Icon(AppIcons.mail, size: 30),
                              buttonText: AppStrings.signinWithEmail,
                              fontSize: 16.sp,
                            ),
                            sb(30),
                            SizedBox(
                              width: double.infinity,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: AppColors.greyDark,
                                      thickness: 0.7,
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 12),
                                    child: CommonText(
                                      'SECURE ACCESS',
                                      style: TextStyle(
                                        letterSpacing: 1,
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.greyDark,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: AppColors.greyDark,
                                      thickness: 0.7,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            sb(30),
                            CommonText(
                              AppStrings.privacyTerms,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w400,
                                color: AppColors.greyDark,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      sb(20),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: _infoCardHeight,
                              child: _SecurityInfoCard(
                                icon: AppIcons.shieldOutlined,
                                title: 'END-TO-END',
                                subtitle: 'Private Ledger Encryption',
                              ),
                            ),
                          ),
                          sbw(14),
                          Expanded(
                            child: SizedBox(
                              height: _infoCardHeight,
                              child: _SecurityInfoCard(
                                icon: AppIcons.lockOutline,
                                title: 'NO - TRACKING',
                                subtitle: 'Zero Data Monetization',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _isVerificationEmailMessage(String message) {
    final String lower = message.toLowerCase();
    return lower.contains('email not verified') ||
        lower.contains('email is not verified') ||
        lower.contains('verification email') ||
        lower.contains('verify and sign in') ||
        (lower.contains('verify') && lower.contains('email'));
  }
}

class _SecurityInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SecurityInfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.greyLight,
            blurRadius: 12,
            offset: Offset(10, 10),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Icon(icon, size: 30, color: AppColors.primaryDark),
            sb(8),
            CommonText(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.greyDark,
              ),
              textAlign: TextAlign.start,
            ),
            CommonText(
              subtitle,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.black,
              ),
              textAlign: TextAlign.start,
            ),
          ],
        ),
      ),
    );
  }
}
