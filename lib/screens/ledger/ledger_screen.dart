import 'dart:async';

import "package:flutter_screenutil/flutter_screenutil.dart";
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kharcha/bloc/sms/sms_bloc.dart';
import 'package:kharcha/bloc/sms/sms_event.dart';
import 'package:kharcha/bloc/sms/sms_state.dart';
import 'package:kharcha/components/common_text.dart';
import 'package:kharcha/components/common_shimmer.dart';
import 'package:kharcha/screens/ledger/transaction_detail_screen.dart';
import 'package:kharcha/utils/constants/app_colors.dart';
import 'package:kharcha/utils/constants/app_strings.dart';
import 'package:kharcha/utils/anim/marquee_text.dart';
import 'package:kharcha/utils/drive/drive_backup_service.dart';
import 'package:kharcha/utils/drive/transaction_repository.dart';
import 'package:kharcha/utils/sms/sms_transaction.dart';
import 'package:kharcha/utils/permissions/permission_manager.dart';
import 'package:kharcha/utils/my_cm.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LedgerTabScreen extends StatefulWidget {
  const LedgerTabScreen({super.key});

  @override
  State<LedgerTabScreen> createState() => LedgerTabScreenState();
}

class LedgerTabScreenState extends State<LedgerTabScreen>
    with AutomaticKeepAliveClientMixin {
  static const String _allMethodFilter = 'ALL';

  static const List<String> _baseMethodFilters = <String>[
    _allMethodFilter,
    'UPI',
    'NEFT',
    'IMPS',
    'RTGS',
    'CARD',
    'WALLET',
    'OTHER',
  ];

  static const int _pageSize = 25;

  final ScrollController _scrollController = ScrollController();
  late DriveBackupService _driveBackupService;
  final TransactionRepository _repo = TransactionRepository.instance;
  Timer? _autoSyncTimer;
  List<SmsTransaction> _transactions = const <SmsTransaction>[];
  bool _isInitialLoading = true;
  bool _isDrivePermissionDenied = false;
  bool _isSmsPermissionDenied = false;
  bool _isLoadingMore = false;
  bool _isSyncingFromSms = false;
  String? _ledgerError;
  int _visibleTransactionsLimit = _pageSize;
  int _lastFilteredCount = 0;

  _LedgerTimeFilter _selectedTimeFilter = _LedgerTimeFilter.thisYear;
  _LedgerDirectionFilter _selectedDirectionFilter = _LedgerDirectionFilter.all;
  String _selectedMethodFilter = _allMethodFilter;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _driveBackupService = DriveBackupService();

    // Listen to repository updates so the ledger refreshes when data changes
    _repo.transactionsNotifier.addListener(_onTransactionsUpdated);
    _repo.isLoadingNotifier.addListener(_onLoadingStateChanged);

    // Seed from cache immediately (avoids showing empty list if data is already loaded)
    _transactions = _repo.transactions;
    _isInitialLoading = _repo.isLoading || !_repo.hasLoaded;

    _checkAndLoadDriveTransactions();
    _autoSyncTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _syncLatestTransactionsFromSms(silent: true),
    );
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _repo.transactionsNotifier.removeListener(_onTransactionsUpdated);
    _repo.isLoadingNotifier.removeListener(_onLoadingStateChanged);
    super.dispose();
  }

  void _onTransactionsUpdated() {
    if (!mounted) return;
    setState(() {
      _transactions = _repo.transactions;
      _isInitialLoading = false;
    });
  }

  void _onLoadingStateChanged() {
    if (!mounted) return;
    // Only show the loading shimmer when we have no data yet
    if (_repo.isLoading && _transactions.isEmpty) {
      setState(() {
        _isInitialLoading = true;
      });
    }
  }

  Future<void> _checkAndLoadDriveTransactions() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
          _isDrivePermissionDenied = true;
          _ledgerError = 'Please sign in to view Drive transactions.';
        });
      }
      return;
    }

    final String userEmail = (currentUser.email ?? '').trim().toLowerCase();
    if (userEmail.isEmpty) {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
          _isDrivePermissionDenied = true;
          _ledgerError = 'Unable to identify the signed-in account.';
        });
      }
      return;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> userSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userEmail)
              .get();
      final Map<String, dynamic>? userData = userSnapshot.data();
      final bool driveGranted =
          (userData?['driveAccessGranted'] as bool?) ?? false;

      if (driveGranted && mounted) {
        setState(() {
          _isDrivePermissionDenied = false;
          _ledgerError = null;
        });
        _loadDriveTransactions();
      } else if (mounted) {
        setState(() {
          _isInitialLoading = false;
          _isDrivePermissionDenied = true;
          _ledgerError =
              'Google Drive access is required to show transactions.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
          _isDrivePermissionDenied = true;
          _ledgerError = 'Unable to load Drive transactions.';
        });
      }
    }
  }

  Future<void> _loadDriveTransactions() async {
    if (!mounted) {
      return;
    }

    try {
      // Use the shared repository so Home tab also gets the updated data
      await _repo.loadTransactions(forceRefresh: true);
      if (mounted) {
        setState(() {
          _transactions = _repo.transactions;
          _isInitialLoading = false;
          _isDrivePermissionDenied = false;
          _ledgerError = null;
          _visibleTransactionsLimit = _pageSize;
          _lastFilteredCount = _transactions.length;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
          _isDrivePermissionDenied = true;
          _ledgerError = 'Failed to read transactions from Drive.';
        });
      }
    }
  }

  Future<void> _syncLatestTransactionsFromSms({bool silent = false}) async {
    if (_isSyncingFromSms || !mounted) {
      return;
    }

    _isSyncingFromSms = true;
    try {
      final SmsBloc smsBloc = context.read<SmsBloc>();
      smsBloc.add(const SmsFetchRequested());

      final SmsState result = await smsBloc.stream.firstWhere(
        (SmsState state) =>
            state is SmsLoaded ||
            state is SmsPermissionDenied ||
            state is SmsFailure,
      );

      if (result is SmsLoaded && result.transactions.isNotEmpty) {
        await _driveBackupService.backupTransactionsToDrive(
          result.transactions,
        );
        // After backup, do a fresh Drive read so we get the merged/deduplicated
        // list, then push it through the repository so Home tab updates too.
        await _loadDriveTransactions();
        return;
      }

      if (!silent && mounted) {
        setState(() {
          _isInitialLoading = false;
          _isSmsPermissionDenied = result is SmsPermissionDenied;
          _ledgerError = result is SmsFailure ? result.message : _ledgerError;
        });
      }
    } catch (_) {
      if (!silent && mounted) {
        setState(() {
          _isInitialLoading = false;
          _ledgerError = 'Unable to sync new transactions right now.';
        });
      }
    } finally {
      _isSyncingFromSms = false;
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore) {
      return;
    }

    if (_visibleTransactionsLimit >= _lastFilteredCount) {
      return;
    }

    final ScrollPosition position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 220) {
      _loadMoreTransactions();
    }
  }

  void _loadMoreTransactions() {
    if (_isLoadingMore || _visibleTransactionsLimit >= _lastFilteredCount) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (!mounted) {
        return;
      }

      setState(() {
        _visibleTransactionsLimit = (_visibleTransactionsLimit + _pageSize)
            .clamp(0, _lastFilteredCount);
        _isLoadingMore = false;
      });
    });
  }

  Future<void> _onRefresh() async {
    // Show shimmer immediately instead of keeping the RefreshIndicator spinner
    if (mounted) {
      setState(() {
        _isInitialLoading = true;
      });
    }
    // Fire the sync but don't await it — the RefreshIndicator completes
    // right away and the shimmer stays until _loadDriveTransactions finishes
    // (which sets _isInitialLoading = false via _onTransactionsUpdated).
    unawaited(_syncLatestTransactionsFromSms());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    final List<String> methodFilters = _buildMethodFilters(_transactions);
    if (!methodFilters.contains(_selectedMethodFilter)) {
      _selectedMethodFilter = _allMethodFilter;
    }

    final List<SmsTransaction> filtered = _applyFilter(_transactions);
    _lastFilteredCount = filtered.length;
    final int visibleCount = _visibleTransactionsLimit.clamp(
      0,
      _lastFilteredCount,
    );
    final List<SmsTransaction> visibleFiltered = filtered
        .take(visibleCount)
        .toList();
    final bool hasMoreToLoad = visibleCount < _lastFilteredCount;
    final List<_LedgerListEntry> listEntries = _buildListEntries(
      visibleFiltered,
    );

    return RefreshIndicator(
      onRefresh: _onRefresh,
      backgroundColor: AppColors.white,
      color: AppColors.primary,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CommonText(
                    AppStrings.activity,
                    style: TextStyle(
                      fontSize: 14.sp,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6C727A),
                    ),
                  ),
                  sb(4),
                  CommonText(
                    AppStrings.transactions,
                    style: TextStyle(
                      fontSize: 36.sp,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B2023),
                    ),
                  ),
                  sb(12),
                  Row(
                    children: [
                      Expanded(
                        child: _FilterDropdown<_LedgerTimeFilter>(
                          value: _selectedTimeFilter,
                          items: _LedgerTimeFilter.values,
                          itemLabelBuilder: (_LedgerTimeFilter value) =>
                              value.label,
                          onSelected: (_LedgerTimeFilter selected) {
                            setState(() {
                              _selectedTimeFilter = selected;
                              _visibleTransactionsLimit = _pageSize;
                              _isLoadingMore = false;
                            });
                          },
                        ),
                      ),
                      sbw(10),
                      Expanded(
                        child: _FilterDropdown<_LedgerDirectionFilter>(
                          value: _selectedDirectionFilter,
                          items: _LedgerDirectionFilter.values,
                          itemLabelBuilder: (_LedgerDirectionFilter value) =>
                              value.label,
                          onSelected: (_LedgerDirectionFilter selected) {
                            setState(() {
                              _selectedDirectionFilter = selected;
                              _visibleTransactionsLimit = _pageSize;
                              _isLoadingMore = false;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  sb(12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List<Widget>.generate(methodFilters.length, (
                        int index,
                      ) {
                        final String method = methodFilters[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            right: index == methodFilters.length - 1 ? 0 : 8,
                          ),
                          child: _MethodChip(
                            label: _methodLabel(method),
                            isSelected: _selectedMethodFilter == method,
                            onTap: () {
                              setState(() {
                                _selectedMethodFilter = method;
                                _visibleTransactionsLimit = _pageSize;
                                _isLoadingMore = false;
                              });
                            },
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: sb(18)),
          ..._buildBodySlivers(
            isLoading: _isInitialLoading && _transactions.isEmpty,
            isDrivePermissionDenied: _isDrivePermissionDenied,
            isSmsPermissionDenied: _isSmsPermissionDenied,
            errorMessage: _ledgerError,
            listEntries: listEntries,
          ),
          SliverToBoxAdapter(
            child: _isLoadingMore
                ? Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: const CommonShimmerList(count: 1),
                  )
                : SizedBox(height: hasMoreToLoad ? 28.h : 18.h),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBodySlivers({
    required bool isLoading,
    required bool isDrivePermissionDenied,
    required bool isSmsPermissionDenied,
    required String? errorMessage,
    required List<_LedgerListEntry> listEntries,
  }) {
    if (isLoading) {
      return <Widget>[
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          sliver: const SliverToBoxAdapter(child: CommonShimmerList(count: 6)),
        ),
      ];
    }

    final slivers = <Widget>[];

    if (isSmsPermissionDenied) {
      slivers.add(
        SliverToBoxAdapter(
          child: Container(
            margin: EdgeInsets.fromLTRB(20, 0, 20, 10),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.orange, size: 28),
                sbw(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CommonText('Automatic tracking disabled', 
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp, color: AppColors.black)),
                      CommonText('Grant SMS permission to auto-track expenses.', 
                          style: TextStyle(fontSize: 12.sp, color: AppColors.greyDark)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => PermissionManager().openAppSettings(),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: CommonText('Settings', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (isDrivePermissionDenied) {
      slivers.add(
        SliverToBoxAdapter(
          child: _StatusCard(
            title: 'Drive permission needed',
            description:
                'Grant Google Drive access to load transactions from your backup.',
            actionLabel: 'Connect Drive',
            onActionPressed: () {
              // Should probably trigger drive connection
            },
          ),
        ),
      );
      return slivers;
    }

    if (errorMessage != null && listEntries.isEmpty) {
      slivers.add(
        SliverToBoxAdapter(
          child: _StatusCard(
            title: 'Unable to load transactions',
            description: errorMessage,
            actionLabel: 'Retry',
            onActionPressed: () {
              context.read<SmsBloc>().add(const SmsFetchRequested());
            },
          ),
        ),
      );
      return slivers;
    }

    if (listEntries.isEmpty) {
      slivers.add(
        SliverToBoxAdapter(
          child: _StatusCard(
            title: 'No transactions found',
            description:
                'Try a different filter or pull down to refresh your SMS ledger.',
          ),
        ),
      );
      return slivers;
    }

    slivers.add(
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((
            BuildContext context,
            int index,
          ) {
            final _LedgerListEntry entry = listEntries[index];
            if (entry.isSection) {
              return Padding(
                padding: EdgeInsets.only(top: index == 0 ? 0 : 8, bottom: 10),
                child: _LedgerSectionTitle(title: entry.sectionTitle!),
              );
            }

            return Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: _TransactionTile(data: entry.transaction!),
            );
          }, childCount: listEntries.length),
        ),
      ),
    );

    return slivers;
  }

  List<SmsTransaction> _applyFilter(List<SmsTransaction> transactions) {
    final DateTime now = DateTime.now();
    final DateTime startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final DateTime endOfWeek = startOfWeek.add(const Duration(days: 7));
    final DateTime startOfYear = DateTime(now.year, 1, 1);
    final DateTime nextYear = DateTime(now.year + 1, 1, 1);

    return transactions.where((SmsTransaction item) {
      final DateTime dateOnly = DateTime(
        item.transactionDate.year,
        item.transactionDate.month,
        item.transactionDate.day,
      );

      final bool matchesTimeFilter = switch (_selectedTimeFilter) {
        _LedgerTimeFilter.allTime => true,
        _LedgerTimeFilter.thisYear =>
          !dateOnly.isBefore(startOfYear) && dateOnly.isBefore(nextYear),
        _LedgerTimeFilter.thisWeek =>
          !dateOnly.isBefore(startOfWeek) && dateOnly.isBefore(endOfWeek),
        _LedgerTimeFilter.today => _isSameDay(dateOnly, now),
      };

      final bool matchesDirectionFilter = switch (_selectedDirectionFilter) {
        _LedgerDirectionFilter.all => true,
        _LedgerDirectionFilter.credited => !item.isDebit,
        _LedgerDirectionFilter.debited => item.isDebit,
      };

      final bool matchesMethodFilter =
          _selectedMethodFilter == _allMethodFilter ||
          _normalizeMethod(item.method) == _selectedMethodFilter;

      return matchesTimeFilter && matchesDirectionFilter && matchesMethodFilter;
    }).toList();
  }

  List<String> _buildMethodFilters(List<SmsTransaction> transactions) {
    final Set<String> methods = <String>{..._baseMethodFilters};
    for (final SmsTransaction item in transactions) {
      methods.add(_normalizeMethod(item.method));
    }

    final List<String> ordered = <String>[];
    for (final String method in _baseMethodFilters) {
      if (methods.remove(method)) {
        ordered.add(method);
      }
    }

    final List<String> extras = methods.toList()..sort();
    ordered.addAll(extras);
    return ordered;
  }

  String _methodLabel(String method) {
    return switch (method) {
      _allMethodFilter => 'All',
      'RTGS' => 'Bank Transfer',
      'CARD' => 'Card',
      'WALLET' => 'Wallet',
      'OTHER' => 'Other',
      _ => method,
    };
  }

  String _normalizeMethod(String method) {
    final String normalized = method.trim().toUpperCase();
    if (normalized.isEmpty) {
      return 'OTHER';
    }
    if (normalized.contains('UPI')) {
      return 'UPI';
    }
    if (normalized.contains('NEFT')) {
      return 'NEFT';
    }
    if (normalized.contains('IMPS')) {
      return 'IMPS';
    }
    if (normalized.contains('RTGS') || normalized.contains('BANK TRANSFER')) {
      return 'RTGS';
    }
    if (normalized.contains('CARD')) {
      return 'CARD';
    }
    if (normalized.contains('WALLET')) {
      return 'WALLET';
    }
    return 'OTHER';
  }

  List<_LedgerListEntry> _buildListEntries(List<SmsTransaction> items) {
    if (items.isEmpty) {
      return <_LedgerListEntry>[];
    }

    final List<_LedgerListEntry> entries = <_LedgerListEntry>[];
    String? currentSection;

    for (final SmsTransaction item in items) {
      final String section = _sectionTitleForDate(item.transactionDate);
      if (section != currentSection) {
        currentSection = section;
        entries.add(_LedgerListEntry.section(section));
      }
      entries.add(_LedgerListEntry.transaction(item));
    }

    return entries;
  }

  String _sectionTitleForDate(DateTime date) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime target = DateTime(date.year, date.month, date.day);

    if (target == today) {
      return AppStrings.today;
    }

    if (target == today.subtract(const Duration(days: 1))) {
      return AppStrings.yesterday;
    }

    return _formatDate(date);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDate(DateTime date) {
    const List<String> monthNames = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final String month = monthNames[(date.month - 1).clamp(0, 11)];
    return '$month ${date.day}, ${date.year}';
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T value) itemLabelBuilder;
  final ValueChanged<T> onSelected;

  const _FilterDropdown({
    required this.value,
    required this.items,
    required this.itemLabelBuilder,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      initialValue: value,
      onSelected: onSelected,
      color: AppColors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (BuildContext context) {
        return items
            .map(
              (T option) => PopupMenuItem<T>(
                value: option,
                child: CommonText(
                  itemLabelBuilder(option),
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: option == value
                        ? AppColors.primary
                        : AppColors.greyDark,
                  ),
                ),
              ),
            )
            .toList();
      },
      child: Container(
        height: 40,
        padding: EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: CommonText(
                itemLabelBuilder(value),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ),
            sbw(4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: AppColors.white,
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MethodChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFE8E8E8),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: CommonText(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
            color: isSelected ? AppColors.white : AppColors.greyDark,
          ),
        ),
      ),
    );
  }
}

enum _LedgerTimeFilter { allTime, thisYear, thisWeek, today }

extension _LedgerTimeFilterLabel on _LedgerTimeFilter {
  String get label {
    return switch (this) {
      _LedgerTimeFilter.allTime => 'All Time',
      _LedgerTimeFilter.thisYear => AppStrings.thisYear,
      _LedgerTimeFilter.thisWeek => AppStrings.thisWeek,
      _LedgerTimeFilter.today => AppStrings.today,
    };
  }
}

enum _LedgerDirectionFilter { all, credited, debited }

extension _LedgerDirectionFilterLabel on _LedgerDirectionFilter {
  String get label {
    return switch (this) {
      _LedgerDirectionFilter.all => AppStrings.all,
      _LedgerDirectionFilter.credited => 'Credited',
      _LedgerDirectionFilter.debited => 'Debited',
    };
  }
}

class _LedgerSectionTitle extends StatelessWidget {
  final String title;

  const _LedgerSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 8),
      child: CommonText(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 14.sp,
          letterSpacing: 2.0,
          fontWeight: FontWeight.w700,
          color: Color(0xFF73797D),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final SmsTransaction data;

  const _TransactionTile({required this.data});

  _TileVisual _tileVisual() {
    final String lowerTitle = data.displaySenderLabel.toLowerCase();
    final String normalizedMethod = data.method.trim().toUpperCase();

    if (!data.isDebit) {
      return _TileVisual(
        icon: Icons.account_balance_wallet_outlined,
        iconColor: AppColors.primary,
        iconBackground: Color(0xFFD6E6E0),
        amountColor: AppColors.primary,
        trailingText: normalizedMethod.isEmpty
            ? AppStrings.tagNow
            : normalizedMethod,
        trailingTextColor: AppColors.primary,
        trailingBackground: Color(0xFFD8EBE4),
        showAccent: false,
      );
    }

    IconData icon = Icons.shopping_bag_outlined;
    Color iconColor = Color(0xFF52606D);

    if (lowerTitle.contains('uber') ||
        lowerTitle.contains('ola') ||
        lowerTitle.contains('transport')) {
      icon = Icons.directions_car_filled_outlined;
    } else if (lowerTitle.contains('food') ||
        lowerTitle.contains('restaurant') ||
        lowerTitle.contains('cafe') ||
        lowerTitle.contains('swiggy') ||
        lowerTitle.contains('zomato')) {
      icon = Icons.restaurant;
      iconColor = AppColors.primary;
    } else if (lowerTitle.contains('power') ||
        lowerTitle.contains('electric') ||
        lowerTitle.contains('bill')) {
      icon = Icons.electric_bolt;
    }

    return _TileVisual(
      icon: icon,
      iconColor: iconColor,
      iconBackground: Color(0xFFE9EAEB),
      amountColor: Color(0xFF1F2529),
      trailingText: normalizedMethod.isEmpty
          ? AppStrings.tagNow
          : normalizedMethod,
      trailingTextColor: AppColors.primary,
      trailingBackground: AppColors.transparent,
      showAccent: true,
    );
  }

  _DirectionChipStyle _directionChipStyle() {
    if (data.isDebit) {
      return const _DirectionChipStyle(
        label: 'Debited',
        textColor: Color(0xFFB42318),
        backgroundColor: Color(0xFFFEE4E2),
      );
    }

    return const _DirectionChipStyle(
      label: 'Credited',
      textColor: Color(0xFF027A48),
      backgroundColor: Color(0xFFD1FADF),
    );
  }

  String _relativeTime(DateTime date) {
    final Duration diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) {
      final int minutes = diff.inMinutes <= 0 ? 1 : diff.inMinutes;
      return '${minutes}M AGO';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}H AGO';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays}D AGO';
    }

    const List<String> shortMonths = <String>[
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    final String month = shortMonths[(date.month - 1).clamp(0, 11)];
    return '${date.day} $month';
  }

  @override
  Widget build(BuildContext context) {
    final _TileVisual visual = _tileVisual();
    final _DirectionChipStyle directionChip = _directionChipStyle();

    return GestureDetector(
      onTap: () {
        callNextScreen(context, TransactionDetailScreen(transaction: data));
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(22),
          border: visual.showAccent
              ? Border(left: BorderSide(width: 4, color: AppColors.red))
              : Border(left: BorderSide(color: AppColors.primary, width: 4)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, 14, 14, 14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: visual.iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(visual.icon, color: visual.iconColor, size: 24),
              ),
              sbw(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 22,
                      child: MarqueePlus(
                        text: data.displaySenderLabel,
                        initialDelay: Duration(seconds: 2),
                        velocity: 25,
                        pauseAfterRound: Duration(milliseconds: 900),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2427),
                        ),
                      ),
                    ),
                    sb(6),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: directionChip.backgroundColor,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: CommonText(
                            directionChip.label,
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                              color: directionChip.textColor,
                            ),
                          ),
                        ),
                        sbw(8),
                        Flexible(
                          child: CommonText(
                            _relativeTime(data.transactionDate),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.sp,
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF55657A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              sbw(10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CommonText(
                    data.formattedSignedAmount,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: visual.amountColor,
                    ),
                  ),
                  sb(4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: visual.trailingBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CommonText(
                      visual.trailingText,
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: visual.trailingTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LedgerListEntry {
  final String? sectionTitle;
  final SmsTransaction? transaction;

  const _LedgerListEntry.section(this.sectionTitle) : transaction = null;

  const _LedgerListEntry.transaction(this.transaction) : sectionTitle = null;

  bool get isSection => sectionTitle != null;
}

class _TileVisual {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final Color amountColor;
  final String trailingText;
  final Color trailingTextColor;
  final Color trailingBackground;
  final bool showAccent;

  const _TileVisual({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.amountColor,
    required this.trailingText,
    required this.trailingTextColor,
    required this.trailingBackground,
    required this.showAccent,
  });
}

class _DirectionChipStyle {
  final String label;
  final Color textColor;
  final Color backgroundColor;

  const _DirectionChipStyle({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
  });
}

class _StatusCard extends StatelessWidget {
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  const _StatusCard({
    required this.title,
    required this.description,
    this.actionLabel,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CommonText(
              title,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2529),
              ),
            ),
            sb(8),
            CommonText(
              description,
              style: TextStyle(
                fontSize: 13.sp,
                height: 1.35,
                fontWeight: FontWeight.w500,
                color: Color(0xFF5C6470),
              ),
            ),
            if (actionLabel != null && onActionPressed != null) ...[
              sb(14),
              SizedBox(
                height: 42,
                child: ElevatedButton(
                  onPressed: onActionPressed,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: CommonText(
                    actionLabel!,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
