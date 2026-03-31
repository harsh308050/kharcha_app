import 'package:flutter/material.dart';
import 'package:kharcha/components/common_loader.dart';
import 'package:kharcha/utils/anim/wave_dots.dart';
import 'package:kharcha/utils/constants/app_colors.dart';
import 'package:kharcha/utils/constants/app_icons.dart';
import 'package:kharcha/utils/constants/app_sizes.dart';

enum ButtonLoaderType { circular, waveDots }

class CustomButton extends StatelessWidget {
  final VoidCallback onButtonPressed;
  final String buttonText;
  final bool isLoading;
  final ButtonLoaderType loaderType;

  // Option 1: Single solid color
  final Color? backgroundColor;
  
  // Option 2: Gradient colors
  final List<Color>? gradientColors;
  final AlignmentGeometry? gradientBegin;
  final AlignmentGeometry? gradientEnd;
  
  // Border
  final Color? borderColor;
  final double? borderWidth;
  
  // Dimensions
  final double? btnWidth;
  final double? btnHeight;
  
  // Icons
  final Widget? prefixIcon;
  final Widget? trailingIcon;
  final String? prefixImageAsset;
  final String? trailingImageAsset;
  final double? prefixImageSize;
  final double? trailingImageSize;
  final bool showPrefixIcon;
  final bool showTrailingIcon;
  final Color? iconColor;
  final double? iconSize;
  
  // Text
  final Color? textColor;
  final double? fontSize;
  final FontWeight? fontWeight;
  
  // Border Radius
  final double? borderRadius;

  const CustomButton({
    super.key,
    required this.onButtonPressed,
    required this.buttonText,
    this.isLoading = false,
    this.loaderType = ButtonLoaderType.waveDots,
    // Background options (choose one):
    this.backgroundColor,
    this.gradientColors,
    this.gradientBegin,
    this.gradientEnd,
    // Border
    this.borderColor,
    this.borderWidth,
    // Dimensions
    this.btnWidth,
    this.btnHeight,
    // Icons
    this.prefixIcon,
    this.trailingIcon,
    this.prefixImageAsset,
    this.trailingImageAsset,
    this.prefixImageSize,
    this.trailingImageSize,
    this.showPrefixIcon = false,
    this.showTrailingIcon = false,
    this.iconColor,
    this.iconSize,
    // Text
    this.textColor,
    this.fontSize,
    this.fontWeight,
    // Shape
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    // Determine background type based on what user provided
    final bool useGradient = gradientColors != null && gradientColors!.isNotEmpty;
    // final bool useSolidColor = backgroundColor != null;
    
    // Default fallback color if neither provided
    final Color effectiveBackgroundColor = 
        backgroundColor ?? AppColors.primary;
    
    final Color effectiveTextColor = textColor ?? AppColors.white;
    final Color effectiveIconColor = iconColor ?? effectiveTextColor;
    final double effectiveIconSize = iconSize ?? 24.0;
    final double effectiveBorderRadius = borderRadius ?? AppSizes.btnHeight / 2;

    // Prefix/suffix precedence: explicit widget > image asset > default icon.
    final Widget effectivePrefixIcon =
        prefixIcon ??
        (prefixImageAsset != null
            ? Image.asset(
                prefixImageAsset!,
                width: prefixImageSize ?? effectiveIconSize,
                height: prefixImageSize ?? effectiveIconSize,
                fit: BoxFit.contain,
              )
            : Icon(
                AppIcons.arrowBack,
                color: effectiveIconColor,
                size: effectiveIconSize,
              ));

    final Widget effectiveTrailingIcon =
        trailingIcon ??
        (trailingImageAsset != null
            ? Image.asset(
                trailingImageAsset!,
                width: trailingImageSize ?? effectiveIconSize,
                height: trailingImageSize ?? effectiveIconSize,
                fit: BoxFit.contain,
              )
            : Icon(
                AppIcons.arrowForward,
                color: effectiveIconColor,
                size: effectiveIconSize,
              ));

    // Button content
    Widget buttonChild = isLoading
        ? Transform.scale(
            scale: 0.7,
            child: loaderType == ButtonLoaderType.waveDots
                ? WaveDots(size: 55, color: effectiveTextColor)
                : CustomLoader(color: effectiveTextColor),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Prefix Icon
              if (showPrefixIcon && !isLoading) ...[
                effectivePrefixIcon,
                SizedBox(width: 8),
              ],
              
              // Text
              Text(
                buttonText,
                style: TextStyle(
                  fontSize: fontSize ?? AppSizes.btnFontSize,
                  fontWeight: fontWeight ?? FontWeight.bold,
                  color: effectiveTextColor,
                ),
              ),
              
              // Trailing Icon
              if (showTrailingIcon && !isLoading) ...[
                SizedBox(width: 8),
                effectiveTrailingIcon,
              ],
            ],
          );

    // Build the button container with optional gradient decoration
    Widget buildButton() {
      return Container(
        width: btnWidth ?? double.infinity,
        height: btnHeight ?? AppSizes.btnHeight,
        decoration: useGradient
            ? BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors!,
                  begin: gradientBegin ?? Alignment.centerLeft,
                  end: gradientEnd ?? Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(effectiveBorderRadius),
                border: borderColor != null && borderWidth != null
                    ? Border.all(color: borderColor!, width: borderWidth!)
                    : null,
              )
            : null,
        child: ElevatedButton(
          onPressed: onButtonPressed,
          style: ElevatedButton.styleFrom(
            // If using gradient, button background must be transparent
            backgroundColor: useGradient 
                ? Colors.transparent 
                : effectiveBackgroundColor,
            foregroundColor: effectiveTextColor,
            elevation: useGradient ? 0 : null,
            padding: EdgeInsets.symmetric(horizontal: 24),
            minimumSize: Size(
              btnWidth ?? double.infinity, 
              btnHeight ?? AppSizes.btnHeight,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(effectiveBorderRadius),
              side: borderColor != null
                  ? BorderSide(color: borderColor!, width: borderWidth ?? 1.0)
                  : BorderSide.none,
            ),
          ),
          child: buttonChild,
        ),
      );
    }

    return IgnorePointer(ignoring: isLoading, child: buildButton());
  }
}