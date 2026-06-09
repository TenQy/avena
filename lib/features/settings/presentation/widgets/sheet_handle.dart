import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';

class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.borderFor(context),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
