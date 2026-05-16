import 'package:flutter/material.dart';

import '../../../../shared/widgets/module_placeholder.dart';

class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholder(
      icon: Icons.point_of_sale_rounded,
      message: 'Ventas',
    );
  }
}
