import 'package:flutter/material.dart';
import 'package:kharcha/components/common_text.dart';
import 'package:kharcha/utils/constants/app_colors.dart';

class CommonTagChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;
  final Color? textColor;
  final Color? backgroundColor;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const CommonTagChip({
    super.key,
    required this.icon,
    required this.label,
    this.iconColor,
    this.textColor,
    this.backgroundColor,
    this.borderRadius = 999,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Widget content = Container(
      padding:
          padding ?? EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.greyLight,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: iconColor ?? AppColors.greyDark),
          SizedBox(width: 8),
          CommonText(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textColor ?? AppColors.black,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;

    return GestureDetector(onTap: onTap, child: content);
  }
}