import "package:flutter_screenutil/flutter_screenutil.dart";
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kharcha/components/common_button.dart';
import 'package:kharcha/components/common_text.dart';
import 'package:kharcha/screens/home/home_screen.dart';
import 'package:kharcha/screens/messages_fetching/message_fetching_screen.dart';
import 'package:kharcha/utils/constants/app_colors.dart';
import 'package:kharcha/utils/constants/app_icons.dart';
import 'package:kharcha/utils/constants/app_strings.dart';
import 'package:kharcha/utils/my_cm.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  static const String _driveFileScope =
      'https://www.googleapis.com/auth/drive.file';
  static const String _driveAppDataScope =
      'https://www.googleapis.com/auth/drive.appdata';

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[_driveFileScope, _driveAppDataScope],
  );

  bool _isDriveLoading = false;
  bool _isDriveGranted = false;
  String? _connectedDriveEmail;

  @override
  void initState() {
    super.initState();
    _loadDriveAccessStatus();
  }

  String _currentUserEmailDocId() {
    return (_firebaseAuth.currentUser?.email ?? '').trim().toLowerCase();
  }

  Future<void> _loadDriveAccessStatus() async {
    final String docId = _currentUserEmailDocId();
    if (docId.isEmpty) {
      return;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('users')
          .doc(docId)
          .get();

      final Map<String, dynamic>? data = snapshot.data();
      if (!mounted) {
        return;
      }

      setState(() {
        _isDriveGranted = (data?['driveAccessGranted'] as bool?) ?? false;
        _connectedDriveEmail = (data?['driveAccountEmail'] as String?)?.trim();
      });
    } catch (_) {
      // Keep default value when status lookup fails.
    }
  }

  bool _isSameAccount(String a, String b) {
    return a.trim().toLowerCase() == b.trim().toLowerCase();
  }

  Future<void> _requestGoogleDriveAccess() async {
    if (_isDriveLoading || _isDriveGranted) {
      return;
    }

    final User? currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      showSnackBar(context, 'Please sign in first.', AppColors.red);
      return;
    }
    final String currentUserEmail = (currentUser.email ?? '').trim();
    if (currentUserEmail.isEmpty) {
      showSnackBar(context, 'Unable to identify signed in user email.', AppColors.red);
      return;
    }

    setState(() {
      _isDriveLoading = true;
    });

    try {
      GoogleSignInAccount? account = _googleSignIn.currentUser;
      account ??= await _googleSignIn.signInSilently();
      account ??= await _googleSignIn.signIn();

      if (account == null) {
        if (mounted) {
          showSnackBar(
            context,
            'Google sign-in was cancelled. Drive access was not granted.',
            AppColors.red,
          );
        }
        return;
      }

      final String selectedGoogleEmail = account.email.trim();
      if (!_isSameAccount(selectedGoogleEmail, currentUserEmail)) {
        try {
          await _googleSignIn.disconnect();
        } catch (_) {
          await _googleSignIn.signOut();
        }

        if (mounted) {
          showSnackBar(
            context,
            'Please select the same Google account as your app login: $currentUserEmail',
            AppColors.red,
          );
        }
        return;
      }

      final bool granted = await _googleSignIn.requestScopes(
        <String>[_driveFileScope, _driveAppDataScope],
      );

      if (!granted) {
        if (mounted) {
          showSnackBar(
            context,
            'Google Drive permission is required to store backups.',
            AppColors.red,
          );
        }
        return;
      }

      final String emailDocId = _currentUserEmailDocId();
      if (emailDocId.isEmpty) {
        if (mounted) {
          showSnackBar(
            context,
            'Unable to identify user profile for Drive setup.',
            AppColors.red,
          );
        }
        return;
      }

      await _firestore.collection('users').doc(emailDocId).set(
        <String, dynamic>{
          'driveAccessGranted': true,
          'driveScopes': <String>[_driveFileScope, _driveAppDataScope],
          'driveAccountEmail': selectedGoogleEmail.toLowerCase(),
          'driveAccessGrantedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isDriveGranted = true;
        _connectedDriveEmail = selectedGoogleEmail.toLowerCase();
      });
      showSnackBar(
        context,
        'Google Drive access granted. You can now store data in Drive.',
        AppColors.primary,
      );
    } catch (_) {
      if (mounted) {
        showSnackBar(
          context,
          'Failed to request Google Drive access. Please try again.',
          AppColors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDriveLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteBg,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(22, 8, 22, 10),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CommonText.rich(
                  TextSpan(
                    style: TextStyle(
                      fontSize: 34.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                    children: [
                      TextSpan(text: AppStrings.permissionPageTitle1),
                      TextSpan(text: '\n'),
                      TextSpan(
                        text: AppStrings.permissionPageTitle2,
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ],
                  ),
                  textAlign: .start,
                ),
                sb(14),
                CommonText(
                  AppStrings.permissionPageDesc,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontSize: 16.sp,
                    height: 1.35,
                    color: AppColors.greyDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                sb(28),
                _PermissionItem(
                  icon: AppIcons.message,
                  title: AppStrings.permissionPagePermissionTitle1,
                  subtitle: AppStrings.permissionPagePermissionDesc1,
                ),
                sb(18),
                _PermissionItem(
                  icon: AppIcons.notification,
                  title: AppStrings.permissionPagePermissionTitle2,
                  subtitle: AppStrings.permissionPagePermissionDesc2,
                ),
                sb(18),
                _PermissionItem(
                  icon: Icons.cloud_done_outlined,
                  title: 'Google Drive Access',
                  subtitle: _isDriveGranted
                    ? (_connectedDriveEmail == null ||
                        _connectedDriveEmail!.isEmpty
                      ? 'Granted. Backup to your Drive is ready.'
                      : 'Granted for $_connectedDriveEmail')
                      : 'Required to store app data in your Google Drive.',
                  trailing: _isDriveGranted
                      ? Icon(
                          Icons.check_circle,
                          color: AppColors.primary,
                          size: 24,
                        )
                      : null,
                ),
                sb(30),
                CustomButton(
                  onButtonPressed: _requestGoogleDriveAccess,
                  isLoading: _isDriveLoading,
                  buttonText: _isDriveGranted
                      ? 'Google Drive Connected'
                      : 'Allow Google Drive Access',
                  fontSize: 17.sp,
                  backgroundColor: _isDriveGranted
                      ? AppColors.primaryDark
                      : AppColors.primary,
                ),
                sb(14),
                CustomButton(
                  onButtonPressed: () {
                    callNextScreenAndClearStack(
                      context,
                      MessageFetchingScreen(),
                    );
                  },
                  buttonText: AppStrings.allowSMSAccess,
                  fontSize: 18.sp,
                ),
                sb(18),
                Center(
                  child: TextButton(
                    style: ButtonStyle(
                      splashFactory: NoSplash.splashFactory
                    ),
                    onPressed: () async {
                      if (!_isDriveGranted) {
                        await _requestGoogleDriveAccess();
                        if (!context.mounted) {
                          return;
                        }

                        if (!_isDriveGranted) {
                          showSnackBar(
                            context,
                            'Google Drive access is required to continue.',
                            AppColors.red,
                          );
                          return;
                        }
                      }

                      if (!context.mounted) {
                        return;
                      }
                      callNextScreenAndClearStack(context, HomeScreen());
                    },
                    child: CommonText(
                      AppStrings.iWillDoItLater,
                      textAlign: .center,
                      style: TextStyle(
                        color: AppColors.greyDark,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                sb(30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PermissionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _PermissionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.white,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(icon, size: 29, color: AppColors.primaryDark),
          ),
          sbw(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CommonText(
                  title,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
                sb(5),
                CommonText(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.greyDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            sbw(8),
            trailing!,
          ],
        ],
      ),
    );
  }
}
