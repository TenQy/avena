import 'package:flutter/material.dart';

import '../../../../shared/widgets/module_placeholder.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholder(
      icon: Icons.dashboard_rounded,
      message: 'Dashboard',
    );
  }
}
