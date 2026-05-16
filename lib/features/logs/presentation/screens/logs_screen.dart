import 'package:flutter/material.dart';

import '../../../../shared/widgets/module_placeholder.dart';

class LogsScreen extends StatelessWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholder(
      icon: Icons.history_rounded,
      message: 'Logs',
    );
  }
}
