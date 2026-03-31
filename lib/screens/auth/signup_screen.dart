import "package:flutter_screenutil/flutter_screenutil.dart";
import 'package:flutter/material.dart';
import 'package:kharcha/components/common_app_bar.dart';
import 'package:kharcha/components/common_button.dart';
import 'package:kharcha/components/common_input_field.dart';
import 'package:kharcha/components/common_text.dart';
import 'package:kharcha/screens/permisson/permission_screen.dart';
import 'package:kharcha/utils/constants/app_colors.dart';
import 'package:kharcha/utils/constants/app_icons.dart';
import 'package:kharcha/utils/constants/app_image.dart';
import 'package:kharcha/utils/constants/app_strings.dart';
import 'package:kharcha/utils/my_cm.dart';

class SignupScreen extends StatefulWidget {
  final bool isEditMode;
  final String? initialName;
  final String? initialEmail;

  const SignupScreen({
    super.key,
    this.isEditMode = false,
    this.initialName,
    this.initialEmail,
  });

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _fullNameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _isPasswordHidden = true;

  @override
  void initState() {
    super.initState();
    _fullNameController.text = widget.initialName ?? '';
    _emailController.text = widget.initialEmail ?? '';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteBg,
      appBar: CommonAppBar(
        onPrefixTap: () => Navigator.pop(context),
        prefixIcon: AppIcons.arrowBackIos,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: Image.asset(AppImage.logo, height: 100),
                ),
              ),
              sb(24),
              Center(
                child: CommonText(
                  widget.isEditMode ? AppStrings.editProfile : AppStrings.createYourSpace,
                  style: TextStyle(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                    height: 1.05,
                  ),
                ),
              ),
              sb(6),
              Center(
                child: CommonText(
                  widget.isEditMode
                      ? AppStrings.updateYourProfile
                      : AppStrings.createYourSpaceSubtitle,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.greyDark,
                  ),
                ),
              ),
              sb(25.sp),
              CommonInputField(
                labelText: AppStrings.fullName,
                hintText: 'Type Here...',
                controller: _fullNameController,
                focusNode: _fullNameFocusNode,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                backgroundColor: AppColors.grey,
                enabledBorderColor: AppColors.grey,
                focusedBorderColor: AppColors.primary,
                borderRadius: 999,
                labelStyle: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.greyDark,
                  letterSpacing: 1.6,
                ),
                hintStyle: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.greyDark,
                ),
                inputStyle: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.black,
                ),
              ),
              sb(18),
              CommonInputField(
                labelText: AppStrings.emailAddress,
                hintText: 'name@example.com',
                controller: _emailController,
                focusNode: _emailFocusNode,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                backgroundColor: AppColors.grey,
                enabledBorderColor: AppColors.grey,
                focusedBorderColor: AppColors.primary,
                borderRadius: 999,
                labelStyle: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.greyDark,
                  letterSpacing: 1.6,
                ),
                hintStyle: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.greyDark,
                ),
                inputStyle: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.black,
                ),
                suffixIcon: AppIcons.mail,
              ),
              sb(18),
              CommonInputField(
                labelText: AppStrings.password,
                hintText: 'Enter your password',
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                keyboardType: TextInputType.visiblePassword,
                textInputAction: TextInputAction.done,
                obscureText: _isPasswordHidden,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                backgroundColor: AppColors.grey,
                enabledBorderColor: AppColors.grey,
                focusedBorderColor: AppColors.primary,
                borderRadius: 999,
                labelStyle: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.greyDark,
                  letterSpacing: 1.6,
                ),
                hintStyle: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.greyDark,
                ),
                inputStyle: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.black,
                ),
                suffixIcon:
                    _isPasswordHidden ? AppIcons.visibilityOff : AppIcons.visibility,
                onSuffixPressed: () {
                  setState(() {
                    _isPasswordHidden = !_isPasswordHidden;
                  });
                },
              ),
              sb(28),
              CustomButton(
                onButtonPressed: () {
                  if (widget.isEditMode) {
                    showSnackBar(context, 'Profile updated successfully', AppColors.primary);
                    Navigator.pop(context);
                  } else {
                    callNextScreenAndClearStack(context, PermissionScreen());
                  }
                },
                buttonText: widget.isEditMode ? AppStrings.saveProfile : AppStrings.createAccount,
                btnHeight: 58,
                borderRadius: 999,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                showTrailingIcon: true,
                trailingIcon: Icon(
                  AppIcons.arrowForwardIos,
                  size: 18,
                  color: AppColors.white,
                ),
              ),
              sb(22),
              if (!widget.isEditMode) ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.greyLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        AppIcons.shieldOutlined,
                        color: AppColors.primaryDark,
                        size: 20,
                      ),
                      sbw(12),
                      Expanded(
                        child: CommonText(
                          AppStrings.encryptedAndSecure,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.greyDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                sb(28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CommonText(
                      AppStrings.alreadyHaveAccount,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.greyDark,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        splashFactory: NoSplash.splashFactory,
                      ),
                      child: CommonText(
                        AppStrings.signin,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
