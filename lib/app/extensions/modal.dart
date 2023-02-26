import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';

extension BuildContextX on BuildContext {
  void showLoading() {
    BotToast.showLoading();
  }

  void closeLoading() {
    BotToast.closeAllLoading();
  }

  void showSnackbar(String? error) {
    const defaultError = 'Something went wrong please try again later';
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(error ?? defaultError),
      ),
    );
  }
}
