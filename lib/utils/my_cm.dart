
import 'package:flutter/material.dart';
import 'package:kharcha/utils/constants/app_colors.dart';

showSnackBar(BuildContext context, String message, Color color) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.white),
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}


Widget sb(double dblSize) {
  return SizedBox(height: dblSize);
}

//Add sizebox with width
Widget sbw(double dblSize) {
  return SizedBox(width: dblSize);
}

void callNextScreen(BuildContext context, Widget nextScreen) {
  Navigator.push(context, MaterialPageRoute(builder: (context) => nextScreen));
}

Future callNextScreenWithResult(BuildContext context, Widget nextScreen) async {
  var action = await Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => nextScreen),
  );

  return action;
}

void callNextScreenAndClearStack(BuildContext context, Widget nextScreen) {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => nextScreen),
    (Route<dynamic> route) => false,
  );
}