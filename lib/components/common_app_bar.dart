import 'package:flutter/material.dart';
import 'package:kharcha/components/common_text.dart';
import 'package:kharcha/utils/constants/app_colors.dart';

enum CommonAppBarTitleAlignment { center, start }

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final CommonAppBarTitleAlignment titleAlignment;

  final Color? backgroundColor;
  final double? elevation;
  final double toolbarHeight;
  final bool automaticallyImplyLeading;
  final bool isPrefixImageRound;
  final bool isSuffixImageRound;
  final Color? prefixImageBackgroundColor;
  final Color? suffixImageBackgroundColor;
  final double? prefixImageBorderRadius;
  final double? suffixImageBorderRadius;
  final Widget? prefix;
  final IconData? prefixIcon;
  final String? prefixImageAsset;
  final VoidCallback? onPrefixTap;
  final Color? prefixIconColor;
  final double? prefixIconSize;
  final double? prefixImageSize;
  final double? prefixImageWidth;
  final double? prefixImageHeight;
  final bool prefixTakesOneThirdWidth;
  final double appBarHorizontalPadding;
  final double appBarVerticalPadding;
  final double? leadingWidth;

  final Widget? suffix;
  final IconData? suffixIcon;
  final String? suffixImageAsset;
  final VoidCallback? onSuffixTap;
  final Color? suffixIconColor;
  final double? suffixIconSize;
  final double? suffixImageSize;

  final List<Widget>? actions;

  const CommonAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.titleAlignment = CommonAppBarTitleAlignment.center,
    this.backgroundColor,
    this.elevation,
    this.toolbarHeight = 56.0,
    this.automaticallyImplyLeading = false,
    this.isPrefixImageRound = false,
    this.isSuffixImageRound = false,
    this.prefixImageBackgroundColor,
    this.suffixImageBackgroundColor,
    this.prefixImageBorderRadius,
    this.suffixImageBorderRadius,
    this.prefix,
    this.prefixIcon,
    this.prefixImageAsset,
    this.onPrefixTap,
    this.prefixIconColor,
    this.prefixIconSize,
    this.prefixImageSize,
    this.prefixImageWidth,
    this.prefixImageHeight,
    this.prefixTakesOneThirdWidth = false,
    this.appBarHorizontalPadding = 16,
    this.appBarVerticalPadding = 0,
    this.leadingWidth,
    this.suffix,
    this.suffixIcon,
    this.suffixImageAsset,
    this.onSuffixTap,
    this.suffixIconColor,
    this.suffixIconSize,
    this.suffixImageSize,
    this.actions,
  });

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight);

  @override
  Widget build(BuildContext context) {
    final Widget? effectiveLeading = _buildLeading();
    final List<Widget>? effectiveActions = actions ?? _buildActions();
    final Widget? effectiveTitle = _buildTitle();

    final Widget? paddedLeading = effectiveLeading == null
        ? null
        : Padding(
            padding: EdgeInsets.symmetric(
              horizontal: appBarHorizontalPadding,
              vertical: appBarVerticalPadding,
            ),
            child: effectiveLeading,
          );

    final Widget? paddedTitle = effectiveTitle == null
        ? null
        : Padding(
            padding: EdgeInsets.symmetric(
              horizontal: appBarHorizontalPadding,
              vertical: appBarVerticalPadding,
            ),
            child: effectiveTitle,
          );

    final List<Widget>? paddedActions = effectiveActions
        ?.map(
          (Widget action) => Padding(
            padding: EdgeInsets.symmetric(
              horizontal: appBarHorizontalPadding,
              vertical: appBarVerticalPadding,
            ),
            child: action,
          ),
        )
        .toList();

    return AppBar(
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: backgroundColor ?? AppColors.whiteBg,
      elevation: elevation ?? 0,
      toolbarHeight: toolbarHeight,
      scrolledUnderElevation: 0,
      centerTitle: titleAlignment == CommonAppBarTitleAlignment.center,
      titleSpacing: titleAlignment == CommonAppBarTitleAlignment.start ? 0 : null,
      leadingWidth: leadingWidth ?? _resolveLeadingWidth(context),
      leading: paddedLeading,
      title: paddedTitle,
      actions: paddedActions,
    );
  }

  Widget? _buildTitle() {
    if (titleWidget != null) return titleWidget;
    if (title == null || title!.trim().isEmpty) return null;

    return CommonText(
      title,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.black,
      ),
    );
  }

  double? _resolveLeadingWidth(BuildContext context) {
    if (prefixIcon != null) {
      final double iconVisualSize = prefixIconSize ?? 24;
      // IconButton has a minimum tap target close to 48 logical pixels.
      final double tapTarget = iconVisualSize < 48 ? 48 : iconVisualSize;
      return tapTarget + (appBarHorizontalPadding * 2);
    }

    if (prefixImageAsset == null) return null;
    if (prefixTakesOneThirdWidth) {
      return MediaQuery.sizeOf(context).width / 3;
    }
    final double imageWidth = prefixImageWidth ?? prefixImageSize ?? 24;
    return imageWidth + (appBarHorizontalPadding * 2);
  }

  Widget? _buildLeading() {
    if (prefix != null) return prefix;

    if (prefixIcon != null) {
      return _buildIconOrImage(
        prefixIcon,
        onTap: onPrefixTap,
        iconColor: prefixIconColor,
        iconSize: prefixIconSize,
      );
    }

    if (prefixImageAsset != null) {
      final double imageWidth = prefixTakesOneThirdWidth
          ? double.infinity
          : (prefixImageWidth ?? prefixImageSize ?? 24);
      final double imageHeight = prefixImageHeight ?? prefixImageSize ?? (toolbarHeight - 8);
      final Widget image = _buildIconOrImage(
        null,
        imageAsset: prefixImageAsset,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
        onTap: onPrefixTap,
        isImageRound: isPrefixImageRound,
        imageBackgroundColor: prefixImageBackgroundColor,
        imageBorderRadius: prefixImageBorderRadius,
      );

      return Align(alignment: Alignment.centerLeft, child: image);
    }

    return null;
  }

  List<Widget>? _buildActions() {
    if (suffix != null) {
      return [suffix!, SizedBox(width: 8)];
    }

    if (suffixIcon != null) {
      return [
        Center(
          child: _buildIconOrImage(
            suffixIcon,
            onTap: onSuffixTap,
            iconColor: suffixIconColor,
            iconSize: suffixIconSize,
          ),
        ),
        if (onSuffixTap != null) SizedBox(width: 8),
      ];
    }

    if (suffixImageAsset != null) {
      return [
        Center(
          child: _buildIconOrImage(
            null,
            imageAsset: suffixImageAsset,
            imageWidth: suffixImageSize ?? 24,
            imageHeight: suffixImageSize ?? 24,
            onTap: onSuffixTap,
            isImageRound: isSuffixImageRound,
            imageBackgroundColor: suffixImageBackgroundColor,
            imageBorderRadius: suffixImageBorderRadius,
          ),
        ),
        if (onSuffixTap != null) SizedBox(width: 8),
      ];
    }

    return null;
  }

  Widget _buildIconOrImage(
    IconData? icon, {
    String? imageAsset,
    double? imageWidth,
    double? imageHeight,
    VoidCallback? onTap,
    Color? iconColor,
    double? iconSize,
    bool isImageRound = false,
    Color? imageBackgroundColor,
    double? imageBorderRadius,
  }) {
    if (icon != null) {
      final Widget iconWidget = Icon(
        icon,
        color: iconColor ?? AppColors.black,
        size: iconSize,
      );

      if (onTap == null) return iconWidget;

      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(child: iconWidget),
        ),
      );
    }

    final double resolvedRadius =
        isImageRound ? 999 : (imageBorderRadius ?? 0);

    final Widget imageWidget = ClipRRect(
      borderRadius: BorderRadius.circular(resolvedRadius),
      child: Container(
        color: imageBackgroundColor,
        child: Image.asset(
          imageAsset!,
          width: imageWidth,
          height: imageHeight,
          fit: BoxFit.fitWidth,
        ),
      ),
    );

    if (onTap == null) return imageWidget;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: imageWidget,
    );
  }
}
