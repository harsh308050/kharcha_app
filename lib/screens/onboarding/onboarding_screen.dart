import "package:flutter_screenutil/flutter_screenutil.dart";
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kharcha/components/common_button.dart';
import 'package:kharcha/components/common_tag_chip.dart';
import 'package:kharcha/components/common_text.dart';
import 'package:kharcha/screens/auth/auth_screen.dart';
import 'package:kharcha/utils/constants/app_colors.dart';
import 'package:kharcha/utils/constants/app_icons.dart';
import 'package:kharcha/utils/constants/app_image.dart';
import 'package:kharcha/utils/constants/app_strings.dart';
import 'package:kharcha/utils/my_cm.dart';
import 'package:kharcha/utils/permissions/permission_manager.dart';

double _responsiveFont(
  BuildContext context,
  double base, {
  double minScale = 0.85,
  double maxScale = 1.0,
}) {
  final double width = MediaQuery.sizeOf(context).width;
  final double scale = (width / 390).clamp(minScale, maxScale);
  return base * scale;
}

class OnboardingScreen extends StatefulWidget {

  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final PermissionManager _permissionManager = PermissionManager();
  int _currentPage = 0;
  final int _totalPages = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
      return;
    }
    callNextScreenAndClearStack(context, const AuthScreen());
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.whiteBg,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.whiteBg,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.whiteBg,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (int page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  children: [
                    _AutoTrackingPage(),
                    _PrivacyPromisePage(),
                    _NotificationTaggingPage(),
                  ],
                ),
              ),
              sb(16),
              _buildIndicator(),
              sb(18),
              _buildBottomActions(),
              sb(16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {

    if (_currentPage == 1) {
      return Padding(
        padding: EdgeInsets.fromLTRB(24, 14, 24, 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: CommonText(
            AppStrings.onboardingSecurityProtocol,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              letterSpacing: 2.8,
              color: AppColors.primaryDark,
            ),
          ),
        ),
      );
    }

    if (_currentPage == 2) {
      return Padding(
        padding: EdgeInsets.fromLTRB(12, 8, 14, 6),
        child: Row(
          children: [
            IconButton(
              onPressed: _goToPreviousPage,
              icon: Icon(
                AppIcons.arrowBackIos,
                color: AppColors.primary,
              ),
            ),
            Expanded(
              child: Center(
                child: CommonText(
                  AppStrings.appName,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Image.asset(AppImage.logo2, height: 80, fit: BoxFit.contain);
  }

  Widget _buildIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalPages, (index) {
        final bool isActive = _currentPage == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          margin: EdgeInsets.symmetric(horizontal: 6),
          width: isActive ? 30 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            color: isActive ? AppColors.primary : AppColors.grey,
          ),
        );
      }),
    );
  }

  Widget _buildBottomActions() {
    final double actionTextSize = _responsiveFont(context, 18);

    if (_currentPage == 1) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            TextButton(
              onPressed: _goToPreviousPage,
              child: CommonText(
                AppStrings.back,
                style: TextStyle(
                  color: AppColors.greyDark,
                  fontSize: actionTextSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Spacer(),
            CustomButton(
              onButtonPressed: _goToNextPage,
              buttonText: AppStrings.next,
              btnWidth: 160,
              showTrailingIcon: true,
              trailingIcon: Icon(AppIcons.arrowForwardIos, size: 18),
              fontSize: actionTextSize,
            ),
          ],
        ),
      );
    }

    if (_currentPage == 2) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            CustomButton(
              onButtonPressed: () async {
                await _permissionManager.requestNotificationPermission();
                if (context.mounted) {
                  callNextScreenAndClearStack(context, const AuthScreen());
                }
              },
              buttonText: 'Allow Notifications',
              borderRadius: 32,
            ),
            sb(12),
            TextButton(
              onPressed: () {
                callNextScreenAndClearStack(context, const AuthScreen());
              },
              child: CommonText(
                'Skip for now',
                style: TextStyle(
                  color: AppColors.greyDark,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          CustomButton(
            onButtonPressed: _goToNextPage,
            buttonText: AppStrings.next,
            showTrailingIcon: true,
            trailingIcon: Icon(AppIcons.arrowForwardIos, size: 20),
            borderRadius: 32,
          ),
        ],
      ),
    );
  }
}

class _AutoTrackingPage extends StatelessWidget {
  const _AutoTrackingPage();

  @override
  Widget build(BuildContext context) {
    final double titleSize = _responsiveFont(context, 35);
    final double bodySize = _responsiveFont(context, 16);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(22, 8, 22, 10),
      child: Column(
        children: [
          Image.asset(
            AppImage.onboardingHeroAsset,
            width: 280.sp,
            fit: BoxFit.contain,
          ),
          CommonText.rich(
            TextSpan(
              style: TextStyle(
                fontFamily: 'FunnelDisplay',
                fontSize: titleSize,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
              children: [
                TextSpan(text: AppStrings.onBoardingTitle1),
                TextSpan(text: '\n'),
                TextSpan(
                  text: AppStrings.onBoardingTitle1_1,
                  style: TextStyle(color: AppColors.primary),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          sb(14),
          CommonText(
            AppStrings.onBoardingDesc1,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: bodySize,
              height: 1.35,
              color: AppColors.greyDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyPromisePage extends StatelessWidget {
  const _PrivacyPromisePage();

  @override
  Widget build(BuildContext context) {

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 6, 24, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommonText(
            AppStrings.onBoardingTitle2,
            style: TextStyle(
              fontSize: 40.sp,
              height: 1.0,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          sb(30),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Image.asset(
                    AppStrings.decorativePercentAsset,
                    width: 158.sp,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(18, 18, 18, 16),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: 46.sp,
                          height: 46.sp,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.all(
                                Radius.circular(13.sp),
                              ),
                            ),
                            child: Icon(
                              AppIcons.checkCircle,
                              color: AppColors.primary,
                              size: 24.sp,
                            ),
                          ),
                        ),
                      ),
                      sb(18.sp),
                      _PrivacyItem(
                        icon: AppIcons.shieldOutlined,
                        title: AppStrings.privacyTitle1,
                        subtitle: AppStrings.privacyDesc1,
                      ),
                      sb(18),
                      _PrivacyItem(
                        icon: AppIcons.devicesOutlined,
                        title: AppStrings.privacyTitle2,
                        subtitle: AppStrings.privacyDesc2,
                      ),
                      sb(18),
                      _PrivacyItem(
                        icon: AppIcons.barChartOutlined,
                        title: AppStrings.privacyTitle3,
                        subtitle: AppStrings.privacyDesc3,
                      ),
                    ],
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

class _NotificationTaggingPage extends StatelessWidget {
  const _NotificationTaggingPage();

  @override
  Widget build(BuildContext context) {

    return SingleChildScrollView(
      child: Column(
        children: [
          sb(10),
          Padding(
            padding: EdgeInsets.fromLTRB(18, 8, 18, 0),
            child: _QuickTagPreviewCard(),
          ),
          sb(30),
          Padding(
            padding: EdgeInsets.fromLTRB(22, 20, 22, 0),
            child: Column(
              children: [
                CommonText(
                  AppStrings.onBoardingTitle3,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 38.sp,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    color: AppColors.black,
                  ),
                ),
                sb(12),
                CommonText(
                  AppStrings.onBoardingDesc3,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16.sp,
                    height: 1.35,
                    fontWeight: FontWeight.w400,
                    color: AppColors.greyDark,
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

class _QuickTagPreviewCard extends StatelessWidget {
  const _QuickTagPreviewCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.12),
            blurRadius: 26,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CommonText(
                  AppStrings.onboardingLedgerLabel,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                    color: AppColors.primaryDark,
                  ),
                ),
            sb(6),
            CommonText(
              AppStrings.onboardingExpenseDetected,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.w900,
                color: AppColors.black,
                height: 1,
              ),
            ),
            sb(6),
            CommonText(
              AppStrings.onboardingSampleExpense,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.greyDark,
              ),
            ),
            sb(14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                CommonTagChip(
                  icon: Icons.restaurant,
                  label: AppStrings.onboardingTagFood,
                  iconColor: AppColors.orange,
                ),
                CommonTagChip(
                  icon: Icons.flight,
                  label: AppStrings.onboardingTagTravel,
                  iconColor: AppColors.blue,
                ),
                CommonTagChip(
                  icon: Icons.shopping_bag_outlined,
                  label: AppStrings.onboardingTagShopping,
                  iconColor: AppColors.purple,
                ),
                CommonTagChip(
                  icon: Icons.receipt_long,
                  label: AppStrings.onboardingTagOther,
                  iconColor: AppColors.greyDark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PrivacyItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
    );
  }
}
