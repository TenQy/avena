import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
    this.hasActiveItem = true,
    this.showDashboard = true,
    this.showCash = true,
  });

  final int currentIndex;
  final ValueChanged<int> onItemSelected;
  final bool hasActiveItem;
  final bool showDashboard;
  final bool showCash;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onItemSelected,
      selectedItemColor: hasActiveItem
          ? AppColors.textPrimary
          : AppColors.iconInactive,
      selectedLabelStyle: TextStyle(
        fontSize: 11,
        fontWeight: hasActiveItem ? FontWeight.w600 : FontWeight.normal,
      ),
      items: [
        if (showDashboard)
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.point_of_sale_rounded),
          label: 'Ventas',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2_rounded),
          label: 'Inventario',
        ),
        if (showCash)
          const BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Caja',
          ),
      ],
    );
  }
}
