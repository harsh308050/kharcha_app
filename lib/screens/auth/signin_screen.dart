import "package:flutter_screenutil/flutter_screenutil.dart";
import 'package:flutter/material.dart';
import 'package:kharcha/components/common_app_bar.dart';
import 'package:kharcha/components/common_button.dart';
import 'package:kharcha/components/common_input_field.dart';
import 'package:kharcha/components/common_text.dart';
import 'package:kharcha/screens/auth/signup_screen.dart';
import 'package:kharcha/screens/permisson/permission_screen.dart';
import 'package:kharcha/utils/constants/app_colors.dart';
import 'package:kharcha/utils/constants/app_icons.dart';
import 'package:kharcha/utils/constants/app_image.dart';
import 'package:kharcha/utils/constants/app_strings.dart';
import 'package:kharcha/utils/my_cm.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _isPasswordHidden = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteBg,
      appBar: CommonAppBar(
        onPrefixTap: () {
          Navigator.pop(context);
        },
        prefixIcon: AppIcons.arrowBackIos,
        appBarHorizontalPadding: 26,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: Image.asset(AppImage.logo, height: 80),
                ),
                sb(20),
                CommonText(
                  AppStrings.signinWithEmail,
                  style: TextStyle(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
                // sb(8),
                CommonText(
                  AppStrings.signinWithEmailDesc,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.greyDark,
                  ),
                ),
                sb(30),
                CommonInputField(
                  labelText: 'EMAIL ADDRESS',
                  hintText: 'name@example.com',
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) {
                    _passwordFocusNode.requestFocus();
                  },
                  backgroundColor: AppColors.grey,
                  cursorColor: AppColors.primary,
                  enabledBorderColor: AppColors.grey,
                  focusedBorderColor: AppColors.primary,
                  errorBorderColor: AppColors.red,
                  disabledBorderColor: AppColors.greyLight,
                  borderRadius: 100,
                  labelStyle: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: AppColors.black,
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
                sb(20),
                CommonInputField(
                  labelText: 'PASSWORD',
                  hintText: 'Enter your password',
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction: TextInputAction.done,
                  obscureText: _isPasswordHidden,
                  backgroundColor: AppColors.grey,
                  cursorColor: AppColors.primary,
                  enabledBorderColor: AppColors.grey,
                  focusedBorderColor: AppColors.primary,
                  errorBorderColor: AppColors.red,
                  disabledBorderColor: AppColors.greyLight,
                  borderRadius: 100,
                  labelStyle: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: AppColors.black,
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
                  suffixIcon: _isPasswordHidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  onSuffixPressed: () {
                    setState(() {
                      _isPasswordHidden = !_isPasswordHidden;
                    });
                  },
                ),
                sb(50),
                CustomButton(
                  onButtonPressed: () {
                    callNextScreenAndClearStack(context, PermissionScreen());
                  },
                  buttonText: AppStrings.signin,
                  fontSize: 20.sp,
                ),
                sb(50),
                Row(
                  mainAxisAlignment: .center,
                  children: [
                    CommonText(
                      AppStrings.donthaveanAccount,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.greyDark,
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        splashFactory: NoSplash.splashFactory,
                      ),
                      onPressed: () {
                        callNextScreen(context, SignupScreen());
                      },
                      child: CommonText(
                        AppStrings.createAccount,
                        textAlign: .center,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                sb(28),
                Row(
                  mainAxisAlignment: .center,
                  children: [
                    Icon(
                      AppIcons.lockOutline,
                      size: 22,
                      color: AppColors.primaryDark,
                    ),
                    sbw(10),
                    CommonText(
                      'End-to-End Encrypted Data',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.greyDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                sb(12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
