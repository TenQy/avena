import 'package:flutter/material.dart';

import '../../../../shared/widgets/module_placeholder.dart';

class CalculatorScreen extends StatelessWidget {
  const CalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholder(
      icon: Icons.calculate_rounded,
      message: 'Calculadora',
    );
  }
}
