import "package:flutter_screenutil/flutter_screenutil.dart";
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kharcha/components/common_app_bar.dart';
import 'package:kharcha/components/common_button.dart';
import 'package:kharcha/components/common_input_field.dart';
import 'package:kharcha/components/common_text.dart';
import 'package:kharcha/screens/auth/bloc/auth_bloc.dart';
import 'package:kharcha/screens/auth/bloc/auth_event.dart';
import 'package:kharcha/screens/auth/bloc/auth_state.dart';
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
  String? _emailInlineError;
  String? _passwordInlineError;
  bool _isPasswordHidden = true;
  bool _suppressNextVerificationMessage = false;
  bool _isVerificationDialogOpen = false;

  static final RegExp _emailPattern = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  );

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _openSignUpAndHandleResult() async {
    _dismissKeyboard();
    _suppressNextVerificationMessage = true;

    final dynamic result = await callNextScreenWithResult(
      context,
      const SignupScreen(),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _emailController.clear();
      _passwordController.clear();
      _emailInlineError = null;
      _passwordInlineError = null;
      _isPasswordHidden = true;
    });

    if (result == SignupScreen.emailVerificationSentResult) {
      await _showVerificationLinkDialog();
    }

    _suppressNextVerificationMessage = false;
  }

  Future<void> _showVerificationLinkDialog() async {
    if (_isVerificationDialogOpen) {
      return;
    }

    _isVerificationDialogOpen = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return const _VerificationLinkSentDialog();
      },
    );
    _isVerificationDialogOpen = false;
  }

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
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (BuildContext context, AuthState state) {
        if (!(ModalRoute.of(context)?.isCurrent ?? false)) {
          return;
        }

        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          final String message = state.errorMessage!;
          if (_isVerificationEmailMessage(message)) {
            context.read<AuthBloc>().add(const AuthErrorCleared());
            if (_suppressNextVerificationMessage) {
              _suppressNextVerificationMessage = false;
              return;
            }

            _showVerificationLinkDialog();
            return;
          }

          if (_isInvalidEmailMessage(message)) {
            context.read<AuthBloc>().add(const AuthErrorCleared());
            setState(() {
              _emailInlineError = 'Please enter a valid email address.';
            });
            return;
          }

          if (_isUserNotFoundMessage(message)) {
            context.read<AuthBloc>().add(const AuthErrorCleared());
            setState(() {
              _emailInlineError = 'No user found with this email.';
            });
            return;
          }

          if (_isInvalidCredentialsMessage(message)) {
            context.read<AuthBloc>().add(const AuthErrorCleared());
            setState(() {
              _passwordInlineError = 'Invalid email or password.';
            });
            return;
          }

          showSnackBar(context, state.errorMessage!, AppColors.red);
          context.read<AuthBloc>().add(const AuthErrorCleared());
        }

        if (state.isAuthenticated) {
          _dismissKeyboard();
          callNextScreenAndClearStack(context, const PermissionScreen());
        }
      },
      builder: (BuildContext context, AuthState state) {
        final bool isSignInLoading =
            state.isLoading && state.actionType == AuthActionType.emailSignIn;

        return Scaffold(
          backgroundColor: AppColors.whiteBg,
          appBar: CommonAppBar(
            onPrefixTap: () {
              _dismissKeyboard();
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
                      onChanged: (String value) {
                        if (_emailInlineError == null) {
                          return;
                        }

                        if (_validateEmail(value) == null) {
                          setState(() {
                            _emailInlineError = null;
                          });
                        }
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
                      hasError: _emailInlineError != null,
                      errorMessage: _emailInlineError,
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
                      onChanged: (String value) {
                        if (_passwordInlineError == null) {
                          return;
                        }

                        if (_validatePassword(value) == null) {
                          setState(() {
                            _passwordInlineError = null;
                          });
                        }
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
                      suffixIcon: _isPasswordHidden
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      onSuffixPressed: () {
                        setState(() {
                          _isPasswordHidden = !_isPasswordHidden;
                        });
                      },
                      hasError: _passwordInlineError != null,
                      errorMessage: _passwordInlineError,
                    ),
                    sb(50),
                    CustomButton(
                      onButtonPressed: () {
                        final String email = _emailController.text.trim();
                        final String password = _passwordController.text;

                        final String? emailError = _validateEmail(email);
                        final String? passwordError = _validatePassword(password);

                        if (emailError != null || passwordError != null) {
                          setState(() {
                            _emailInlineError = emailError;
                            _passwordInlineError = passwordError;
                          });
                          return;
                        }

                        _dismissKeyboard();
                        context.read<AuthBloc>().add(
                              AuthSignInWithEmailRequested(
                                email: email,
                                password: password,
                              ),
                            );
                      },
                      isLoading: isSignInLoading,
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
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.greyDark,
                          ),
                        ),
                        TextButton(
                          
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 5, vertical: 0),
                            
                            overlayColor: AppColors.transparent,
                          ),
                          onPressed: () async {
                            await _openSignUpAndHandleResult();
                          },
                          child: CommonText(
                            AppStrings.createAccount,
                            textAlign: .center,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 14.sp,
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
      },
    );
  }

  bool _isVerificationEmailMessage(String message) {
    final String lower = message.toLowerCase();
    return lower.contains('email not verified') ||
        lower.contains('email is not verified') ||
        lower.contains('verification email') ||
        lower.contains('verify and sign in') ||
        (lower.contains('verify') && lower.contains('email'));
  }

  bool _isInvalidEmailMessage(String message) {
    final String lower = message.toLowerCase();
    return lower.contains('valid email address') ||
        lower.contains('invalid-email');
  }

  bool _isUserNotFoundMessage(String message) {
    final String lower = message.toLowerCase();
    return lower.contains('no user found with this email') ||
        lower.contains('user-not-found');
  }

  bool _isInvalidCredentialsMessage(String message) {
    final String lower = message.toLowerCase();
    return lower.contains('invalid email or password') ||
        lower.contains('invalid-credential') ||
        lower.contains('wrong-password');
  }

  String? _validateEmail(String value) {
    final String normalized = value.trim();
    if (normalized.isEmpty) {
      return 'Email address is required.';
    }
    if (!_emailPattern.hasMatch(normalized)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  String? _validatePassword(String value) {
    final String normalized = value.trim();
    if (normalized.isEmpty) {
      return 'Password is required.';
    }
    return null;
  }
}

class _VerificationLinkSentDialog extends StatefulWidget {
  const _VerificationLinkSentDialog();

  @override
  State<_VerificationLinkSentDialog> createState() =>
      _VerificationLinkSentDialogState();
}

class _VerificationLinkSentDialogState
    extends State<_VerificationLinkSentDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _countdownController;

  @override
  void initState() {
    super.initState();
    _countdownController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )
      ..addListener(() {
        if (mounted) {
          setState(() {});
        }
      })
      ..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed && mounted) {
          Navigator.of(context).pop();
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _countdownController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double ringValue = (1.0 - _countdownController.value).clamp(0.0, 1.0);
    final int remainingSeconds =
        ((1 - _countdownController.value) * 5).ceil().clamp(0, 5);

    return Dialog(
      backgroundColor: AppColors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        padding: EdgeInsets.fromLTRB(24.w, 22.h, 24.w, 20.h),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(30.r),
        ),
        child: Stack(
          children: [
            Positioned(
              right: 2.w,
              top: 0,
              child: SizedBox(
                width: 34.w,
                height: 34.w,
                child: Stack(
                  fit: StackFit.expand,
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: ringValue,
                      strokeWidth: 3,
                      backgroundColor: AppColors.grey,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                    Center(
                      child: CommonText(
                        '$remainingSeconds',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 66.w,
                  height: 66.w,
                  decoration: BoxDecoration(
                    color: AppColors.greyLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    AppIcons.mail,
                    color: AppColors.primary,
                    size: 30.sp,
                  ),
                ),
                sb(16),
                CommonText(
                  'Verification Link Sent',
                  style: TextStyle(
                    fontSize: 27.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                sb(12),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2.w),
                  child: CommonText(
                    "We've sent a secure link to your email address. Please click it to verify your account.",
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.greyDark,
                      height: 1.45,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                sb(12),
                CommonText(
                  "Can't find it? Check your spam or junk folder.",
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.greyDark,
                    decoration: TextDecoration.underline,
                    decorationThickness: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                sb(24),
                SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: CommonText(
                      'Got it',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
