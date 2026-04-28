import "package:flutter_screenutil/flutter_screenutil.dart";
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kharcha/components/common_button.dart';
import 'package:kharcha/components/common_text.dart';
import 'package:kharcha/screens/auth/bloc/auth_bloc.dart';
import 'package:kharcha/screens/auth/bloc/auth_event.dart';
import 'package:kharcha/screens/auth/bloc/auth_state.dart';
import 'package:kharcha/screens/auth/signup_screen.dart';
import 'package:kharcha/screens/splash/splash_screen.dart';
import 'package:kharcha/utils/constants/app_colors.dart';
import 'package:kharcha/utils/constants/app_image.dart';
import 'package:kharcha/utils/constants/app_strings.dart';
import 'package:kharcha/utils/my_cm.dart';
import 'package:kharcha/utils/permissions/permission_manager.dart';

class SettingsTabScreen extends StatefulWidget {
  const SettingsTabScreen({super.key});

  @override
  State<SettingsTabScreen> createState() => SettingsTabScreenState();
}

class SettingsTabScreenState extends State<SettingsTabScreen> {
  final PermissionManager _permissionManager = PermissionManager();
  bool _pushNotificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    final bool enabled = await _permissionManager.isNotificationsEnabled();
    if (mounted) {
      setState(() {
        _pushNotificationsEnabled = enabled;
      });
    }
  }

  Future<void> _handleNotificationToggle(bool value) async {
    if (value) {
      // User wants to enable notifications — request permission first
      final bool granted = await _permissionManager.requestNotificationPermission();
      if (!granted) {
        if (mounted) {
          showSnackBar(
            context,
            'Notification permission is required. Please enable it in app settings.',
            AppColors.red,
          );
        }
        return;
      }
    }

    await _permissionManager.setNotificationsEnabled(value);
    if (mounted) {
      setState(() {
        _pushNotificationsEnabled = value;
      });
      showSnackBar(
        context,
        value
            ? 'Push notifications enabled'
            : 'Push notifications disabled',
        value ? AppColors.primary : AppColors.greyDark,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String normalizedEmail =
        (currentUser?.email ?? '').trim().toLowerCase();

    return BlocListener<AuthBloc, AuthState>(
      listener: (BuildContext context, AuthState state) {
        if (!context.mounted) {
          return;
        }
        final bool isLoggedOut = FirebaseAuth.instance.currentUser == null;
        if (isLoggedOut) {
          callNextScreenAndClearStack(context, const SplashScreen());
        }
      },
      child: normalizedEmail.isEmpty
          ? _buildSettingsUI(
              context,
              displayName: currentUser?.displayName ?? 'User',
              email: currentUser?.email ?? '',
              photoUrl: null,
            )
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(normalizedEmail)
                  .snapshots(),
              builder: (
                BuildContext context,
                AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot,
              ) {
                final Map<String, dynamic>? data = snapshot.data?.data();
                final String displayName =
                    (data?['fullName'] as String?)?.trim().isNotEmpty == true
                    ? (data?['fullName'] as String).trim()
                    : (currentUser?.displayName ?? 'User');
                final String email =
                    (data?['email'] as String?)?.trim().isNotEmpty == true
                    ? (data?['email'] as String).trim()
                    : (currentUser?.email ?? '');
                final String photoUrlRaw =
                    (data?['photoUrl'] as String?)?.trim() ?? '';

                return _buildSettingsUI(
                  context,
                  displayName: displayName,
                  email: email,
                  photoUrl: photoUrlRaw.isEmpty ? null : photoUrlRaw,
                );
              },
            ),
    );
  }

  Widget _buildSettingsUI(
    BuildContext context, {
    required String displayName,
    required String email,
    required String? photoUrl,
  }) {
    return SafeArea(
      top: true,
      bottom: false,
      child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 10, 20, 20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sb(8),
            Center(
              child: SizedBox(
                width: 158,
                height: 158,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 158,
                      height: 158,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFD6DBDF),
                      ),
                      padding: EdgeInsets.all(6),
                      child: ClipOval(
                        child: photoUrl == null
                            ? Image.asset(
                                AppImage.profilePlaceHolder,
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                photoUrl,
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
                              ),
                      ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: 12,
                      child: GestureDetector(
                        onTap: () {
                          callNextScreen(
                            context,
                            SignupScreen(
                              isEditMode: true,
                              initialName: displayName,
                              initialEmail: email,
                            ),
                          );
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.white,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.black.withValues(alpha: 0.12),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.edit_outlined,
                            color: AppColors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            sb(14),
            Center(
              child: CommonText(
                displayName,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E2328),
                ),
              ),
            ),
            sb(24),
            const _SettingsSectionTitle(title: AppStrings.account),
            sb(8),
            _SettingsTile(
              icon: Icons.person_outline_rounded,
              title: AppStrings.personalInformation,
              onTap: () {
                callNextScreen(
                  context,
                  SignupScreen(
                    isEditMode: true,
                    initialName: displayName,
                    initialEmail: email,
                  ),
                );
              },
            ),
            sb(16),
            const _SettingsSectionTitle(title: AppStrings.categories),
            sb(8),
            _SettingsTile(
              icon: Icons.auto_graph_rounded,
              title: AppStrings.manageCategories,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E8E6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: CommonText(
                      AppStrings.categoryCount,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  sbw(8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFA8B1B8),
                    size: 24,
                  ),
                ],
              ),
              onTap: () {},
            ),
            sb(16),
            const _SettingsSectionTitle(title: AppStrings.notifications),
            sb(8),
            _SettingsTile(
              icon: Icons.notifications_none_rounded,
              title: AppStrings.pushNotifications,
              trailing: Switch.adaptive(
                value: _pushNotificationsEnabled,
                activeTrackColor: AppColors.primary,
                inactiveThumbColor: AppColors.white,
                inactiveTrackColor: const Color(0xFFD6DDE3),
                onChanged: (bool value) {
                  _handleNotificationToggle(value);
                },
              ),
              onTap: () {
                _handleNotificationToggle(!_pushNotificationsEnabled);
              },
            ),
            sb(16),
            const _SettingsSectionTitle(title: AppStrings.dataAndPrivacy),
            sb(8),
            _SettingsTile(
              icon: Icons.file_download_outlined,
              title: AppStrings.exportData,
              onTap: () {},
            ),
            sb(42),
            CustomButton(
              onButtonPressed: () {
                context.read<AuthBloc>().add(const AuthLogoutRequested());
              },
              buttonText: AppStrings.logout,
              backgroundColor: AppColors.red,
              textColor: AppColors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSectionTitle extends StatelessWidget {
  final String title;

  const _SettingsSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: CommonText(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13.sp,
          letterSpacing: 1.4,
          fontWeight: FontWeight.w700,
          color: Color(0xFF8B98A5),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 72,
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon, size: 26, color: AppColors.primary),
              sbw(10),
              Expanded(
                child: CommonText(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF22282D),
                  ),
                ),
              ),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFA8B1B8),
                    size: 24,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
