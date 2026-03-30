import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kharcha/components/common_button.dart';
import 'package:kharcha/utils/constants/app_colors.dart';
import 'package:kharcha/utils/constants/app_image.dart';
import 'package:kharcha/utils/constants/app_strings.dart';
import 'package:kharcha/utils/my_cm.dart';

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
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
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
    widget.onComplete();
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
                  children: const [
                    _AutoTrackingPage(),
                    _PrivacyPromisePage(),
                    _NotificationTaggingPage(),
                  ],
                ),
              ),
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
    final double appNameSize = _responsiveFont(context, 34);

    if (_currentPage == 1) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(24, 14, 24, 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            AppStrings.onboardingSecurityProtocol,
            style: TextStyle(
              fontSize: 12,
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
        padding: const EdgeInsets.fromLTRB(12, 8, 14, 6),
        child: Row(
          children: [
            IconButton(
              onPressed: _goToPreviousPage,
              icon: const Icon(Icons.arrow_back, color: AppColors.primary),
            ),
            Expanded(
              child: Center(
                child: Text(
                  AppStrings.appName,
                  style: TextStyle(
                    fontSize: appNameSize,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ),
            const Icon(Icons.lock_outline, color: AppColors.greyDark),
          ],
        ),
      );
    }

    return Image.asset(AppImage.logo2, height: 100, fit: BoxFit.contain);
  }

  Widget _buildIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalPages, (index) {
        final bool isActive = _currentPage == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 6),
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
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            TextButton(
              onPressed: _goToPreviousPage,
              child: Text(
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
              trailingIcon: const Icon(Icons.arrow_forward, size: 18),
              fontSize: actionTextSize,
            ),
          ],
        ),
      );
    }

    if (_currentPage == 2) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            CustomButton(
              onButtonPressed: _goToNextPage,
              buttonText: AppStrings.getStarted,
              showTrailingIcon: true,
              trailingIcon: const Icon(Icons.arrow_forward_ios, size: 16),
              btnHeight: 64,
              borderRadius: 32,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          CustomButton(
            onButtonPressed: _goToNextPage,
            buttonText: AppStrings.next,
            showTrailingIcon: true,
            trailingIcon: const Icon(Icons.arrow_forward, size: 20),
            btnHeight: 64,
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
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 10),
      child: Column(
        children: [
          Image.asset(
            AppImage.onboardingHeroAsset,
            width: 400,
            fit: BoxFit.contain,
          ),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontFamily: 'FunnelDisplay',
                fontSize: titleSize,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
              children: const [
                TextSpan(text: AppStrings.onBoardingTitle1),
                TextSpan(text: '\n'),
                TextSpan(
                  text: AppStrings.onBoardingTitle1_1,
                  style: TextStyle(color: AppColors.primary),
                ),
              ],
            ),
          ),
          sb(14),
          Text(
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
    final double headingSize = _responsiveFont(context, 48);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.onBoardingTitle2,
            style: TextStyle(
              fontSize: headingSize,
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
                    width: 128,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: 66,
                          height: 66,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.all(
                                Radius.circular(16),
                              ),
                            ),
                            child: Icon(
                              Icons.check_circle,
                              color: AppColors.primary,
                              size: 34,
                            ),
                          ),
                        ),
                      ),
                      sb(28),
                      _PrivacyItem(
                        icon: Icons.shield_outlined,
                        title: AppStrings.privacyTitle1,
                        subtitle: AppStrings.privacyDesc1,
                      ),
                      sb(18),
                      _PrivacyItem(
                        icon: Icons.devices_outlined,
                        title: AppStrings.privacyTitle2,
                        subtitle: AppStrings.privacyDesc2,
                      ),
                      sb(18),
                      _PrivacyItem(
                        icon: Icons.bar_chart_outlined,
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
    final double headingSize = _responsiveFont(context, 35);
    final double bodySize = _responsiveFont(context, 18);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 8),
      child: Column(
        children: [
          Image.asset(
              AppImage.onboardingCardAsset,
              width: double.infinity,
              fit: BoxFit.fitWidth,
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
            child: Column(
              children: [
                Text(
                  AppStrings.onBoardingTitle3,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: headingSize,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    color: AppColors.black,
                  ),
                ),
                sb(12),
                Text(
                  AppStrings.onBoardingDesc3,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: bodySize,
                    height: 1.35,
                    fontWeight: FontWeight.w400,
                    color: AppColors.greyDark,
                  ),
                ),
              ],
            ),
          ),
    ],
      ));
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
          padding: const EdgeInsets.only(top: 4),
          child: Icon(icon, size: 29, color: AppColors.primaryDark),
        ),
        sbw(10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
              sb(5),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 18,
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
