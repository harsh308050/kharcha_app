import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kharcha/components/common_shimmer.dart';
import 'package:kharcha/components/common_text.dart';
import 'package:kharcha/utils/drive/drive_read_service.dart';
import 'package:kharcha/utils/constants/app_colors.dart';
import 'package:kharcha/utils/constants/app_icons.dart';
import 'package:kharcha/utils/constants/app_strings.dart';
import 'package:kharcha/utils/my_cm.dart';
import 'package:kharcha/utils/sms/sms_transaction.dart';

enum _HomeRangeFilter { today, thisWeek, thisMonth, thisYear }

extension _HomeRangeFilterLabel on _HomeRangeFilter {
  String get label {
    return switch (this) {
      _HomeRangeFilter.today => 'Today',
      _HomeRangeFilter.thisWeek => 'This Week',
      _HomeRangeFilter.thisMonth => 'This month',
      _HomeRangeFilter.thisYear => 'This Year',
    };
  }
}

class HomeTabScreen extends StatefulWidget {
  final HomeTabData? data;

  const HomeTabScreen({super.key, this.data});

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> {
  _HomeRangeFilter _selectedFilter = _HomeRangeFilter.today;
  late final DriveReadService _driveReadService;
  List<SmsTransaction> _transactions = <SmsTransaction>[];
  bool _isLoadingTransactions = true;

  @override
  void initState() {
    super.initState();
    _driveReadService = DriveReadService();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoadingTransactions = true;
    });

    final List<SmsTransaction> transactions = await _driveReadService
        .readTransactionsFromDrive();

    if (!mounted) {
      return;
    }

    setState(() {
      _transactions = transactions;
      _isLoadingTransactions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final HomeTabData data = widget.data ?? HomeTabData.demo();
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String normalizedEmail = (currentUser?.email ?? '')
        .trim()
        .toLowerCase();

    if (normalizedEmail.isEmpty) {
      final String fallbackName = _firstNameFrom(
        (currentUser?.displayName ?? '').trim(),
      );
      final String greeting = _timeGreeting(fallbackName);
      return _buildDashboard(data: data, greeting: greeting);
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(normalizedEmail)
          .snapshots(),
      builder:
          (
            BuildContext context,
            AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot,
          ) {
            final Map<String, dynamic>? userData = snapshot.data?.data();
            final String fullName =
                (userData?['fullName'] as String?)?.trim().isNotEmpty == true
                ? (userData?['fullName'] as String).trim()
                : (currentUser?.displayName ?? 'User');
            final String greeting = _timeGreeting(_firstNameFrom(fullName));
            return _buildDashboard(data: data, greeting: greeting);
          },
    );
  }

  Widget _buildDashboard({
    required HomeTabData data,
    required String greeting,
  }) {
    final bool isLoading = _isLoadingTransactions;
    final List<SmsTransaction> filteredTransactions = _applyDateFilter(
      _transactions,
    );

    double income = 0;
    double expenses = 0;
    for (final SmsTransaction transaction in filteredTransactions) {
      if (transaction.amount <= 0) {
        continue;
      }

      final SmsTransactionType effectiveType = _resolveTypeForSummary(
        transaction,
      );

      if (effectiveType == SmsTransactionType.credit) {
        income += transaction.amount;
      } else if (effectiveType == SmsTransactionType.debit) {
        expenses += transaction.amount;
      }
    }

    final String totalSpendValue = _formatCurrency(income + expenses);
    final List<HomeTopStatData> topStats = <HomeTopStatData>[
      HomeTopStatData(
        label: AppStrings.income,
        value: _formatCurrency(income),
        valueColor: AppColors.primaryDark,
      ),
      HomeTopStatData(
        label: AppStrings.expenses,
        value: _formatCurrency(expenses),
        valueColor: AppColors.red,
      ),
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLoading)
            const _SpendSummaryShimmer()
          else
            _SpendSummary(
              greeting: "$greeting!",
              totalSpendValue: totalSpendValue,
              totalSpendLabel: "Total",
              selectedFilter: _selectedFilter,
              onFilterChanged: (_HomeRangeFilter selected) {
                setState(() {
                  _selectedFilter = selected;
                });
              },
            ),
          sb(20),
          if (isLoading)
            const _TopStatsRowShimmer()
          else
            _TopStatsRow(stats: topStats),
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

  String _timeGreeting(String firstName) {
    final int hour = DateTime.now().hour;
    final String salutation = hour < 12
        ? 'Good Morning'
        : hour < 17
        ? 'Good Afternoon'
        : hour < 21
        ? 'Good Evening'
        : 'Good Night';
    return '$salutation $firstName';
  }

  String _firstNameFrom(String fullName) {
    final String normalized = fullName.trim();
    if (normalized.isEmpty) {
      return 'User';
    }

    final int firstSpaceIndex = normalized.indexOf(' ');
    String firstName;
    if (firstSpaceIndex <= 0) {
      firstName = normalized;
    } else {
      firstName = normalized.substring(0, firstSpaceIndex).trim();
    }

    // Capitalize first letter
    if (firstName.isEmpty) {
      return 'User';
    }
    return firstName[0].toUpperCase() + firstName.substring(1).toLowerCase();
  }

  String _formatCurrency(double amount) {
    final int intAmount = amount.toInt();
    final String amountStr = intAmount.toString();

    if (amountStr.length <= 3) {
      return '₹$amountStr';
    }

    // Separate last 3 digits and everything before
    final String lastThree = amountStr.substring(amountStr.length - 3);
    final String beforeLastThree = amountStr.substring(0, amountStr.length - 3);

    // Format the part before last 3 with commas every 2 digits from right
    final StringBuffer formattedBefore = StringBuffer();
    for (int i = 0; i < beforeLastThree.length; i++) {
      if (i > 0 && (beforeLastThree.length - i) % 2 == 0) {
        formattedBefore.write(',');
      }
      formattedBefore.write(beforeLastThree[i]);
    }

    // Combine
    return '₹$formattedBefore,$lastThree';
  }

  List<SmsTransaction> _applyDateFilter(List<SmsTransaction> source) {
    final DateTime now = DateTime.now();
    final DateTime endExclusive = DateTime(now.year, now.month, now.day + 1);

    final DateTime startInclusive = switch (_selectedFilter) {
      _HomeRangeFilter.today => DateTime(now.year, now.month, now.day),
      _HomeRangeFilter.thisWeek => DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1)),
      _HomeRangeFilter.thisMonth => DateTime(now.year, now.month, 1),
      _HomeRangeFilter.thisYear => DateTime(now.year, 1, 1),
    };

    return source.where((SmsTransaction transaction) {
      final DateTime txDate = transaction.transactionDate;
      return !txDate.isBefore(startInclusive) && txDate.isBefore(endExclusive);
    }).toList();
  }

  SmsTransactionType _resolveTypeForSummary(SmsTransaction item) {
    if (item.type == SmsTransactionType.credit ||
        item.type == SmsTransactionType.debit) {
      return item.type;
    }

    final String text = item.rawMessage.toLowerCase();
    final bool hasCreditKeyword = RegExp(
      r'\b(?:credited|credit|received|deposit(?:ed)?|salary|cr\.?)\b',
      caseSensitive: false,
    ).hasMatch(text);
    final bool hasDebitKeyword = RegExp(
      r'\b(?:debited|debit|paid|spent|withdrawn|deducted|purchase|sent|dr\.?)\b',
      caseSensitive: false,
    ).hasMatch(text);

    if (hasCreditKeyword && !hasDebitKeyword) {
      return SmsTransactionType.credit;
    }
    if (hasDebitKeyword && !hasCreditKeyword) {
      return SmsTransactionType.debit;
    }

    return item.type;
  }
}

class _SpendSummaryShimmer extends StatelessWidget {
  const _SpendSummaryShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const CommonShimmerBlock(width: 170, height: 20),
            const Spacer(),
            CommonShimmerBlock(
              width: 112.w,
              height: 36.h,
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
        sb(12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            CommonShimmerBlock(
              width: 170.w,
              height: 44.h,
              borderRadius: BorderRadius.circular(14),
            ),
            sbw(10),
            const CommonShimmerBlock(width: 92, height: 16),
          ],
        ),
      ],
    );
  }
}

class _TopStatsRowShimmer extends StatelessWidget {
  const _TopStatsRowShimmer();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCardShimmer()),
        sbw(10),
        Expanded(child: _StatCardShimmer()),
      ],
    );
  }
}

class _StatCardShimmer extends StatelessWidget {
  const _StatCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118.h,
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.grey.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CommonShimmerBlock(width: 76, height: 12),
          sb(14),
          const CommonShimmerBlock(width: 120, height: 24),
        ],
      ),
    );
  }
}

class _SpendSummary extends StatelessWidget {
  final String greeting;
  final String totalSpendValue;
  final String totalSpendLabel;
  final _HomeRangeFilter selectedFilter;
  final ValueChanged<_HomeRangeFilter> onFilterChanged;

  const _SpendSummary({
    required this.greeting,
    required this.totalSpendValue,
    required this.totalSpendLabel,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: CommonText(
                greeting,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.greyDark,
                ),
              ),
            ),
            sbw(10),
            _HomeRangeDropdown(
              selectedFilter: selectedFilter,
              onChanged: onFilterChanged,
            ),
          ],
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

class _HomeRangeDropdown extends StatelessWidget {
  final _HomeRangeFilter selectedFilter;
  final ValueChanged<_HomeRangeFilter> onChanged;

  const _HomeRangeDropdown({
    required this.selectedFilter,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_HomeRangeFilter>(
      initialValue: selectedFilter,
      onSelected: onChanged,
      color: AppColors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (BuildContext context) {
        return _HomeRangeFilter.values
            .map(
              (_HomeRangeFilter option) => PopupMenuItem<_HomeRangeFilter>(
                value: option,
                child: CommonText(
                  option.label,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: option == selectedFilter
                        ? AppColors.primary
                        : AppColors.greyDark,
                  ),
                ),
              ),
            )
            .toList();
      },
      child: Container(
        height: 40,
        padding: EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CommonText(
              selectedFilter.label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
            sbw(4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: AppColors.white,
            ),
          ],
        ),
      ),
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
      height: 118.h,
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
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
              fontSize: 30.h,
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
            child: Icon(AppIcons.celebration, color: AppColors.white, size: 34),
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
