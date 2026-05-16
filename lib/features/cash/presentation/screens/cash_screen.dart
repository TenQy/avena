import 'package:flutter/material.dart';

import '../../../../shared/widgets/module_placeholder.dart';

class CashScreen extends StatelessWidget {
  const CashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholder(
      icon: Icons.account_balance_wallet_rounded,
      message: 'Caja',
    );
  }
}
