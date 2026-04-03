import "package:flutter_screenutil/flutter_screenutil.dart";
import 'package:flutter/material.dart';
import 'package:kharcha/components/common_button.dart';
import 'package:kharcha/components/common_text.dart';
import 'package:kharcha/utils/drive/drive_backup_service.dart';
import 'package:kharcha/utils/constants/app_colors.dart';
import 'package:kharcha/utils/constants/app_icons.dart';
import 'package:kharcha/utils/constants/app_strings.dart';
import 'package:kharcha/utils/sms/sms_transaction.dart';
import 'package:kharcha/utils/my_cm.dart';

class TransactionDetailScreen extends StatefulWidget {
  final SmsTransaction transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  static const List<String> _categoryOptions = <String>[
    'Food',
    'Travel',
    'Shopping',
    'Leisure',
    'Transport',
    'Bills',
    'Salary',
    'Other',
  ];

  late String _merchant;
  late String _category;
  late String _note;

  bool _isEditingMerchant = false;
  bool _isEditingCategory = false;
  bool _isEditingNote = false;
  bool _isRawSmsExpanded = true;
  bool _isSaving = false;
  bool _isDeleting = false;

  final DriveBackupService _driveBackupService = DriveBackupService();

  late final TextEditingController _merchantController;
  late final TextEditingController _noteController;
  late final FocusNode _merchantFocusNode;
  late final FocusNode _noteFocusNode;

  @override
  void initState() {
    super.initState();
    _merchant = widget.transaction.displaySenderLabel;
    _category = widget.transaction.category.trim().isEmpty
        ? (widget.transaction.isDebit ? 'Other' : 'Income')
        : widget.transaction.category.trim();
    final String existingNote = widget.transaction.note.trim();
    if (existingNote.isNotEmpty) {
      _note = existingNote;
    } else {
      final String method = widget.transaction.method.trim();
      _note = method.isEmpty ? 'Imported from SMS' : 'Imported via $method SMS';
    }

    _merchantController = TextEditingController(text: _merchant);
    _noteController = TextEditingController(text: _note);
    _merchantFocusNode = FocusNode();
    _noteFocusNode = FocusNode();
  }

  bool get _isManualTransaction {
    return widget.transaction.reference.trim().toLowerCase().startsWith('manual-') ||
        widget.transaction.rawMessage.trim().toUpperCase().startsWith('[MANUAL]');
  }

  Future<void> _saveChanges() async {
    if (_isSaving) {
      return;
    }

    final String updatedMerchant = _merchantController.text.trim().isEmpty
        ? _merchant
        : _merchantController.text.trim();
    final String updatedNote = _noteController.text.trim().isEmpty
        ? _note
        : _noteController.text.trim();

    final SmsTransaction updated = widget.transaction.copyWith(
      senderId: updatedMerchant,
      counterparty: updatedMerchant,
      category: _category,
      note: updatedNote,
    );

    setState(() {
      _isSaving = true;
    });

    try {
      final DriveBackupResult result = await _driveBackupService
          .updateTransactionInDrive(
            original: widget.transaction,
            updated: updated,
          );
      if (!mounted) {
        return;
      }

      if (!result.success) {
        showSnackBar(context, result.message, AppColors.red);
        return;
      }

      setState(() {
        _merchant = updatedMerchant;
        _note = updatedNote;
        _isEditingMerchant = false;
        _isEditingCategory = false;
        _isEditingNote = false;
      });

      showSnackBar(context, 'Transaction updated', AppColors.primary);
      Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        showSnackBar(context, 'Failed to update transaction', AppColors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteTransaction() async {
    if (_isDeleting || !_isManualTransaction) {
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete transaction?'),
          content: const Text('This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      final DriveBackupResult result = await _driveBackupService
          .deleteTransactionFromDrive(transaction: widget.transaction);
      if (!mounted) {
        return;
      }

      if (!result.success) {
        showSnackBar(context, result.message, AppColors.red);
        return;
      }

      showSnackBar(context, 'Transaction deleted', AppColors.primary);
      Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        showSnackBar(context, 'Failed to delete transaction', AppColors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _noteController.dispose();
    _merchantFocusNode.dispose();
    _noteFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _AmountParts amountParts =
        _splitAmount(widget.transaction.formattedSignedAmount);

    return Scaffold(
      backgroundColor: AppColors.whiteBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(AppIcons.arrowBackIos, color: Color(0xFF5B6876)),
                  ),
                  Expanded(
                    child: CommonText(
                      AppStrings.transactionDetail,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26.sp,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E2327),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.share_outlined, color: Color(0xFF5B6876)),
                  ),
                ],
              ),
              sb(16),
              Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD5E6E1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 14, color: AppColors.primary),
                      sbw(6),
                      CommonText(
                        _transactionTagLabel(),
                        style: TextStyle(
                          fontSize: 11.sp,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              sb(14),
              Center(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: amountParts.main,
                        style: TextStyle(
                          fontSize: 44.sp,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1D2124),
                        ),
                      ),
                      TextSpan(
                        text: amountParts.decimal,
                        style: TextStyle(
                          fontSize: 36.sp,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFA1ABB6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              sb(4),
              Center(
                child: CommonText(
                  widget.transaction.formattedDateTime,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5D6C7F),
                  ),
                ),
              ),
              sb(18),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Icons.shopping_bag_outlined,
                      title: 'MERCHANT',
                      value: _merchant,
                      isEditing: _isEditingMerchant,
                      textController: _merchantController,
                      textFocusNode: _merchantFocusNode,
                      onEditTap: () {
                        final bool willEdit = !_isEditingMerchant;
                        setState(() {
                          _isEditingMerchant = willEdit;
                          _merchantController.text = _merchant;
                        });
                        if (willEdit) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              _merchantFocusNode.requestFocus();
                            }
                          });
                        } else {
                          _merchantFocusNode.unfocus();
                        }
                      },
                      onEditingComplete: () {
                        setState(() {
                          _merchant = _merchantController.text.trim().isEmpty
                              ? _merchant
                              : _merchantController.text.trim();
                          _isEditingMerchant = false;
                        });
                      },
                    ),
                    sb(14),
                    _DetailRow(
                      icon: Icons.category_outlined,
                      title: AppStrings.category,
                      value: _category,
                      isEditing: _isEditingCategory,
                      onEditTap: () {
                        setState(() {
                          _isEditingCategory = !_isEditingCategory;
                        });
                      },
                      editorChild: _CategorySelector(
                        options: _categoryOptions,
                        selected: _category,
                        onSelected: (String value) {
                          setState(() {
                            _category = value;
                            _isEditingCategory = false;
                          });
                        },
                      ),
                    ),
                    sb(14),
                    _DetailRow(
                      icon: Icons.notes_rounded,
                      title: 'NOTE',
                      value: _note,
                      isMultiLine: true,
                      isEditing: _isEditingNote,
                      textController: _noteController,
                      textFocusNode: _noteFocusNode,
                      onEditTap: () {
                        final bool willEdit = !_isEditingNote;
                        setState(() {
                          _isEditingNote = willEdit;
                          _noteController.text = _note;
                        });
                        if (willEdit) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              _noteFocusNode.requestFocus();
                            }
                          });
                        } else {
                          _noteFocusNode.unfocus();
                        }
                      },
                      onEditingComplete: () {
                        setState(() {
                          _note = _noteController.text.trim().isEmpty
                              ? _note
                              : _noteController.text.trim();
                          _isEditingNote = false;
                        });
                      },
                    ),
                  ],
                ),
              ),
              sb(18),
              InkWell(
                onTap: () {
                  setState(() {
                    _isRawSmsExpanded = !_isRawSmsExpanded;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.sms_outlined, size: 14, color: Color(0xFF5B6876)),
                      sbw(8),
                       CommonText(
                        AppStrings.showRawSMSSource,
                        style: TextStyle(
                          fontSize: 14.sp,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF5B6876),
                        ),
                      ),
                      sbw(4),
                      Icon(
                        _isRawSmsExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 18,
                        color: const Color(0xFF5B6876),
                      ),
                    ],
                  ),
                ),
              ),
              sb(10),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 220),
                crossFadeState: _isRawSmsExpanded
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E2E4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: CommonText(
                    widget.transaction.rawMessage,
                    style: TextStyle(
                      fontSize: 13.sp,
                      height: 1.45,
                      letterSpacing: 0.2,
                      color: Color(0xFF4A5B70),
                    ),
                  ),
                ),
                secondChild: SizedBox.shrink(),
              ),
              sb(24),
              CustomButton(
                onButtonPressed: _isManualTransaction ? _deleteTransaction : () {},
                buttonText: 'Delete Transaction',
                isLoading: _isDeleting,
                borderColor: AppColors.red,
                borderRadius: 16,
                backgroundColor: _isManualTransaction
                    ? AppColors.white
                    : const Color(0xFFF4F4F4),
                borderWidth: 1,
                textColor: _isManualTransaction ? AppColors.red : const Color(0xFFB8BEC6),
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                showPrefixIcon: true,
                prefixIcon: Icon(
                  Icons.delete_outline,
                  color: _isManualTransaction ? AppColors.red : const Color(0xFFB8BEC6),
                  size: 22,
                ),
              ),
              if (!_isManualTransaction)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: CommonText(
                    'Only manually added transactions can be deleted.',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF8A949E),
                    ),
                  ),
                ),
              sb(28),
              Center(
                child: SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    onButtonPressed: _saveChanges,
                    isLoading: _isSaving,
                    buttonText: AppStrings.saveChanges,
                    borderRadius: 26,
                    backgroundColor: AppColors.primary,
                    textColor: AppColors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    showPrefixIcon: true,
                    prefixIcon: Icon(Icons.check, color: AppColors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _AmountParts _splitAmount(String amount) {
    final String value = amount.replaceAll(' ', '');
    final int dotIndex = value.lastIndexOf('.');

    if (dotIndex == -1) {
      return _AmountParts(main: value, decimal: '.00');
    }

    return _AmountParts(
      main: value.substring(0, dotIndex),
      decimal: value.substring(dotIndex),
    );
  }

  String _transactionTagLabel() {
    if (!widget.transaction.isDebit) {
      return AppStrings.salary;
    }

    final String method = widget.transaction.method.trim().toUpperCase();
    return method.isEmpty ? AppStrings.tagNow : method;
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final bool isMultiLine;
  final bool isEditing;
  final TextEditingController? textController;
  final FocusNode? textFocusNode;
  final VoidCallback? onEditTap;
  final VoidCallback? onEditingComplete;
  final Widget? editorChild;

  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
    this.isMultiLine = false,
    this.isEditing = false,
    this.textController,
    this.textFocusNode,
    this.onEditTap,
    this.onEditingComplete,
    this.editorChild,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFE6E6E7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        sbw(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommonText(
                title,
                style: TextStyle(
                  fontSize: 12.sp,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6F7780),
                ),
              ),
              sb(2),
              if (isEditing && editorChild != null)
                editorChild!
              else if (isEditing && textController != null)
                TextField(
                  controller: textController,
                  focusNode: textFocusNode,
                  maxLines: isMultiLine ? 3 : 1,
                  minLines: 1,
                  textInputAction: TextInputAction.done,
                  onEditingComplete: onEditingComplete,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 6),
                    border: InputBorder.none,
                  ),
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF252A2F),
                  ),
                )
              else
                CommonText(
                  value,
                  maxLines: isMultiLine ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF252A2F),
                  ),
                ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onEditTap,
          child: Icon(
            isEditing ? Icons.check_rounded : Icons.edit_outlined,
            size: 20,
            color: isEditing ? AppColors.primary : const Color(0xFFAAB2B7),
          ),
        ),
      ],
    );
  }
}

class _CategorySelector extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  const _CategorySelector({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (BuildContext context, int index) {
          final String option = options[index];
          final bool isSelected = option == selected;
          return GestureDetector(
            onTap: () => onSelected(option),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : const Color(0xFFEAECEA),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: CommonText(
                option,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.white : const Color(0xFF4A4F4F),
                ),
              ),
            ),
          );
        },
        separatorBuilder: (BuildContext _, int index) => sbw(8),
        itemCount: options.length,
      ),
    );
  }
}

class _AmountParts {
  final String main;
  final String decimal;

  const _AmountParts({required this.main, required this.decimal});
}
