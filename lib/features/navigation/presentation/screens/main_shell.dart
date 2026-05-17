import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_roles.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/app_nav_bar.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../authentication/providers/auth_provider.dart';
import '../../../calculator/presentation/screens/calculator_screen.dart';
import '../../../cash/presentation/screens/cash_screen.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../../inventory/presentation/screens/inventory_screen.dart';
import '../../../logs/presentation/screens/logs_screen.dart';
import '../../../pending_payments/presentation/screens/pending_payments_screen.dart';
import '../../../sales/presentation/screens/sales_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../users/presentation/screens/users_screen.dart';

enum MainModule {
  dashboard,
  sales,
  inventory,
  cash,
  users,
  pendingPayments,
  calculator,
  logs,
  settings,
}

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  MainModule _selectedModule = MainModule.dashboard;

  int get _currentNavIndex {
    return switch (_selectedModule) {
      MainModule.dashboard => 0,
      MainModule.sales => 1,
      MainModule.inventory => 2,
      MainModule.cash => 3,
      _ => 0,
    };
  }

  bool get _hasActiveNavItem {
    return switch (_selectedModule) {
      MainModule.dashboard ||
      MainModule.sales ||
      MainModule.inventory ||
      MainModule.cash => true,
      _ => false,
    };
  }

  String get _title {
    return switch (_selectedModule) {
      MainModule.dashboard => 'Dashboard',
      MainModule.sales => 'Ventas',
      MainModule.inventory => 'Inventarios',
      MainModule.cash => 'Caja',
      MainModule.users => 'Usuarios',
      MainModule.pendingPayments => 'Pagos pendientes',
      MainModule.calculator => 'Calculadora',
      MainModule.logs => 'Logs',
      MainModule.settings => 'Configuración',
    };
  }

  Widget get _screen {
    return switch (_selectedModule) {
      MainModule.dashboard => const DashboardScreen(),
      MainModule.sales => const SalesScreen(),
      MainModule.inventory => const InventoryScreen(),
      MainModule.cash => const CashScreen(),
      MainModule.users => const UsersScreen(),
      MainModule.pendingPayments => const PendingPaymentsScreen(),
      MainModule.calculator => const CalculatorScreen(),
      MainModule.logs => const LogsScreen(),
      MainModule.settings => const SettingsScreen(),
    };
  }

  void _onNavSelected(int index) {
    setState(() {
      _selectedModule = switch (index) {
        0 => MainModule.dashboard,
        1 => MainModule.sales,
        2 => MainModule.inventory,
        _ => MainModule.cash,
      };
    });
  }

  void _selectOtherModule(MainModule module) {
    Navigator.of(context).pop();
    setState(() {
      _selectedModule = module;
    });
  }

  Future<void> _logout() async {
    final shouldLogout = await ConfirmDialog.show(
      context,
      title: 'Cerrar sesión',
      message: '¿Quieres cerrar tu sesión actual?',
      confirmLabel: 'Cerrar sesión',
      icon: Icons.logout_rounded,
    );

    if (!mounted || !shouldLogout) {
      return;
    }

    Navigator.of(context).pop();
    await ref.read(authProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    final drawerWidth = MediaQuery.sizeOf(context).width * 0.84;
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final currentRole = currentUser?.role;
    final canManageUsers =
        currentRole != null && AppRoles.canManageUsers(currentRole);
    final canViewLogs =
        currentRole != null && AppRoles.canViewLogs(currentRole);
    final canUseCalculator =
        currentRole != null && AppRoles.isAdminRole(currentRole);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppHeader(
        title: _title,
        actions: [
          IconButton(
            tooltip: 'Mas modulos',
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      endDrawer: Drawer(
        width: drawerWidth,
        backgroundColor: AppColors.cardSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.headerNav,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border, width: 0.5),
                      ),
                      child: const Icon(
                        Icons.apps_rounded,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Más modulos',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar',
                      icon: const Icon(Icons.close_rounded),
                      color: AppColors.textPrimary,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const _DrawerSeparator(),
                if (canManageUsers)
                  _OtherModuleTile(
                    icon: Icons.group_rounded,
                    label: 'Usuarios',
                    selected: _selectedModule == MainModule.users,
                    onTap: () => _selectOtherModule(MainModule.users),
                  ),
                _OtherModuleTile(
                  icon: Icons.receipt_long_rounded,
                  label: 'Pagos pendientes',
                  selected: _selectedModule == MainModule.pendingPayments,
                  onTap: () => _selectOtherModule(MainModule.pendingPayments),
                ),
                if (canUseCalculator)
                  _OtherModuleTile(
                    icon: Icons.calculate_rounded,
                    label: 'Calculadora',
                    selected: _selectedModule == MainModule.calculator,
                    onTap: () => _selectOtherModule(MainModule.calculator),
                  ),
                if (canViewLogs)
                  _OtherModuleTile(
                    icon: Icons.history_rounded,
                    label: 'Logs',
                    selected: _selectedModule == MainModule.logs,
                    onTap: () => _selectOtherModule(MainModule.logs),
                  ),
                const Spacer(),
                const _DrawerSeparator(),
                _OtherModuleTile(
                  icon: Icons.settings_rounded,
                  label: 'Configuración',
                  selected: _selectedModule == MainModule.settings,
                  onTap: () => _selectOtherModule(MainModule.settings),
                ),
                _DrawerActionTile(
                  icon: Icons.logout_rounded,
                  label: 'Cerrar sesión',
                  onTap: _logout,
                ),
              ],
            ),
          ),
        ),
      ),
      body: _screen,
      bottomNavigationBar: AppNavBar(
        currentIndex: _currentNavIndex,
        hasActiveItem: _hasActiveNavItem,
        onItemSelected: _onNavSelected,
      ),
    );
  }
}

class _DrawerSeparator extends StatelessWidget {
  const _DrawerSeparator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Divider(height: 1, thickness: 0.5, color: AppColors.border),
    );
  }
}

class _OtherModuleTile extends StatelessWidget {
  const _OtherModuleTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: selected ? AppColors.headerNav : AppColors.bodyBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Icon(
          icon,
          color: selected ? AppColors.textPrimary : AppColors.iconInactive,
          size: 22,
        ),
      ),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: selected ? AppColors.textPrimary : AppColors.textSecondary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.iconInactive,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      tileColor: selected ? AppColors.headerNav : AppColors.cardSurface,
      onTap: onTap,
    );
  }
}

class _DrawerActionTile extends StatelessWidget {
  const _DrawerActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.bodyBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Icon(icon, color: AppColors.iconInactive, size: 22),
      ),
      title: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      tileColor: AppColors.cardSurface,
      onTap: onTap,
    );
  }
}
