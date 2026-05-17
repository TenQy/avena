import 'package:flutter/material.dart';

final appSnackBarVisible = ValueNotifier<bool>(false);

void showAppSnackBar(BuildContext context, String message) {
  appSnackBarVisible.value = true;

  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message))).closed.whenComplete(() {
    appSnackBarVisible.value = false;
  });
}

class SnackBarAwareFab extends StatelessWidget {
  const SnackBarAwareFab({
    super.key,
    required this.child,
    this.baseBottom = 0,
    this.snackBarBottom = 56,
  });

  final Widget child;
  final double baseBottom;
  final double snackBarBottom;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: appSnackBarVisible,
      builder: (context, snackBarVisible, child) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            bottom: snackBarVisible ? snackBarBottom : baseBottom,
          ),
          child: child,
        );
      },
      child: child,
    );
  }
}
