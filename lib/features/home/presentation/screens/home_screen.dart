import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/empty_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppHeader(title: AppConstants.appName),
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: EmptyState(
          icon: Icons.storefront_rounded,
          message: 'Base del proyecto lista',
          description: 'Las funciones se agregarán en fases posteriores.',
        ),
      ),
    );
  }
}
