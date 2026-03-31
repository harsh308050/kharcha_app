import "package:flutter_screenutil/flutter_screenutil.dart";
import 'package:flutter/material.dart';
import 'package:kharcha/components/common_button.dart';
import 'package:kharcha/components/common_text.dart';
import 'package:kharcha/utils/constants/app_colors.dart';
import 'package:kharcha/utils/constants/app_strings.dart';
import 'package:kharcha/utils/my_cm.dart';

class ReportTabScreen extends StatefulWidget {
  const ReportTabScreen({super.key});

  @override
  State<ReportTabScreen> createState() => ReportTabScreenState();
}

class ReportTabScreenState extends State<ReportTabScreen> {
  String _selectedFilter = AppStrings.thisMonth;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommonText(
            AppStrings.financialSummary,
            style: TextStyle(
              fontSize: 12.sp,
              letterSpacing: 1.8,
              fontWeight: FontWeight.w700,
              color: Color(0xFF667585),
            ),
          ),
          sb(6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    CommonText(
                      AppStrings.reports,
                      style: TextStyle(
                        fontSize: 22.sp,
                        height: 1.08,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1C2125),
                      ),
                    ),
                    CommonText(
                      AppStrings.october2025Report,
                      style: TextStyle(
                        fontSize: 32.sp,
                        height: 1.08,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1C2125),
                      ),
                    ),
                  ],
                ),
              ),
              sbw(10),
              _ReportFilterDropdown(
                selected: _selectedFilter,
                onSelected: (String value) {
                  setState(() {
                    _selectedFilter = value;
                  });
                },
              ),
            ],
          ),
          sb(6),
          CommonText(
            AppStrings.generatedOnDate,
            style: TextStyle(
              fontSize: 12.sp,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6A798B),
            ),
          ),
          sb(18),
          const _MetricCard(
            title: AppStrings.totalSpend,
            value: AppStrings.reportTotalSpendAmount,
          ),
          sb(14),
          const _MetricCard(
            title: AppStrings.monthlyDelta,
            value: AppStrings.monthlyDeltaValue,
            valueColor: AppColors.red,
            subtitle: AppStrings.vsSeptember2023,
            trailingIcon: Icons.trending_down,
          ),
          sb(14),
          const _TopCategoryCard(),
          sb(20),
          const _SectionTitle(
            icon: Icons.auto_graph_rounded,
            title: AppStrings.categoryBreakdown,
          ),
          sb(12),
          const _CategoryBreakdownTable(),
          sb(20),
          const _SectionTitle(
            icon: Icons.storefront_outlined,
            title: AppStrings.top5Merchants,
          ),
          sb(12),
          const _MerchantTile(
            icon: Icons.shopping_cart_outlined,
            title: AppStrings.wholeFoods,
            subtitle: AppStrings.threeTransactions,
            amount: AppStrings.wholeFoodsAmount,
          ),
          sb(10),
          const _MerchantTile(
            icon: Icons.electric_bolt_outlined,
            title: AppStrings.conEdUtilities,
            subtitle: AppStrings.oneTransaction,
            amount: AppStrings.conEdAmount,
          ),
          sb(10),
          const _MerchantTile(
            icon: Icons.local_cafe_outlined,
            title: AppStrings.blueBottle,
            subtitle: AppStrings.twelveTransactions,
            amount: AppStrings.blueBottleAmount,
          ),
          sb(16),
          const Divider(height: 1, color: Color(0xFFDFE3E8)),
          sb(16),
          CustomButton(
            onButtonPressed: () {},
            buttonText: AppStrings.exportPdf,
            btnHeight: 54,
            borderRadius: 28,
            backgroundColor: AppColors.white,
            borderColor: AppColors.primary,
            borderWidth: 2,
            textColor: AppColors.primary,
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
          ),
          sb(10),
          CustomButton(
            onButtonPressed: () {},
            buttonText: AppStrings.shareReport,
            btnHeight: 54,
            borderRadius: 28,
            backgroundColor: AppColors.primary,
            textColor: AppColors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            showPrefixIcon: true,
            prefixIcon: Icon(
              Icons.share_outlined,
              color: AppColors.white,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportFilterDropdown extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _ReportFilterDropdown({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      initialValue: selected,
      onSelected: onSelected,
      color: AppColors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (BuildContext context) {
        const List<String> options = <String>[
          AppStrings.thisWeek,
          AppStrings.thisMonth,
          AppStrings.thisYear,
        ];

        return options
            .map(
              (String option) => PopupMenuItem<String>(
                value: option,
                child: CommonText(
                  option,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: option == selected
                        ? AppColors.primary
                        : const Color(0xFF4F5F72),
                  ),
                ),
              ),
            )
            .toList();
      },
      child: Container(
        height: 34,
        padding: EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE8EFEA),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: AppColors.primaryLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CommonText(
              selected,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            sbw(4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        sbw(8),
        CommonText(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: Color(0xFF252B30),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final Color? valueColor;
  final String? subtitle;
  final IconData? trailingIcon;

  const _MetricCard({
    required this.title,
    required this.value,
    this.valueColor,
    this.subtitle,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommonText(
            title,
            style: TextStyle(
              fontSize: 11.sp,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w700,
              color: Color(0xFF647589),
            ),
          ),
          sb(8),
          Row(
            children: [
              CommonText(
                value,
                style: TextStyle(
                  fontSize: 26.sp,
                  fontWeight: FontWeight.w800,
                  color: valueColor ?? const Color(0xFF1E2327),
                ),
              ),
              if (trailingIcon != null) ...[
                sbw(8),
                Icon(
                  trailingIcon,
                  size: 16,
                  color: valueColor ?? const Color(0xFF1E2327),
                ),
              ],
            ],
          ),
          if (subtitle != null) ...[
            sb(6),
            CommonText(
              subtitle,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: Color(0xFF667585),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TopCategoryCard extends StatelessWidget {
  const _TopCategoryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Container(width: 4, height: 124, color: AppColors.primary),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(14, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CommonText(
                    AppStrings.topCategory,
                    style: TextStyle(
                      fontSize: 11.sp,
                      letterSpacing: 1.6,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF647589),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  CommonText(
                    AppStrings.topCategoryHousing,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E2327),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  CommonText(
                    AppStrings.topCategoryShare,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF667585),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBreakdownTable extends StatelessWidget {
  const _CategoryBreakdownTable();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _CategoryHeaderRow(),
          _CategoryValueRow(
            dotColor: AppColors.primary,
            category: AppStrings.topCategoryHousing,
            amount: AppStrings.housingAmount,
            share: AppStrings.housingShare,
          ),
          _CategoryValueRow(
            dotColor: AppColors.primary,
            category: AppStrings.groceries,
            amount: AppStrings.groceriesAmount,
            share: AppStrings.groceriesShare,
          ),
          _CategoryValueRow(
            dotColor: Color(0xFF546378),
            category: AppStrings.diningOut,
            amount: AppStrings.diningOutAmount,
            share: AppStrings.diningOutShare,
          ),
          _CategoryValueRow(
            dotColor: Color(0xFF6E7A78),
            category: AppStrings.transport,
            amount: AppStrings.transportAmount,
            share: AppStrings.transportShare,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _CategoryHeaderRow extends StatelessWidget {
  const _CategoryHeaderRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF1F3F5),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: CommonText(
              AppStrings.categoryHeader,
              style: TextStyle(
                fontSize: 11.sp,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
                color: Color(0xFF67778A),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: CommonText(
              AppStrings.amountHeader,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11.sp,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
                color: Color(0xFF67778A),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: CommonText(
              AppStrings.shareHeader,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11.sp,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
                color: Color(0xFF67778A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryValueRow extends StatelessWidget {
  final Color dotColor;
  final String category;
  final String amount;
  final String share;
  final bool isLast;

  const _CategoryValueRow({
    required this.dotColor,
    required this.category,
    required this.amount,
    required this.share,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isLast ? AppColors.transparent : const Color(0xFFE8EDF1),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                sbw(10),
                Expanded(
                  child: CommonText(
                    category,
                    style: TextStyle(
                      fontSize: 15.sp,
                      height: 1.1,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2A2F33),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: CommonText(
              amount,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2A2F33),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: CommonText(
              share,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                color: Color(0xFF627488),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MerchantTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;

  const _MerchantTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 22, color: const Color(0xFF607182)),
          ),
          sbw(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CommonText(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2A2F33),
                  ),
                ),
                CommonText(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF738293),
                  ),
                ),
              ],
            ),
          ),
          CommonText(
            amount,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2A2F33),
            ),
          ),
        ],
      ),
    );
  }
}
