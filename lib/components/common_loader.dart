import 'package:flutter/material.dart';
import 'package:kharcha/utils/constants/app_colors.dart';


class CustomLoader extends StatelessWidget {
  final Color? color;
  const CustomLoader({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(color: color ?? AppColors.white),
    );
  }
}