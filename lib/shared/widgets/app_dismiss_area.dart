import 'package:flutter/material.dart';

class AppDismissArea extends StatelessWidget {
  const AppDismissArea({
    super.key,
    required this.child,
    this.onDismiss,
    this.dismissKeyboard = true,
  });

  final Widget child;
  final VoidCallback? onDismiss;
  final bool dismissKeyboard;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (dismissKeyboard) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
        onDismiss?.call();
      },
      child: child,
    );
  }
}
