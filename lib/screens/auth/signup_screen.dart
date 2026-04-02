import "package:flutter_screenutil/flutter_screenutil.dart";
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kharcha/components/common_app_bar.dart';
import 'package:kharcha/components/common_button.dart';
import 'package:kharcha/components/common_input_field.dart';
import 'package:kharcha/components/common_text.dart';
import 'package:kharcha/screens/auth/bloc/auth_bloc.dart';
import 'package:kharcha/screens/auth/bloc/auth_event.dart';
import 'package:kharcha/screens/auth/bloc/auth_state.dart';
import 'package:kharcha/utils/constants/app_colors.dart';
import 'package:kharcha/utils/constants/app_icons.dart';
import 'package:kharcha/utils/constants/app_image.dart';
import 'package:kharcha/utils/constants/app_strings.dart';
import 'package:kharcha/utils/my_cm.dart';

class SignupScreen extends StatefulWidget {
  static const String emailVerificationSentResult = 'email_verification_sent';

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
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _fullNameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  String? _fullNameInlineError;
  String? _emailInlineError;
  bool _isPasswordHidden = true;
  String? _passwordInlineError;
  bool _isFetchingProfile = false;
  bool _isSavingProfile = false;
  String? _profilePhotoUrl;

  static final RegExp _emailPattern = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  );

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  void initState() {
    super.initState();
    _fullNameController.text = widget.initialName ?? '';
    _emailController.text = widget.initialEmail ?? '';

    if (widget.isEditMode) {
      _loadProfileFromFirestore();
    }
  }

  Future<void> _loadProfileFromFirestore() async {
    final User? currentUser = _firebaseAuth.currentUser;
    final String normalizedEmail =
        (currentUser?.email ?? '').trim().toLowerCase();

    if (normalizedEmail.isEmpty) {
      return;
    }

    setState(() {
      _isFetchingProfile = true;
    });

    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('users')
          .doc(normalizedEmail)
          .get();
      final Map<String, dynamic>? data = snapshot.data();
      final String firestoreName = (data?['fullName'] as String?)?.trim() ?? '';
      final String firestoreEmail = (data?['email'] as String?)?.trim() ?? '';
      final String firestorePhotoUrl =
          (data?['photoUrl'] as String?)?.trim() ?? '';

      if (!mounted) {
        return;
      }

      setState(() {
        if (firestoreName.isNotEmpty) {
          _fullNameController.text = firestoreName;
        }
        if (firestoreEmail.isNotEmpty) {
          _emailController.text = firestoreEmail;
        } else if (_emailController.text.trim().isEmpty) {
          _emailController.text = normalizedEmail;
        }
        _profilePhotoUrl = firestorePhotoUrl.isEmpty ? null : firestorePhotoUrl;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      if (_emailController.text.trim().isEmpty) {
        _emailController.text = normalizedEmail;
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingProfile = false;
        });
      }
    }
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

  String? _validateFullName(String value) {
    final String normalized = value.trim();
    if (normalized.isEmpty) {
      return 'Full name is required.';
    }
    if (normalized.length < 2) {
      return 'Please enter your full name.';
    }
    return null;
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
    if (normalized.length < 6) {
      return 'Password is too weak. Use at least 6 characters.';
    }
    return null;
  }

  bool _isVerificationEmailMessage(String message) {
    final String lower = message.toLowerCase();
    return lower.contains('email not verified') ||
        lower.contains('email is not verified') ||
        lower.contains('verification email') ||
        lower.contains('verify and sign in') ||
        (lower.contains('verify') && lower.contains('email'));
  }

  bool _isWeakPasswordMessage(String message) {
    final String lower = message.toLowerCase();
    return lower.contains('weak password') ||
        lower.contains('password is too weak');
  }

  bool _isInvalidEmailMessage(String message) {
    final String lower = message.toLowerCase();
    return lower.contains('valid email address') || lower.contains('invalid-email');
  }

  bool _isEmailAlreadyInUseMessage(String message) {
    final String lower = message.toLowerCase();
    return lower.contains('already exists with this email') ||
        lower.contains('email-already-in-use');
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (BuildContext context, AuthState state) {
        if (!(ModalRoute.of(context)?.isCurrent ?? false)) {
          return;
        }

        if (widget.isEditMode &&
            _isSavingProfile &&
            !state.isLoading &&
            state.actionType == AuthActionType.none &&
            (state.errorMessage == null || state.errorMessage!.isEmpty)) {
          _isSavingProfile = false;
          _dismissKeyboard();
          showSnackBar(context, 'Profile updated successfully', AppColors.primary);
          Navigator.pop(context, true);
          return;
        }

        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          if (widget.isEditMode) {
            _isSavingProfile = false;
          }

          final String message = state.errorMessage!;
          if (_isVerificationEmailMessage(message) && !widget.isEditMode) {
            context.read<AuthBloc>().add(const AuthErrorCleared());
            _dismissKeyboard();
            Navigator.pop(context, SignupScreen.emailVerificationSentResult);
            return;
          }

          if (_isWeakPasswordMessage(message) && !widget.isEditMode) {
            context.read<AuthBloc>().add(const AuthErrorCleared());
            setState(() {
              _passwordInlineError =
                  'Password is too weak. Use at least 6 characters.';
            });
            return;
          }

          if (_isInvalidEmailMessage(message) && !widget.isEditMode) {
            context.read<AuthBloc>().add(const AuthErrorCleared());
            setState(() {
              _emailInlineError = 'Please enter a valid email address.';
            });
            return;
          }

          if (_isEmailAlreadyInUseMessage(message) && !widget.isEditMode) {
            context.read<AuthBloc>().add(const AuthErrorCleared());
            setState(() {
              _emailInlineError =
                  'An account already exists with this email.';
            });
            return;
          }
          showSnackBar(context, message, AppColors.red);
          context.read<AuthBloc>().add(const AuthErrorCleared());
        }
      },
      builder: (BuildContext context, AuthState state) {
        return Scaffold(
          backgroundColor: AppColors.whiteBg,
          appBar: CommonAppBar(
            onPrefixTap: () {
              _dismissKeyboard();
              Navigator.pop(context);
            },
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
                      child: widget.isEditMode
                          ? Container(
                              width: 100,
                              height: 100,
                              color: AppColors.grey,
                              child: _profilePhotoUrl != null
                                  ? Image.network(
                                      _profilePhotoUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                        BuildContext context,
                                        Object error,
                                        StackTrace? stackTrace,
                                      ) {
                                        return Image.asset(
                                          AppImage.profilePlaceHolder,
                                          fit: BoxFit.cover,
                                        );
                                      },
                                    )
                                  : Image.asset(
                                      AppImage.profilePlaceHolder,
                                      fit: BoxFit.cover,
                                    ),
                            )
                          : Image.asset(AppImage.logo, height: 100),
                    ),
                  ),
                  sb(24),
                  Center(
                    child: CommonText(
                      widget.isEditMode
                          ? AppStrings.editProfile
                          : AppStrings.createYourSpace,
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
                    enabled: !_isFetchingProfile,
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
                    onChanged: (String value) {
                      if (_fullNameInlineError == null) {
                        return;
                      }

                      if (_validateFullName(value) == null) {
                        setState(() {
                          _fullNameInlineError = null;
                        });
                      }
                    },
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
                    hasError: _fullNameInlineError != null,
                    errorMessage: _fullNameInlineError,
                  ),
                  sb(18),
                  CommonInputField(
                    labelText: AppStrings.emailAddress,
                    hintText: 'name@example.com',
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    enabled: !widget.isEditMode && !_isFetchingProfile,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
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
                      color: widget.isEditMode ? AppColors.greyDark : AppColors.black,
                    ),
                    suffixIcon: AppIcons.mail,
                    hasError: _emailInlineError != null,
                    errorMessage: _emailInlineError,
                  ),
                  sb(18),
                  CommonInputField(
                    labelText: AppStrings.password,
                    hintText: widget.isEditMode ? '••••••' : 'Enter your password',
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    enabled: !widget.isEditMode,
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
                    keyboardType: TextInputType.visiblePassword,
                    textInputAction: TextInputAction.done,
                    obscureText: widget.isEditMode ? true : _isPasswordHidden,
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
                      color: widget.isEditMode ? AppColors.greyDark : AppColors.black,
                    ),
                    suffixIcon: widget.isEditMode
                        ? null
                        : (_isPasswordHidden ? AppIcons.visibilityOff : AppIcons.visibility),
                    onSuffixPressed: widget.isEditMode
                        ? null
                        : () {
                            setState(() {
                              _isPasswordHidden = !_isPasswordHidden;
                            });
                          },
                    hasError: _passwordInlineError != null,
                    errorMessage: _passwordInlineError,
                  ),
                  sb(28),
                  CustomButton(
                    onButtonPressed: () {
                      if (widget.isEditMode) {
                        final String fullName = _fullNameController.text.trim();
                        final String? fullNameError = _validateFullName(fullName);

                        if (fullNameError != null) {
                          setState(() {
                            _fullNameInlineError = fullNameError;
                          });
                          return;
                        }

                        _dismissKeyboard();
                        _isSavingProfile = true;
                        context.read<AuthBloc>().add(
                          AuthUpdateProfileRequested(fullName: fullName),
                        );
                      } else {
                        final String fullName = _fullNameController.text.trim();
                        final String email = _emailController.text.trim();
                        final String password = _passwordController.text;

                        final String? fullNameError = _validateFullName(fullName);
                        final String? emailError = _validateEmail(email);
                        final String? passwordError = _validatePassword(password);

                        if (fullNameError != null ||
                            emailError != null ||
                            passwordError != null) {
                          setState(() {
                            _fullNameInlineError = fullNameError;
                            _emailInlineError = emailError;
                            _passwordInlineError = passwordError;
                          });
                          return;
                        }

                        _dismissKeyboard();
                        context.read<AuthBloc>().add(
                              AuthSignUpWithEmailRequested(
                                fullName: fullName,
                                email: email,
                                password: password,
                              ),
                            );
                      }
                    },
                    isLoading: widget.isEditMode
                      ? (state.isLoading &&
                        state.actionType == AuthActionType.profileUpdate)
                      : state.isLoading,
                    buttonText: widget.isEditMode
                        ? AppStrings.saveProfile
                        : AppStrings.createAccount,
                    borderRadius: 999,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    
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
                          onPressed: () {
                            _dismissKeyboard();
                            Navigator.pop(context);
                          },
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
      },
    );
  }
}

