import 'package:flutter/material.dart';

import '../../../../shared/widgets/module_placeholder.dart';

class PendingPaymentsScreen extends StatelessWidget {
  const PendingPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholder(
      icon: Icons.receipt_long_rounded,
      message: 'Pagos pendientes',
    );
  }
}
