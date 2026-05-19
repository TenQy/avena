import 'package:flutter/material.dart';

import '../../../../shared/theme/app_spacing.dart';
import '../widgets/sale_items_card.dart';
import '../widgets/sale_payment_methods_card.dart';
import '../widgets/sale_product_search_card.dart';
import '../widgets/sale_total_card.dart';

class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: const [
        SaleProductSearchCard(),
        SizedBox(height: AppSpacing.lg),
        SaleItemsCard(),
        SizedBox(height: AppSpacing.lg),
        SalePaymentMethodsCard(),
        SizedBox(height: AppSpacing.lg),
        SaleTotalCard(),
      ],
    );
  }
}
