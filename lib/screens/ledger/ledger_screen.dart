import "package:flutter_screenutil/flutter_screenutil.dart";
import 'package:flutter/material.dart';
import 'package:kharcha/components/common_text.dart';
import 'package:kharcha/screens/ledger/ledger_transaction_data.dart';
import 'package:kharcha/screens/ledger/transaction_detail_screen.dart';
import 'package:kharcha/utils/constants/app_colors.dart';
import 'package:kharcha/utils/constants/app_strings.dart';
import 'package:kharcha/utils/my_cm.dart';

class LedgerTabScreen extends StatefulWidget {
  const LedgerTabScreen({super.key});

  @override
  State<LedgerTabScreen> createState() => LedgerTabScreenState();
}

class LedgerTabScreenState extends State<LedgerTabScreen> {
  static const List<LedgerTransactionData>
  _todayTransactions = <LedgerTransactionData>[
    LedgerTransactionData(
      title: 'Whole Foods Market',
      subtitle: 'HDFC BANK • 2H AGO',
      amount: '-\₹84.20',
      amountColor: Color(0xFF1F2529),
      trailingText: AppStrings.tagNow,
      trailingTextColor: AppColors.primary,
      trailingBackground: AppColors.transparent,
      icon: Icons.shopping_bag_outlined,
      iconColor: Color(0xFF52606D),
      iconBackground: Color(0xFFE9EAEB),
      showAccent: true,
      category: 'Groceries',
      note: 'Weekly groceries and essentials',
      dateTimeText: 'Oct 24, 2023 • 11:42 AM',
      rawSms:
          'Txn of INR 84.20 on HDFC Bank Card XX1234 at Whole Foods on 24-Oct-23. Avl Bal: INR 42,400.32.',
    ),
    LedgerTransactionData(
      title: 'Blue Tokai Coffee',
      subtitle: 'ICICI BANK • 5H AGO',
      amount: '-\₹12.50',
      amountColor: Color(0xFF1F2529),
      trailingText: AppStrings.dining,
      trailingTextColor: Color(0xFF5C6470),
      trailingBackground: Color(0xFFE9ECEF),
      icon: Icons.restaurant,
      iconColor: AppColors.primary,
      iconBackground: Color(0xFFD6E6E0),
      showAccent: false,
      category: 'Food & Drinks',
      note: 'Coffee with team after standup',
      dateTimeText: 'Oct 24, 2023 • 09:35 AM',
      rawSms:
          'Txn of INR 12.50 on ICICI Bank Card XX9981 at BlueTokai on 24-Oct-23. Avl Bal: INR 18,290.11.',
    ),
  ];

  static const List<LedgerTransactionData>
  _yesterdayTransactions = <LedgerTransactionData>[
    LedgerTransactionData(
      title: 'Tata Power Bills',
      subtitle: 'SBI CARD • 1D AGO',
      amount: '-\₹156.00',
      amountColor: Color(0xFF1F2529),
      trailingText: AppStrings.tagNow,
      trailingTextColor: AppColors.primary,
      trailingBackground: AppColors.transparent,
      icon: Icons.electric_bolt,
      iconColor: Color(0xFF52606D),
      iconBackground: Color(0xFFE9EAEB),
      showAccent: true,
      category: 'Utilities',
      note: 'Monthly electricity bill payment',
      dateTimeText: 'Oct 23, 2023 • 07:10 PM',
      rawSms:
          'Txn of INR 156.00 on SBI Card XX2110 at TataPower on 23-Oct-23. Avl Bal: INR 9,521.67.',
    ),
    LedgerTransactionData(
      title: 'Payroll Deposit',
      subtitle: 'HDFC BANK • 1D AGO',
      amount: '+\₹4,200.00',
      amountColor: AppColors.primary,
      trailingText: AppStrings.salary,
      trailingTextColor: AppColors.primary,
      trailingBackground: Color(0xFFD8EBE4),
      icon: Icons.account_balance_wallet_outlined,
      iconColor: AppColors.primary,
      iconBackground: Color(0xFFD6E6E0),
      showAccent: false,
      category: 'Income',
      note: 'Salary credited for October',
      dateTimeText: 'Oct 23, 2023 • 10:01 AM',
      rawSms:
          'Salary credit of INR 4,200.00 in HDFC A/C XX1234 on 23-Oct-23. Avl Bal: INR 52,774.92.',
    ),
    LedgerTransactionData(
      title: 'Uber India',
      subtitle: 'ICICI BANK • 1D AGO',
      amount: '-\₹14.20',
      amountColor: Color(0xFF1F2529),
      trailingText: AppStrings.transport,
      trailingTextColor: Color(0xFF5C6470),
      trailingBackground: Color(0xFFE9ECEF),
      icon: Icons.directions_car_filled_outlined,
      iconColor: Color(0xFF52606D),
      iconBackground: Color(0xFFE9EAEB),
      showAccent: false,
      category: 'Transport',
      note: 'Ride from office to home',
      dateTimeText: 'Oct 23, 2023 • 08:46 PM',
      rawSms:
          'Txn of INR 14.20 on ICICI Bank Card XX9981 at Uber on 23-Oct-23. Avl Bal: INR 18,201.94.',
    ),
  ];

  int _selectedFilterIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommonText(
            AppStrings.activity,
            style: TextStyle(
              fontSize: 14.sp,
              letterSpacing: 2.0,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6C727A),
            ),
          ),
          sb(4),
          CommonText(
            AppStrings.transactions,
            style: TextStyle(
              fontSize: 36.sp,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B2023),
            ),
          ),
          sb(12),
          Row(
            children: List<Widget>.generate(_filters.length, (int index) {
              final bool isSelected = index == _selectedFilterIndex;
              return Padding(
                padding: EdgeInsets.only(
                  right: index == _filters.length - 1 ? 0 : 10,
                ),
                child: _FilterPill(
                  label: _filters[index],
                  isSelected: isSelected,
                  showDropDown: index == 0,
                  onTap: () {
                    setState(() {
                      _selectedFilterIndex = index;
                    });
                  },
                ),
              );
            }),
          ),
          sb(18),
          const _LedgerSectionTitle(title: AppStrings.today),
          sb(10),
          ..._todayTransactions.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: _TransactionTile(data: item),
            ),
          ),
          sb(10),
          const _LedgerSectionTitle(title: AppStrings.yesterday),
          sb(10),
          ..._yesterdayTransactions.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: _TransactionTile(data: item),
            ),
          ),
        ],
      ),
    );
  }

  List<String> get _filters => <String>[
    AppStrings.date,
    AppStrings.today,
    AppStrings.thisWeek,
  ];
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool showDropDown;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.showDropDown,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFE8E8E8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            CommonText(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.white : AppColors.greyDark,
              ),
            ),
            if (showDropDown) ...[
              sbw(6),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: isSelected ? AppColors.white : AppColors.greyDark,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LedgerSectionTitle extends StatelessWidget {
  final String title;

  const _LedgerSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 8),
      child: CommonText(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 14.sp,
          letterSpacing: 2.0,
          fontWeight: FontWeight.w700,
          color: Color(0xFF73797D),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final LedgerTransactionData data;

  const _TransactionTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        callNextScreen(context, TransactionDetailScreen(transaction: data));
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            children: [
              data.showAccent
                  ? Container(width: 4, color: AppColors.yellow)
                  : SizedBox(width: 4.w),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12, 14, 14, 14),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: data.iconBackground,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(data.icon, color: data.iconColor, size: 24),
                      ),
                      sbw(12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CommonText(
                              data.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1F2427),
                              ),
                            ),
                            sb(2),
                            CommonText(
                              data.subtitle,
                              style: TextStyle(
                                fontSize: 11.sp,
                                letterSpacing: 1.0,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF55657A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      sbw(10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          CommonText(
                            data.amount,
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              color: data.amountColor,
                            ),
                          ),
                          sb(4),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: data.trailingBackground,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: CommonText(
                              data.trailingText,
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w700,
                                color: data.trailingTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
