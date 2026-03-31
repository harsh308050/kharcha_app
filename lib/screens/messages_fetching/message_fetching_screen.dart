import "package:flutter_screenutil/flutter_screenutil.dart";
import 'package:flutter/material.dart';
import 'package:kharcha/components/common_app_bar.dart';
import 'package:kharcha/components/sync_progress_circle.dart';
import 'package:kharcha/components/common_text.dart';
import 'package:kharcha/screens/home/home_screen.dart';
import 'package:kharcha/utils/constants/app_colors.dart';
import 'package:kharcha/utils/constants/app_image.dart';
import 'package:kharcha/utils/constants/app_strings.dart';
import 'package:kharcha/utils/my_cm.dart';

class MessageFetchingScreen extends StatefulWidget {
  const MessageFetchingScreen({super.key});

  @override
  State<MessageFetchingScreen> createState() => _MessageFetchingScreenState();
}

class _MessageFetchingScreenState extends State<MessageFetchingScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      callNextScreenAndClearStack(context, HomeScreen());
    });
    
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteBg,
      appBar: CommonAppBar(
        prefixImageAsset: AppImage.logo2,
        prefixImageWidth: 150,
        toolbarHeight: 68,
        appBarHorizontalPadding: 12,
        suffixImageAsset: AppImage.profilePlaceHolder,
        suffixImageBackgroundColor: AppColors.grey,
        isSuffixImageRound: true,
        suffixImageSize: 40,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommonText(
                AppStrings.systemSync,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2,
                  color: AppColors.greyDark,
                ),
              ),
              sb(8.sp),
              CommonText(
                AppStrings.importHistoryTitle,
                style: TextStyle(
                  fontSize: 32.sp,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: AppColors.black,
                ),
              ),
              sb(7.sp),
              CommonText(
                AppStrings.importHistoryDesc,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.greyDark,
                ),
              ),
              sb(70.sp),
              Center(
                child: SyncProgressCircle(
                  progress: 0.6,
                  statusText: 'Scanning...',
                  size: 240,
                  strokeWidth: 16,
                  ringColor: AppColors.primary,
                  fillColor: AppColors.greyLight,
                  statusTextColor: AppColors.primaryDark,
                ),
              ),
              sb(22),
              Center(
                child: Column(
                  children: [
                    CommonText(
                      '526',
                      style: TextStyle(
                        fontSize: 34.sp,
                        fontWeight: FontWeight.w900,
                        color: AppColors.black,
                      ),
                    ),
                    CommonText(
                      AppStrings.transactionsFound,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                        color: AppColors.greyDark,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    child: CommonText(
                          'Please wait while we fetch your messages',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
