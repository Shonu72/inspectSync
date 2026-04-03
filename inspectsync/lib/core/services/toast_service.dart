import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ToastService {
  static void showSuccess(String message) {
    _showToast(message, Colors.green);
  }

  static void showError(String message) {
    _showToast(message, Colors.red);
  }

  static void showInfo(String message) {
    _showToast(message, Colors.blue);
  }

  static void showWarning(String message) {
    _showToast(message, Colors.orange);
  }

  static void _showToast(String message, Color backgroundColor) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 2,
      backgroundColor: backgroundColor,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }
}
