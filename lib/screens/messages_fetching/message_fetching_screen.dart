import "package:flutter_screenutil/flutter_screenutil.dart";
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kharcha/bloc/sms/sms_bloc.dart';
import 'package:kharcha/bloc/sms/sms_event.dart';
import 'package:kharcha/bloc/sms/sms_state.dart';
import 'package:kharcha/components/common_app_bar.dart';
import 'package:kharcha/components/sync_progress_circle.dart';
import 'package:kharcha/components/common_text.dart';
import 'package:kharcha/screens/home/home_screen.dart';
import 'package:kharcha/utils/constants/app_colors.dart';
import 'package:kharcha/utils/constants/app_image.dart';
import 'package:kharcha/utils/constants/app_strings.dart';
import 'package:kharcha/utils/drive/drive_backup_service.dart';
import 'package:kharcha/utils/my_cm.dart';
import 'package:kharcha/utils/sms/sms_transaction.dart';

class MessageFetchingScreen extends StatefulWidget {
  const MessageFetchingScreen({super.key});

  @override
  State<MessageFetchingScreen> createState() => _MessageFetchingScreenState();
}

class _MessageFetchingScreenState extends State<MessageFetchingScreen> {
  final DriveBackupService _driveBackupService = DriveBackupService();
  bool _isBackingUpDrive = false;
  bool _isCompletingFlow = false;

  Future<void> _backupAndNavigate(List<SmsTransaction> transactions) async {
    if (_isCompletingFlow) {
      return;
    }

    _isCompletingFlow = true;
    if (mounted) {
      setState(() {
        _isBackingUpDrive = true;
      });
    }

    try {
      final DriveBackupResult backupResult =
          await _driveBackupService.backupTransactionsToDrive(transactions);
      if (mounted &&
          context.mounted &&
          !backupResult.success &&
          backupResult.message.trim().isNotEmpty) {
        showSnackBar(context, backupResult.message, AppColors.red);
      }
    } catch (_) {
      // Keep app flow intact even if backup fails.
    } finally {
      if (mounted && context.mounted) {
        setState(() {
          _isBackingUpDrive = false;
        });
        callNextScreenAndClearStack(context, const HomeScreen());
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final SmsBloc smsBloc = context.read<SmsBloc>();
      final SmsState currentState = smsBloc.state;

      if (currentState is SmsInitial ||
          currentState is SmsFailure ||
          currentState is SmsPermissionDenied) {
        smsBloc.add(const SmsFetchRequested());
      } else if (currentState is SmsLoaded) {
        _backupAndNavigate(currentState.transactions);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteBg,
      appBar: CommonAppBar(
        prefixImageAsset: AppImage.logo2,
        prefixImageWidth: 150,
        toolbarHeight: 68,
        appBarHorizontalPadding: 12,
        suffixImageAsset: AppImage.profilePlaceHolder,
        suffixImageBackgroundColor: AppColors.grey,
        isSuffixImageRound: true,
        suffixImageSize: 40,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: BlocConsumer<SmsBloc, SmsState>(
            listener: (BuildContext context, SmsState state) {
              if (state is SmsLoaded) {
                _backupAndNavigate(state.transactions);
              }
            },
            builder: (BuildContext context, SmsState state) {
                final bool isLoading = state is SmsLoading || state is SmsInitial;
                final int count = state is SmsLoaded
                  ? state.transactions.length
                  : state is SmsLoading
                    ? state.matchedMessages
                    : 0;
                final double progress = state is SmsLoading
                  ? (state.totalMessages == 0
                    ? 0
                    : state.processedMessages / state.totalMessages)
                  : isLoading
                    ? 0
                    : 1.0;
                final String statusText = state is SmsPermissionDenied
                    ? 'SMS permission denied'
                    : state is SmsFailure
                        ? 'Failed to read messages'
                        : _isBackingUpDrive
                            ? 'Saving backup...'
                        : isLoading
                            ? 'Scanning...'
                            : 'Scan complete';
                final String footerText = state is SmsPermissionDenied
                  ? 'Allow SMS permission to continue'
                  : state is SmsFailure
                    ? (state.message.isEmpty
                      ? 'Unable to read messages'
                      : state.message)
                    : _isBackingUpDrive
                      ? 'Storing transactions in Google Drive...'
                    : 'Please wait while we fetch your messages';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CommonText(
                      AppStrings.systemSync,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 2,
                        color: AppColors.greyDark,
                      ),
                    ),
                    sb(8.sp),
                    CommonText(
                      AppStrings.importHistoryTitle,
                      style: TextStyle(
                        fontSize: 32.sp,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        color: AppColors.black,
                      ),
                    ),
                    sb(7.sp),
                    CommonText(
                      AppStrings.importHistoryDesc,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.greyDark,
                      ),
                    ),
                    sb(70.sp),
                    Center(
                      child: SyncProgressCircle(
                        progress: progress,
                        statusText: statusText,
                        size: 240,
                        strokeWidth: 16,
                        ringColor: AppColors.primary,
                        fillColor: AppColors.greyLight,
                        statusTextColor: AppColors.primaryDark,
                      ),
                    ),
                    sb(22),
                    Center(
                      child: Column(
                        children: [
                          CommonText(
                            '$count',
                            style: TextStyle(
                              fontSize: 34.sp,
                              fontWeight: FontWeight.w900,
                              color: AppColors.black,
                            ),
                          ),
                          CommonText(
                            AppStrings.transactionsFound,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.2,
                              color: AppColors.greyDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: SizedBox(
                          child: CommonText(
                            footerText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
            },
          ),
        ),
      ),
    );
  }
}
