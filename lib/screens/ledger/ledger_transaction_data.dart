import 'package:flutter/material.dart';

class LedgerTransactionData {
  final String title;
  final String subtitle;
  final String amount;
  final Color amountColor;
  final String trailingText;
  final Color trailingTextColor;
  final Color trailingBackground;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final bool showAccent;
  final String category;
  final String note;
  final String dateTimeText;
  final String rawSms;

  const LedgerTransactionData({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.amountColor,
    required this.trailingText,
    required this.trailingTextColor,
    required this.trailingBackground,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.showAccent,
    required this.category,
    required this.note,
    required this.dateTimeText,
    required this.rawSms,
  });
}
