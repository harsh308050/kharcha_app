import "package:flutter_screenutil/flutter_screenutil.dart";
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kharcha/components/common_button.dart';
import 'package:kharcha/components/common_number_pad.dart';
import 'package:kharcha/components/common_text.dart';
import 'package:kharcha/utils/drive/drive_backup_service.dart';
import 'package:kharcha/utils/sms/sms_transaction.dart';
import 'package:kharcha/utils/constants/app_colors.dart';
import 'package:kharcha/utils/my_cm.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  static const List<String> _monthShortNames = <String>[
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

  final List<_CategoryItemData> _categories = const <_CategoryItemData>[
    _CategoryItemData(label: 'Food', icon: Icons.restaurant),
    _CategoryItemData(label: 'Travel', icon: Icons.flight_takeoff),
    _CategoryItemData(label: 'Shopping', icon: Icons.shopping_bag_outlined),
    _CategoryItemData(label: 'Leisure', icon: Icons.sports_esports_outlined),
    _CategoryItemData(
      label: 'Transport',
      icon: Icons.directions_car_filled_outlined,
    ),
    _CategoryItemData(label: 'Health', icon: Icons.local_hospital_outlined),
    _CategoryItemData(label: 'Education', icon: Icons.school_outlined),
    _CategoryItemData(label: 'Bills', icon: Icons.receipt_long_outlined),
    _CategoryItemData(label: 'Other', icon: Icons.category_outlined),
  ];

  int _selectedCategory = 0;
  String _amount = '0';
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  bool _isDebit = true; // true = Expense (debit), false = Income (credit)
  bool _isSavingTransaction = false;
  bool _isMethodDropdownOpen = false;
  final DriveBackupService _driveBackupService = DriveBackupService();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _methodDropdownKey = GlobalKey();
  final TextEditingController _merchantController = TextEditingController();
  static const List<String> _methodOptions = <String>[
    'UPI',
    'NEFT',
    'IMPS',
    'BANK TRANSFER',
    'CARD',
    'WALLET',
    'OTHER',
  ];
  String _selectedMethod = 'UPI';

  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _selectedTime = TimeOfDay.fromDateTime(now);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _merchantController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _toggleMethodDropdown() {
    setState(() {
      _isMethodDropdownOpen = !_isMethodDropdownOpen;
    });

    if (_isMethodDropdownOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final BuildContext? targetContext = _methodDropdownKey.currentContext;
        if (targetContext == null) {
          return;
        }
        Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          alignment: 0.18,
        );
      });
    }
  }

  void _onKeyTap(String key) {
    setState(() {
      if (key == 'del') {
        if (_amount.isNotEmpty) {
          _amount = _amount.substring(0, _amount.length - 1);
        }
        if (_amount.isEmpty) {
          _amount = '0';
        }
        return;
      }

      if (_amount == '0') {
        _amount = '';
      }

      if (key == '.') {
        if (_amount.contains('.')) {
          return;
        }
        if (_amount.isEmpty) {
          _amount = '0';
        }
        _amount = '$_amount.';
        return;
      }

      // Limit to 8 digits (before and after decimal)
      final String tempAmount = '$_amount$key';
      final List<String> parts = tempAmount.split('.');
      final String integerPart = parts[0];
      
      // Check if we would exceed 8 total digits
      if (integerPart.replaceFirst(RegExp(r'^0+'), '').length > 8) {
        return;
      }

      _amount = tempAmount;
    });
  }

  Future<void> _pickDate() async {
    DateTime tempDate = _selectedDate;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return _CupertinoPickerSheet(
          title: 'Select Date',
          onDone: () {
            setState(() {
              _selectedDate = tempDate;
            });
            Navigator.of(context).pop();
          },
          child: CupertinoTheme(
            data: CupertinoThemeData(
              primaryColor: AppColors.primary,
              textTheme: CupertinoTextThemeData(
                dateTimePickerTextStyle: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: _selectedDate,
              minimumDate: DateTime(DateTime.now().year - 10),
              maximumDate: DateTime(DateTime.now().year + 10),
              onDateTimeChanged: (DateTime value) {
                tempDate = value;
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickTime() async {
    DateTime tempTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return _CupertinoPickerSheet(
          title: 'Select Time',
          onDone: () {
            setState(() {
              _selectedTime = TimeOfDay(
                hour: tempTime.hour,
                minute: tempTime.minute,
              );
            });
            Navigator.of(context).pop();
          },
          child: CupertinoTheme(
            data: CupertinoThemeData(
              primaryColor: AppColors.primary,
              textTheme: CupertinoTextThemeData(
                dateTimePickerTextStyle: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time,
              use24hFormat: true,
              initialDateTime: tempTime,
              onDateTimeChanged: (DateTime value) {
                tempTime = value;
              },
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${_monthShortNames[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final String period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final String hour = time.hour.toString().padLeft(2, '0');
    final String minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  DateTime get _selectedDateTime {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  Future<void> _saveTransactionToDrive() async {
    if (_isSavingTransaction) {
      return;
    }

    final String merchant = _merchantController.text.trim();
    final String method = _selectedMethod.trim();
    final String note = _noteController.text.trim();

    final double? parsedAmount = double.tryParse(_amount);

    if (parsedAmount == null || parsedAmount <= 0) {
      showSnackBar(context, 'Please enter a valid amount.', AppColors.red);
      return;
    }

    if (merchant.isEmpty ||
        method.isEmpty ||
        note.isEmpty) {
      showSnackBar(
        context,
        'Please fill all required transaction details.',
        AppColors.red,
      );
      return;
    }

    setState(() {
      _isSavingTransaction = true;
    });

    final DateTime transactionDate = _selectedDateTime;
    final String selectedCategory = _categories[_selectedCategory].label;
    final String generatedReference =
      'manual-${transactionDate.millisecondsSinceEpoch}-${parsedAmount.toStringAsFixed(2).replaceAll('.', '')}';
    final SmsTransaction transaction = SmsTransaction(
      rawMessage:
          '[MANUAL] ${_isDebit ? 'Debit' : 'Credit'} ₹${parsedAmount.toStringAsFixed(2)} via $method on ${_formatDate(_selectedDate)} ${_formatTime(_selectedTime)}. Merchant: $merchant. Note: $note',
      senderId: merchant,
      smsDate: transactionDate,
      type: _isDebit ? SmsTransactionType.debit : SmsTransactionType.credit,
      method: method,
      amount: parsedAmount,
      balance: 0,
      currency: 'INR',
      bank: '',
      account: '',
      counterparty: merchant,
      reference: generatedReference,
      date: _formatDate(_selectedDate),
      category: selectedCategory,
      note: note,
    );

    try {
      final DriveBackupResult result = await _driveBackupService
          .backupTransactionsToDrive(<SmsTransaction>[transaction]);

      if (!mounted) {
        return;
      }

      if (result.success) {
        showSnackBar(context, 'Transaction added to Drive.', AppColors.primary);
        Navigator.of(context).pop(true);
      } else {
        showSnackBar(context, result.message, AppColors.red);
      }
    } catch (_) {
      if (mounted) {
        showSnackBar(
          context,
          'Failed to add transaction. Please try again.',
          AppColors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingTransaction = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(
                18,
                8,
                18,
                24 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: Color(0xFF3E4343),
                      size: 26,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: CommonText(
                        _isDebit ? 'Add Expense' : 'Add Income',
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF202626),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 48.w),
                ],
              ),
              sb(18),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isDebit = true;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: _isDebit ? AppColors.primary : Colors.transparent,
                              width: _isDebit ? 3 : 0,
                            ),
                          ),
                        ),
                        child: Center(
                          child: CommonText(
                            'Expense',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: _isDebit ? AppColors.primary : Color(0xFF8B98A5),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isDebit = false;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: !_isDebit ? AppColors.primary : Colors.transparent,
                              width: !_isDebit ? 3 : 0,
                            ),
                          ),
                        ),
                        child: Center(
                          child: CommonText(
                            'Income',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: !_isDebit ? AppColors.primary : Color(0xFF8B98A5),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              sb(24),
              Center(
                child: CommonText(
                  'TOTAL AMOUNT',
                  style: TextStyle(
                    fontSize: 12.sp,
                    letterSpacing: 2.2,
                    color: Color(0xFF6B7070),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              sb(6),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: CommonText(
                          '₹',
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF9EA1A1),
                        ),
                      ),
                    ),
                    CommonText(
                      _amount,
                      style: TextStyle(
                        fontSize: 54.sp,
                        height: 0.95,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111516),
                      ),
                    ),
                  ],
                ),
              ),
              sb(22),
              CommonText(
                'SELECT CATEGORY',
                style: TextStyle(
                  fontSize: 12.sp,
                  letterSpacing: 2.0,
                  color: Color(0xFF5E6464),
                  fontWeight: FontWeight.w500,
                ),
              ),
              sb(14),
              SizedBox(
                height: 104,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                    itemCount: _categories.length,
                      separatorBuilder: (_, _) => sbw(2),
                  itemBuilder: (BuildContext context, int index) {
                    final bool isSelected = _selectedCategory == index;
                    final _CategoryItemData item = _categories[index];

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = index;
                        });
                      },
                      child: SizedBox(
                        width: 78,
                        child: Column(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : const Color(0xFFEAECEA),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.26,
                                          ),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Icon(
                                item.icon,
                                size: 24,
                                color: isSelected
                                    ? AppColors.white
                                    : const Color(0xFF505554),
                              ),
                            ),
                            sb(6),
                            CommonText(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? AppColors.primary
                                    : const Color(0xFF4A4F4F),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              sb(14),
              Row(
                children: [
                  Expanded(
                    child: _InfoCard(
                      title: 'DATE',
                      value: _formatDate(_selectedDate),
                      icon: Icons.calendar_today_outlined,
                      onTap: _pickDate,
                    ),
                  ),
                  sbw(14),
                  Expanded(
                    child: _InfoCard(
                      title: 'TIME',
                      value: _formatTime(_selectedTime),
                      icon: Icons.access_time_outlined,
                      onTap: _pickTime,
                    ),
                  ),
                ],
              ),
              sb(12),
              _FormInputCard(
                title: 'MERCHANT',
                hintText: 'Where did you spend it?',
                controller: _merchantController,
                icon: Icons.storefront_outlined,
              ),
              sb(12),
              _MethodDropdownCard(
                key: _methodDropdownKey,
                title: 'METHOD',
                value: _selectedMethod,
                options: _methodOptions,
                icon: Icons.payments_outlined,
                isExpanded: _isMethodDropdownOpen,
                onToggle: _toggleMethodDropdown,
                onChanged: (String value) {
                  setState(() {
                    _selectedMethod = value;
                    _isMethodDropdownOpen = false;
                  });
                },
              ),
              sb(12),
              
              sb(12),
              _NoteCard(controller: _noteController),
              sb(12),
              SizedBox(
                height: 280,
                child: CommonNumberPad(onKeyTap: _onKeyTap),
              ),
              sb(16),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  onButtonPressed: _saveTransactionToDrive,
                  buttonText: 'Add Transaction',
                  isLoading: _isSavingTransaction,
                  borderRadius: 36,
                  backgroundColor: AppColors.primary,
                  textColor: AppColors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              sb(12),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CategoryItemData {
  final String label;
  final IconData icon;

  const _CategoryItemData({required this.label, required this.icon});
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFEAECEA),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              sbw(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CommonText(
                      title,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        color: Color(0xFF5F6565),
                      ),
                    ),
                    sb(2),
                    CommonText(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF202525),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final TextEditingController controller;

  const _NoteCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAECEA),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.notes_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          sbw(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CommonText(
                  'NOTE',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: Color(0xFF5F6565),
                  ),
                ),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.text,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF202525),
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'What was this for?',
                    hintStyle: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFAEB2B2),
                    ),
                    border: InputBorder.none,
                  ),
                  maxLines: 2,
                  minLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormInputCard extends StatelessWidget {
  final String title;
  final String hintText;
  final TextEditingController controller;
  final IconData icon;

  const _FormInputCard({
    required this.title,
    required this.hintText,
    required this.controller,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAECEA),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          sbw(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CommonText(
                  title,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: Color(0xFF5F6565),
                  ),
                ),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.text,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF202525),
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: hintText,
                    hintStyle: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFAEB2B2),
                    ),
                    border: InputBorder.none,
                  ),
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodDropdownCard extends StatelessWidget {
  final String title;
  final String value;
  final List<String> options;
  final IconData icon;
  final bool isExpanded;
  final VoidCallback onToggle;
  final ValueChanged<String> onChanged;

  const _MethodDropdownCard({
    super.key,
    required this.title,
    required this.value,
    required this.options,
    required this.icon,
    required this.isExpanded,
    required this.onToggle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: onToggle,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFEAECEA),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Row(
                children: [
                  Icon(icon, color: AppColors.primary, size: 24),
                  sbw(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CommonText(
                          title,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                            color: Color(0xFF5F6565),
                          ),
                        ),
                        sb(2),
                        CommonText(
                          value,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF202525),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: isExpanded ? 1 : 0),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          builder: (BuildContext context, double t, Widget? child) {
            return ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: t,
                child: Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, (1 - t) * -10),
                    child: Padding(
                      padding: EdgeInsets.only(top: 8 * t),
                      child: child,
                    ),
                  ),
                ),
              ),
            );
          },
          child: IgnorePointer(
            ignoring: !isExpanded,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE1E5E8)),
              ),
              child: Column(
                children: options.map((String option) {
                  final bool selected = option == value;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onChanged(option),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: CommonText(
                                option,
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight:
                                      selected ? FontWeight.w700 : FontWeight.w500,
                                  color: selected
                                      ? AppColors.primary
                                      : const Color(0xFF2A2F33),
                                ),
                              ),
                            ),
                            if (selected)
                              Icon(
                                Icons.check_rounded,
                                color: AppColors.primary,
                                size: 18,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CupertinoPickerSheet extends StatelessWidget {
  final String title;
  final VoidCallback onDone;
  final Widget child;

  const _CupertinoPickerSheet({
    required this.title,
    required this.onDone,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      color: AppColors.white,
      child: Column(
        children: [
          Container(
            color: AppColors.primaryLight,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                CupertinoButton(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: CommonText(
                    'Cancel',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: CommonText(
                      title,
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  onPressed: onDone,
                  child: CommonText(
                    'Done',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
