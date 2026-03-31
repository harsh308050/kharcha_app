import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kharcha/components/common_text.dart';
import 'package:kharcha/utils/constants/app_colors.dart';
import 'package:kharcha/utils/constants/app_icons.dart';
import 'package:kharcha/utils/constants/app_strings.dart';
import 'package:kharcha/utils/my_cm.dart';

class HomeTabScreen extends StatefulWidget {
  final HomeTabData? data;

  const HomeTabScreen({super.key, this.data});

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> {
  @override
  Widget build(BuildContext context) {
    final HomeTabData data = widget.data ?? HomeTabData.demo();

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SpendSummary(
            greeting: data.greeting,
            totalSpendValue: data.totalSpendValue,
            totalSpendLabel: data.totalSpendLabel,
          ),
          sb(20),
          _TopStatsRow(stats: data.topStats),
          sb(20),
          _BudgetAlertCard(
            title: data.budgetAlert.title,
            description: data.budgetAlert.description,
          ),
          sb(20),
          _GoalCard(data: data.goalCard),
          sb(20),
          _BudgetProgressCard(data: data.budgetProgress),
        ],
      ),
    );
  }
}

class _SpendSummary extends StatelessWidget {
  final String greeting;
  final String totalSpendValue;
  final String totalSpendLabel;

  const _SpendSummary({
    required this.greeting,
    required this.totalSpendValue,
    required this.totalSpendLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommonText(
          greeting,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.greyDark,
          ),
        ),
        sb(8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            CommonText(
              totalSpendValue,
              style: TextStyle(
                fontSize: 45.sp,
                height: 0.95,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            sbw(6),
            Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: CommonText(
                totalSpendLabel,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                  color: AppColors.greyDark,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TopStatsRow extends StatelessWidget {
  final List<HomeTopStatData> stats;

  const _TopStatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[];

    for (int i = 0; i < stats.length; i++) {
      children.add(
        Expanded(
          child: _StatCard(
            label: stats[i].label,
            value: stats[i].value,
            valueColor: stats[i].valueColor,
          ),
        ),
      );

      if (i < stats.length - 1) {
        children.add(sbw(8));
      }
    }

    return Row(children: children);
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.grey.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommonText(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
              color: AppColors.greyDark,
            ),
          ),
          sb(10.h),
          CommonText(
            value,
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetAlertCard extends StatelessWidget {
  final String title;
  final String description;

  const _BudgetAlertCard({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border(top: BorderSide(color: AppColors.yellow, width: 4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: AppColors.greyLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              AppIcons.warningAmber,
              color: AppColors.orange,
              size: 22,
            ),
          ),
          sbw(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CommonText(
                  title,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
                sb(5),
                CommonText(
                  description,
                  style: TextStyle(
                    fontSize: 12.sp,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
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

class _GoalCard extends StatelessWidget {
  final HomeGoalCardData data;

  const _GoalCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0E7A63), Color(0xFF2B9584)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GoalBadge(),
                SizedBox(height: 14.h),
                CommonText(
                  data.title,
                  style: TextStyle(
                    fontSize: 19.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                SizedBox(height: 6.h),
                CommonText(
                  data.description,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                    color: Color(0xFFE5F4EE),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              AppIcons.celebration,
              color: AppColors.white,
              size: 34,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalBadge extends StatelessWidget {
  const _GoalBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: CommonText(
        AppStrings.goalAchieved,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.7,
          color: AppColors.white,
        ),
      ),
    );
  }
}

class _BudgetProgressCard extends StatelessWidget {
  final HomeBudgetProgressData data;

  const _BudgetProgressCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.grey.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommonText(
            AppStrings.budgetProgress,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.black,
            ),
          ),
          sb(16),
          ..._buildProgressLines(),
        ],
      ),
    );
  }

  List<Widget> _buildProgressLines() {
    final List<Widget> widgets = <Widget>[];
    for (int i = 0; i < data.lines.length; i++) {
      final HomeProgressLineData line = data.lines[i];
      widgets.add(
        _ProgressLine(
          label: line.label,
          valueText: line.valueText,
          ratio: line.ratio,
        ),
      );
      if (i < data.lines.length - 1) {
        widgets.add(sb(18));
      }
    }
    return widgets;
  }
}

class _ProgressLine extends StatelessWidget {
  final String label;
  final String valueText;
  final double ratio;

  const _ProgressLine({
    required this.label,
    required this.valueText,
    required this.ratio,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CommonText(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),
            const Spacer(),
            CommonText(
              valueText,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.greyDark,
              ),
            ),
          ],
        ),
        sb(8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: ratio,
            backgroundColor: AppColors.grey,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class HomeTabData {
  final String appName;
  final String greeting;
  final String totalSpendValue;
  final String totalSpendLabel;
  final List<HomeTopStatData> topStats;
  final HomeBudgetAlertData budgetAlert;
  final HomeGoalCardData goalCard;
  final HomeBudgetProgressData budgetProgress;

  const HomeTabData({
    required this.appName,
    required this.greeting,
    required this.totalSpendValue,
    required this.totalSpendLabel,
    required this.topStats,
    required this.budgetAlert,
    required this.goalCard,
    required this.budgetProgress,
  });

  factory HomeTabData.demo() {
    return const HomeTabData(
      appName: AppStrings.appName,
      greeting: AppStrings.goodMorningUser,
      totalSpendValue: '₹45,200',
      totalSpendLabel: AppStrings.totalSpend,
      topStats: [
        HomeTopStatData(
          label: AppStrings.income,
          value: '₹82,000',
          valueColor: AppColors.primaryDark,
        ),
        HomeTopStatData(
          label: AppStrings.expenses,
          value: '₹36,800',
          valueColor: AppColors.red,
        ),
        HomeTopStatData(
          label: AppStrings.balance,
          value: '₹45,200',
          valueColor: AppColors.primaryDark,
        ),
      ],
      budgetAlert: HomeBudgetAlertData(
        title: AppStrings.budgetUsedTitle,
        description: AppStrings.budgetUsedDesc,
      ),
      goalCard: HomeGoalCardData(
        title: AppStrings.newCarFund,
        description: AppStrings.newCarFundDesc,
      ),
      budgetProgress: HomeBudgetProgressData(
        lines: [
          HomeProgressLineData(
            label: AppStrings.foodAndDrinks,
            valueText: '₹8,500 / ₹12,000',
            ratio: 0.70,
          ),
          HomeProgressLineData(
            label: AppStrings.travel,
            valueText: '₹4,200 / ₹5,000',
            ratio: 0.84,
          ),
        ],
      ),
    );
  }
}

class HomeTopStatData {
  final String label;
  final String value;
  final Color valueColor;

  const HomeTopStatData({
    required this.label,
    required this.value,
    required this.valueColor,
  });
}

class HomeBudgetAlertData {
  final String title;
  final String description;

  const HomeBudgetAlertData({required this.title, required this.description});
}

class HomeGoalCardData {
  final String title;
  final String description;

  const HomeGoalCardData({required this.title, required this.description});
}

class HomeAvatarData {
  final String label;
  final Color background;
  final Color foreground;

  const HomeAvatarData({
    required this.label,
    required this.background,
    required this.foreground,
  });
}

class HomeBudgetProgressData {
  final List<HomeProgressLineData> lines;

  const HomeBudgetProgressData({required this.lines});
}

class HomeProgressLineData {
  final String label;
  final String valueText;
  final double ratio;

  const HomeProgressLineData({
    required this.label,
    required this.valueText,
    required this.ratio,
  });
}
