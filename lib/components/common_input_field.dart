import 'package:flutter/material.dart';
import 'package:kharcha/components/common_text.dart';
import 'package:kharcha/utils/constants/app_colors.dart';
import 'package:kharcha/utils/constants/app_sizes.dart';

class CommonInputField extends StatelessWidget {
  final String? labelText;
  final String? hintText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final String? Function(String?)? validator;

  final bool enabled;
  final bool readOnly;
  final bool obscureText;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final AutovalidateMode autovalidateMode;

  final double? width;
  final double? height;
  final double labelSpacing;
  final EdgeInsetsGeometry? contentPadding;

  final TextStyle? labelStyle;
  final TextStyle? hintStyle;
  final TextStyle? inputStyle;
  final TextStyle? errorStyle;

  final Color? cursorColor;
  final Color? backgroundColor;
  final Color? focusedBorderColor;
  final Color? enabledBorderColor;
  final Color? errorBorderColor;
  final Color? disabledBorderColor;
  final bool hasError;
  final String? errorMessage;

  final double borderRadius;
  final double borderWidth;
  final double focusedBorderWidth;
  final double errorBorderWidth;

  final Widget? prefix;
  final Widget? suffix;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixPressed;

  const CommonInputField({
    super.key,
    this.labelText,
    this.hintText,
    this.controller,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onFieldSubmitted,
    this.validator,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.width,
    this.height,
    this.labelSpacing = 6,
    this.contentPadding,
    this.labelStyle,
    this.hintStyle,
    this.inputStyle,
    this.errorStyle,
    this.cursorColor,
    this.backgroundColor,
    this.focusedBorderColor,
    this.enabledBorderColor,
    this.errorBorderColor,
    this.disabledBorderColor,
    this.hasError = false,
    this.errorMessage,
    this.borderRadius = 24,
    this.borderWidth = 1,
    this.focusedBorderWidth = 2,
    this.errorBorderWidth = 1.5,
    this.prefix,
    this.suffix,
    this.suffixIcon,
    this.onSuffixPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bool showManualError =
        hasError && (errorMessage?.trim().isNotEmpty ?? false);
    final Color resolvedErrorColor = errorBorderColor ?? AppColors.red;

    final InputBorder enabledBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(
        color: showManualError
            ? resolvedErrorColor
            : (enabledBorderColor ?? AppColors.grey),
        width: borderWidth,
      ),
    );

    final InputBorder focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(
        color: showManualError
            ? resolvedErrorColor
            : (focusedBorderColor ?? AppColors.primary),
        width: focusedBorderWidth,
      ),
    );

    final InputBorder errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(
        color: resolvedErrorColor,
        width: errorBorderWidth,
      ),
    );

    final Widget textField = TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      obscureText: obscureText,
      enabled: enabled,
      readOnly: readOnly,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      autovalidateMode: autovalidateMode,
      cursorColor: cursorColor ?? AppColors.primary,
      style: inputStyle ??
          TextStyle(
            fontSize: AppSizes.inputFontSize,
            fontWeight: FontWeight.w500,
            color: AppColors.black,
          ),
      decoration: InputDecoration(
        counterText: '',
        isDense: true,
        filled: true,
        fillColor: backgroundColor ?? AppColors.grey,
        hintText: hintText,
        hintStyle: hintStyle ??
            TextStyle(
              fontSize: AppSizes.inputFontSize,
              color: AppColors.greyDark,
              fontWeight: FontWeight.w400,
            ),
        contentPadding: contentPadding ??
            EdgeInsets.symmetric(
              vertical: AppSizes.verticalInputPadding,
              horizontal: AppSizes.horizontalInputPadding,
            ),
        prefixIcon: prefix,
        suffixIcon: suffix ??
            (suffixIcon != null
                ? IconButton(
                    onPressed: onSuffixPressed,
                    icon: Icon(suffixIcon, color: AppColors.greyDark, size: 24),
                  )
                : null),
        enabledBorder: enabledBorder,
        focusedBorder: focusedBorder,
        border: enabledBorder,
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: disabledBorderColor ?? AppColors.greyLight,
            width: borderWidth,
          ),
        ),
        errorBorder: errorBorder,
        focusedErrorBorder: errorBorder,
        errorStyle: errorStyle,
      ),
    );

    return SizedBox(
      width: width ?? double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (labelText != null && labelText!.trim().isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.only(left:8.0),
              child: CommonText(
                labelText,
                style: labelStyle ??
                    TextStyle(
                      fontSize: AppSizes.labelFontSize,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                      letterSpacing: 0.8,
                    ),
              ),
            ),
            SizedBox(height: labelSpacing),
          ],
          if (height != null)
            SizedBox(height: height, child: textField)
          else
            textField,
          if (showManualError)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: CommonText(
                errorMessage,
                style: errorStyle ??
                    TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: resolvedErrorColor,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}