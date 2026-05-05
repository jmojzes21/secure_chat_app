import 'package:flutter/material.dart';

class Dialogs {
  static void showSnackBar(BuildContext context, String message, {int duration = 4}) {
    var snackbar = SnackBar(
      showCloseIcon: true,
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: duration),
      content: Text(message),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackbar);
  }
}
