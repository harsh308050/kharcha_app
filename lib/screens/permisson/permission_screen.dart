import "package:flutter_screenutil/flutter_screenutil.dart";
import 'package:flutter/material.dart';
import 'package:kharcha/components/common_button.dart';
import 'package:kharcha/components/common_text.dart';
import 'package:kharcha/screens/home/home_screen.dart';
import 'package:kharcha/screens/messages_fetching/message_fetching_screen.dart';
import 'package:kharcha/utils/constants/app_colors.dart';
import 'package:kharcha/utils/constants/app_icons.dart';
import 'package:kharcha/utils/constants/app_strings.dart';
import 'package:kharcha/utils/my_cm.dart';

class PermissionScreen extends StatelessWidget {
  const PermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteBg,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(22, 8, 22, 10),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CommonText.rich(
                  TextSpan(
                    style: TextStyle(
                      fontSize: 34.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                    children: [
                      TextSpan(text: AppStrings.permissionPageTitle1),
                      TextSpan(text: '\n'),
                      TextSpan(
                        text: AppStrings.permissionPageTitle2,
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ],
                  ),
                  textAlign: .start,
                ),
                sb(14),
                CommonText(
                  AppStrings.permissionPageDesc,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontSize: 16.sp,
                    height: 1.35,
                    color: AppColors.greyDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                sb(28),
                _PermissionItem(
                  icon: AppIcons.message,
                  title: AppStrings.permissionPagePermissionTitle1,
                  subtitle: AppStrings.permissionPagePermissionDesc1,
                ),
                sb(18),
                _PermissionItem(
                  icon: AppIcons.notification,
                  title: AppStrings.permissionPagePermissionTitle2,
                  subtitle: AppStrings.permissionPagePermissionDesc2,
                ),
                
                sb(30),
                CustomButton(
                  onButtonPressed: () {
                    callNextScreenAndClearStack(context, MessageFetchingScreen());
                  },
                  buttonText: AppStrings.allowSMSAccess,
                  fontSize: 18.sp,
                ),
                sb(18),
                Center(
                  child: TextButton(
                    style: ButtonStyle(
                      splashFactory: NoSplash.splashFactory
                    ),
                    onPressed: () {
                      callNextScreenAndClearStack(context, HomeScreen());
                    },
                    child: CommonText(
                      AppStrings.iWillDoItLater,
                      textAlign: .center,
                      style: TextStyle(
                        color: AppColors.greyDark,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                sb(30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PermissionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PermissionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.white,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(icon, size: 29, color: AppColors.primaryDark),
          ),
          sbw(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CommonText(
                  title,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
                sb(5),
                CommonText(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.greyDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
