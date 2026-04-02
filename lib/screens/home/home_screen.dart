import "package:flutter_screenutil/flutter_screenutil.dart";
import 'package:flutter/material.dart';
import 'package:kharcha/components/common_text.dart';
import 'package:kharcha/screens/add_expense/add_expense_screen.dart';
import 'package:kharcha/screens/budget/budget_screen.dart';
import 'package:kharcha/screens/report/report_screen.dart';
import 'package:kharcha/screens/hometab/hometab_screen.dart';
import 'package:kharcha/screens/ledger/ledger_screen.dart';
import 'package:kharcha/screens/settings/settings_screen.dart';
import 'package:kharcha/utils/constants/app_colors.dart';
import 'package:kharcha/utils/constants/app_icons.dart';
import 'package:kharcha/utils/constants/app_image.dart';
import 'package:kharcha/utils/constants/app_strings.dart';
import 'package:kharcha/utils/my_cm.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const int _homeTabIndex = 0;
  static const int _ledgerTabIndex = 1;
  static const int _settingsTabIndex = 4;
  int _selectedIndex = 0;

  // PageController for PageView
  late final PageController _pageController;

  static final List<_BottomBarItemData> _items = <_BottomBarItemData>[
    _BottomBarItemData(label: AppStrings.home, icon: AppIcons.homeFilled),
    _BottomBarItemData(label: AppStrings.ledger, icon: AppIcons.ledger),
    _BottomBarItemData(label: AppStrings.reports, icon: AppIcons.report),
    _BottomBarItemData(label: AppStrings.budget, icon: AppIcons.wallet),
    _BottomBarItemData(
      label: AppStrings.settings,
      icon: AppIcons.settingsOutlined,
    ),
  ];

  final List<Widget> _tabScreens = const <Widget>[
    HomeTabScreen(),
    LedgerTabScreen(),
    ReportTabScreen(),
    BudgetTabScreen(),
    SettingsTabScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool showSharedTopBar = _selectedIndex != _settingsTabIndex;
    final bool showFab =
        _selectedIndex == _homeTabIndex || _selectedIndex == _ledgerTabIndex;

    return Scaffold(
      backgroundColor: AppColors.whiteBg,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: showFab
          ? Padding(
              padding: EdgeInsets.only(bottom: 86, right: 8),
              child: SizedBox(
                width: 55.sp,
                height: 50.sp,
                child: FloatingActionButton(
                  onPressed: () {
                    callNextScreen(context, AddExpenseScreen());
                  },
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  elevation: 8,
                  shape: const CircleBorder(),
                  child: Icon(AppIcons.add, size: 30.sp),
                ),
              ),
            )
          : null,
      body: Column(
        children: [
          if (showSharedTopBar) const _SharedTopBar(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // Disable swipe, use bottom bar
              children: _tabScreens,
              onPageChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
          ),
          _CustomBottomBar(
            selectedIndex: _selectedIndex,
            items: _items,
            onTap: (int index) {
              setState(() {
                _selectedIndex = index;
              });
              _pageController.jumpToPage(index);
            },
          ),
        ],
      ),
    );
  }
}

class _SharedTopBar extends StatelessWidget {
  const _SharedTopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.whiteBg,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                padding: EdgeInsets.only(top: 5, bottom: 0, left: 5, right: 5),
                decoration: const BoxDecoration(
                  color: AppColors.grey,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                
                  child: Image.asset(
                    AppImage.profilePlaceHolder,
                    width: 24,
                    height: 24,
                    fit: BoxFit.cover,
                  ),
                ),
                // child: Icon(AppIcons.person, color: AppColors.greyDark, size: 24),
              ),
              Spacer(),
              CommonText(
                AppStrings.appName,
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomBottomBar extends StatelessWidget {
  final int selectedIndex;
  final List<_BottomBarItemData> items;
  final ValueChanged<int> onTap;

  const _CustomBottomBar({
    required this.selectedIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final double itemWidth = (screenWidth - 20) / items.length;
    final double labelFontSize = itemWidth < 66
        ? 8.5
        : itemWidth < 74
        ? 9.5
        : itemWidth < 82
        ? 10.5
        : 12;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(36),
          topRight: Radius.circular(36),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List<Widget>.generate(items.length, (int index) {
            final bool isActive = selectedIndex == index;
            final _BottomBarItemData item = items[index];
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(index),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 2),
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                  decoration: BoxDecoration(
                    color: AppColors.transparent, // Remove background from container
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Active background only around icon
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.primaryLight : AppColors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          item.icon,
                          size: 28,
                          color: isActive ? AppColors.primaryDark : AppColors.greyDark,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      SizedBox(
                        width: double.infinity,
                        child: CommonText(
                          item.label.toUpperCase(),
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: labelFontSize,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                            color: isActive
                                ? AppColors.primary // Active label color matches active theme
                                : AppColors.greyDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _BottomBarItemData {
  final String label;
  final IconData icon;

  const _BottomBarItemData({required this.label, required this.icon});
}