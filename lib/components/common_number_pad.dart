import 'package:flutter/material.dart';
import 'package:kharcha/components/common_text.dart';

class CommonNumberPad extends StatelessWidget {
  final ValueChanged<String> onKeyTap;
  final Color backgroundColor;
  final Color borderColor;
  final TextStyle keyTextStyle;
  final IconData deleteIcon;
  final Color deleteIconColor;

  const CommonNumberPad({
    super.key,
    required this.onKeyTap,
    this.backgroundColor = const Color(0xFFEAECEA),
    this.borderColor = const Color(0xFFD4D8D8),
    this.keyTextStyle = const TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.w600,
      color: Color(0xFF232829),
    ),
    this.deleteIcon = Icons.backspace_outlined,
    this.deleteIconColor = const Color(0xFF232829),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(30),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                _NumberPadKey(
                  label: '1',
                  onTap: onKeyTap,
                  borderColor: borderColor,
                  textStyle: keyTextStyle,
                ),
                _NumberPadKey(
                  label: '2',
                  onTap: onKeyTap,
                  borderColor: borderColor,
                  textStyle: keyTextStyle,
                ),
                _NumberPadKey(
                  label: '3',
                  onTap: onKeyTap,
                  borderColor: borderColor,
                  textStyle: keyTextStyle,
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                _NumberPadKey(
                  label: '4',
                  onTap: onKeyTap,
                  borderColor: borderColor,
                  textStyle: keyTextStyle,
                ),
                _NumberPadKey(
                  label: '5',
                  onTap: onKeyTap,
                  borderColor: borderColor,
                  textStyle: keyTextStyle,
                ),
                _NumberPadKey(
                  label: '6',
                  onTap: onKeyTap,
                  borderColor: borderColor,
                  textStyle: keyTextStyle,
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                _NumberPadKey(
                  label: '7',
                  onTap: onKeyTap,
                  borderColor: borderColor,
                  textStyle: keyTextStyle,
                ),
                _NumberPadKey(
                  label: '8',
                  onTap: onKeyTap,
                  borderColor: borderColor,
                  textStyle: keyTextStyle,
                ),
                _NumberPadKey(
                  label: '9',
                  onTap: onKeyTap,
                  borderColor: borderColor,
                  textStyle: keyTextStyle,
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                _NumberPadKey(
                  label: '.',
                  onTap: onKeyTap,
                  borderColor: borderColor,
                  textStyle: keyTextStyle,
                ),
                _NumberPadKey(
                  label: '0',
                  onTap: onKeyTap,
                  borderColor: borderColor,
                  textStyle: keyTextStyle,
                ),
                _NumberPadDeleteKey(
                  onTap: () => onKeyTap('del'),
                  borderColor: borderColor,
                  backgroundColor: const Color(0xFFE5E8E8),
                  icon: deleteIcon,
                  iconColor: deleteIconColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberPadKey extends StatelessWidget {
  final String label;
  final ValueChanged<String> onTap;
  final Color borderColor;
  final TextStyle textStyle;

  const _NumberPadKey({
    required this.label,
    required this.onTap,
    required this.borderColor,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(label),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: borderColor, width: 1),
                bottom: BorderSide(color: borderColor, width: 1),
              ),
            ),
            child: Center(child: CommonText(label, style: textStyle)),
          ),
        ),
      ),
    );
  }
}

class _NumberPadDeleteKey extends StatelessWidget {
  final VoidCallback onTap;
  final Color borderColor;
  final Color backgroundColor;
  final IconData icon;
  final Color iconColor;

  const _NumberPadDeleteKey({
    required this.onTap,
    required this.borderColor,
    required this.backgroundColor,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: backgroundColor,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: borderColor, width: 1),
                top: BorderSide(color: borderColor, width: 1),
              ),
            ),
            child: Center(child: Icon(icon, color: iconColor, size: 30)),
          ),
        ),
      ),
    );
  }
}
