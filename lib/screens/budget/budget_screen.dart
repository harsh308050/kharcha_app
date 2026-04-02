import "package:flutter_screenutil/flutter_screenutil.dart";
import 'package:flutter/material.dart';
import 'dart:math';

import 'package:kharcha/components/common_button.dart';
import 'package:kharcha/components/common_text.dart';
import 'package:kharcha/utils/constants/app_colors.dart';
import 'package:kharcha/utils/constants/app_strings.dart';
import 'package:kharcha/utils/my_cm.dart';

class BudgetTabScreen extends StatefulWidget {
  const BudgetTabScreen({super.key});

  @override
  State<BudgetTabScreen> createState() => BudgetTabScreenState();
}

class BudgetTabScreenState extends State<BudgetTabScreen> {
  final Random _random = Random();

  final List<IconData> _iconPool = const <IconData>[
    Icons.restaurant,
    Icons.shopping_bag_outlined,
    Icons.electric_bolt,
    Icons.directions_car_filled_outlined,
    Icons.local_hospital_outlined,
    Icons.school_outlined,
    Icons.home_outlined,
    Icons.movie_outlined,
  ];

  final List<Color> _themePool = const <Color>[
    Color(0xFF13795B),
    Color(0xFFEA580C),
    Color(0xFFC71F1F),
    Color(0xFF0E7490),
    Color(0xFF7C3AED),
    Color(0xFF2563EB),
  ];

  final List<BudgetCategoryData> _categories = <BudgetCategoryData>[
    const BudgetCategoryData(
      name: 'Dining & Food',
      spent: 340,
      limit: 800,
      icon: Icons.restaurant,
      themeColor: Color(0xFF13795B),
    ),
    const BudgetCategoryData(
      name: 'Shopping',
      spent: 1120,
      limit: 1300,
      icon: Icons.shopping_bag_outlined,
      themeColor: Color(0xFFEA580C),
    ),
    const BudgetCategoryData(
      name: 'Utilities',
      spent: 485,
      limit: 500,
      icon: Icons.electric_bolt,
      themeColor: Color(0xFFC71F1F),
    ),
    const BudgetCategoryData(
      name: AppStrings.transport,
      spent: 225,
      limit: 600,
      icon: Icons.directions_car_filled_outlined,
      themeColor: Color(0xFF13795B),
    ),
  ];

  Future<void> _showAddCategorySheet() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController spentController = TextEditingController();
    final TextEditingController limitController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommonText(
                AppStrings.addNewCategory,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D2227),
                ),
              ),
              sb(12),
              _BudgetInputField(
                controller: nameController,
                hint: 'Category name',
              ),
              sb(10),
              Row(
                children: [
                  Expanded(
                    child: _BudgetInputField(
                      controller: spentController,
                      hint: 'Spent',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  sbw(10),
                  Expanded(
                    child: _BudgetInputField(
                      controller: limitController,
                      hint: 'Limit',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              sb(14),
              CustomButton(
                onButtonPressed: () {
                  final String name = nameController.text.trim();
                  final double? spent = double.tryParse(
                    spentController.text.trim(),
                  );
                  final double? limit = double.tryParse(
                    limitController.text.trim(),
                  );

                  if (name.isEmpty ||
                      spent == null ||
                      limit == null ||
                      limit <= 0) {
                    showSnackBar(
                      context,
                      'Please enter valid values',
                      AppColors.red,
                    );
                    return;
                  }

                  setState(() {
                    _categories.add(
                      BudgetCategoryData(
                        name: name,
                        spent: spent,
                        limit: limit,
                        icon: _iconPool[_random.nextInt(_iconPool.length)],
                        themeColor:
                            _themePool[_random.nextInt(_themePool.length)],
                      ),
                    );
                  });

                  Navigator.pop(context);
                },
                buttonText: AppStrings.addNewCategory,
                //btn height
                btnHeight: 48,
                borderRadius: 14,
                backgroundColor: AppColors.primary,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double totalLimit = _categories.fold<double>(
      0,
      (p, e) => p + e.limit,
    );
    final double totalSpent = _categories.fold<double>(
      0,
      (p, e) => p + e.spent,
    );
    final double remaining = (totalLimit - totalSpent).clamp(
      0,
      double.infinity,
    );
    final double progress = totalLimit <= 0
        ? 0
        : (totalSpent / totalLimit).clamp(0, 1);

    return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 20),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MonthlyOverviewCard(
            totalLimit: totalLimit,
            totalSpent: totalSpent,
            remaining: remaining,
            progress: progress,
          ),
          sb(30),
          Column(
            crossAxisAlignment: .start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CommonText(
                      AppStrings.budgetTitle,
                      style: TextStyle(
                        fontSize: 28.sp,
                        height: 1.02,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F252A),
                      ),
                    ),
                  ),
                  sbw(12),
                  SizedBox(
                    width: 140.w,
                    child: CustomButton(
                      onButtonPressed: _showAddCategorySheet,
                      buttonText: AppStrings.newBudget,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              CommonText(
                AppStrings.budgetDesc,
                style: TextStyle(
                  fontSize: 12.sp,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF667585),
                ),
              ),
            ],
          ),
          sb(14),
          ..._categories.map(
            (BudgetCategoryData item) => Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: _BudgetCategoryCard(
                data: item,
                onEditTap: _showAddCategorySheet,
              ),
            ),
          ),
          _AddCategoryCard(onTap: _showAddCategorySheet),
        ],
      ),
    );
  }
}

class _MonthlyOverviewCard extends StatelessWidget {
  final double totalLimit;
  final double totalSpent;
  final double remaining;
  final double progress;

  const _MonthlyOverviewCard({
    required this.totalLimit,
    required this.totalSpent,
    required this.remaining,
    required this.progress,
  });

  String _fmt(double value) => '₹${value.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF137B69), Color(0xFF1D8B78)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommonText(
            AppStrings.monthlyOverview,
            style: TextStyle(
              fontSize: 13.sp,
              letterSpacing: 1.8,
              fontWeight: FontWeight.w700,
              color: Color(0xFFD5F1EA),
            ),
          ),
          sb(8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: CommonText(
                  _fmt(totalLimit),
                  style: TextStyle(
                    fontSize: 38.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CommonText(
                      AppStrings.remaining,
                      style: TextStyle(
                        fontSize: 11.sp,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFCDEDE5),
                      ),
                    ),
                    CommonText(
                      _fmt(remaining),
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          sb(2),
          CommonText(
            AppStrings.totalBudgetLimit,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Color(0xFFCDEDE5),
            ),
          ),
          sb(12),
          Row(
            children: [
              CommonText(
                '${AppStrings.spentPrefix} ${_fmt(totalSpent)}',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
              const Spacer(),
              CommonText(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFD5F1EA),
                ),
              ),
            ],
          ),
          sb(8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: progress,
              backgroundColor: AppColors.black.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetCategoryCard extends StatelessWidget {
  final BudgetCategoryData data;
  final VoidCallback onEditTap;

  const _BudgetCategoryCard({required this.data, required this.onEditTap});

  @override
  Widget build(BuildContext context) {
    final double ratio = data.limit <= 0
        ? 0
        : (data.spent / data.limit).clamp(0, 1);
    final String status = ratio >= 0.95
        ? AppStrings.criticalLevel
        : ratio >= 0.8
        ? AppStrings.approachingLimit
        : AppStrings.withinLimit;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: data.themeColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(data.icon, size: 22, color: data.themeColor),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onEditTap,
                child: Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: Color(0xFF617284),
                ),
              ),
            ],
          ),
          sb(14),
          CommonText(
            data.name,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F252A),
            ),
          ),
          sb(4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CommonText(
                '\$${data.spent.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                  color: ratio >= 0.95
                      ? AppColors.red
                      : const Color(0xFF1E2328),
                ),
              ),
              const Spacer(),
              CommonText(
                'of \$${data.limit.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6A798B),
                ),
              ),
            ],
          ),
          sb(8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: const Color(0xFFE8EDF1),
              valueColor: AlwaysStoppedAnimation<Color>(data.themeColor),
            ),
          ),
          sb(8),
          Row(
            children: [
              CommonText(
                status.toUpperCase(),
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: data.themeColor,
                ),
              ),
              const Spacer(),
              CommonText(
                '${(ratio * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF657689),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddCategoryCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddCategoryCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD0D7DE), width: 1.5),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Color(0xFFF4F6F8),
              child: Icon(Icons.add, size: 24, color: Color(0xFF9AA7B5)),
            ),
            SizedBox(height: 12.h),
            CommonText(
              AppStrings.addNewCategoryTitle,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: Color(0xFF646E77),
              ),
            ),
            SizedBox(height: 4.h),
            CommonText(
              AppStrings.addNewCategorySub,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                color: Color(0xFFA3AFBC),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;

  const _BudgetInputField({
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFF3F5F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class BudgetCategoryData {
  final String name;
  final double spent;
  final double limit;
  final IconData icon;
  final Color themeColor;

  const BudgetCategoryData({
    required this.name,
    required this.spent,
    required this.limit,
    required this.icon,
    required this.themeColor,
  });
}
