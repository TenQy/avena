import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

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
import '../../../inventory/presentation/controllers/inventory_screen_controller.dart';
import '../../../inventory/presentation/screens/inventory_screen.dart';
import '../../../logs/presentation/screens/logs_screen.dart';
import '../../../pending_payments/presentation/screens/pending_payments_screen.dart';
import '../../../sales/presentation/screens/sales_history_screen.dart';
import '../../../sales/presentation/screens/sales_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../users/presentation/screens/users_screen.dart';

enum MainModule {
  dashboard,
  sales,
  inventory,
  cash,
  salesHistory,
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
  final _inventoryController = InventoryScreenController();
  final _moduleBackStack = <MainModule>[];
  MainModule _selectedModule = MainModule.dashboard;

  @override
  void initState() {
    super.initState();
    _inventoryController.addListener(_onInventoryChanged);
  }

  @override
  void dispose() {
    _inventoryController.removeListener(_onInventoryChanged);
    _inventoryController.dispose();
    super.dispose();
  }

  void _onInventoryChanged() {
    if (!mounted || _selectedModule != MainModule.inventory) {
      return;
    }

    setState(() {});
  }

  List<MainModule> _primaryModulesForRole(String? role) {
    if (role != null && AppRoles.isAdminRole(role)) {
      return const [
        MainModule.dashboard,
        MainModule.sales,
        MainModule.inventory,
        MainModule.cash,
      ];
    }

    return const [MainModule.sales, MainModule.inventory];
  }

  bool _canAccessModule(String? role, MainModule module) {
    if (role == null) {
      return false;
    }

    return switch (module) {
      MainModule.dashboard => AppRoles.isAdminRole(role),
      MainModule.sales => AppRoles.canAccessSales(role),
      MainModule.inventory => AppRoles.canReadInventory(role),
      MainModule.cash => AppRoles.canManageCash(role),
      MainModule.salesHistory => AppRoles.canAccessSales(role),
      MainModule.users => AppRoles.canManageUsers(role),
      MainModule.pendingPayments => AppRoles.canAccessPendingPayments(role),
      MainModule.calculator => AppRoles.isAdminRole(role),
      MainModule.logs => AppRoles.canViewLogs(role),
      MainModule.settings => true,
    };
  }

  MainModule _defaultModuleForRole(String? role) {
    return _primaryModulesForRole(role).first;
  }

  int _currentNavIndex(List<MainModule> primaryModules) {
    final index = primaryModules.indexOf(_selectedModule);
    return index < 0 ? 0 : index;
  }

  String _titleFor(MainModule module) {
    return switch (module) {
      MainModule.dashboard => 'Dashboard',
      MainModule.sales => 'Ventas',
      MainModule.inventory => _inventoryController.title,
      MainModule.cash => 'Caja',
      MainModule.salesHistory => 'Historial de ventas',
      MainModule.users => 'Usuarios',
      MainModule.pendingPayments => 'Pagos pendientes',
      MainModule.calculator => 'Calculadora',
      MainModule.logs => 'Logs',
      MainModule.settings => 'Configuración',
    };
  }

  Widget _screenFor(MainModule module) {
    return switch (module) {
      MainModule.dashboard => const DashboardScreen(),
      MainModule.sales => const SalesScreen(),
      MainModule.inventory => InventoryScreen(controller: _inventoryController),
      MainModule.cash => const CashScreen(),
      MainModule.salesHistory => const SalesHistoryScreen(),
      MainModule.users => const UsersScreen(),
      MainModule.pendingPayments => const PendingPaymentsScreen(),
      MainModule.calculator => const CalculatorScreen(),
      MainModule.logs => const LogsScreen(),
      MainModule.settings => const SettingsScreen(),
    };
  }

  void _onNavSelected(int index, List<MainModule> primaryModules) {
    if (index < 0 || index >= primaryModules.length) {
      return;
    }

    _selectModule(primaryModules[index]);
  }

  void _selectOtherModule(MainModule module, String? role) {
    if (!_canAccessModule(role, module)) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context).pop();
    _selectModule(module);
  }

  void _selectModule(MainModule module) {
    if (module == _selectedModule) {
      return;
    }

    setState(() {
      _moduleBackStack.add(_selectedModule);
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

  Future<void> _handleSystemBack(MainModule effectiveModule) async {
    if (_scaffoldKey.currentState?.isEndDrawerOpen == true) {
      Navigator.of(context).pop();
      return;
    }

    if (effectiveModule == MainModule.inventory &&
        _inventoryController.canGoBack) {
      _inventoryController.closeCategory();
      return;
    }

    if (_moduleBackStack.isNotEmpty) {
      setState(() {
        _selectedModule = _moduleBackStack.removeLast();
      });
      return;
    }

    final shouldExit = await ConfirmDialog.show(
      context,
      title: 'Salir de la aplicación',
      message: '¿Quieres abandonar la aplicación?',
      confirmLabel: 'Salir',
      icon: Icons.exit_to_app_rounded,
    );

    if (!mounted || !shouldExit) {
      return;
    }

    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final drawerWidth = MediaQuery.sizeOf(context).width * 0.84;
    final cardSurface = AppColors.cardSurfaceFor(context);
    final headerNav = AppColors.headerNavFor(context);
    final textPrimary = AppColors.textPrimaryFor(context);
    final border = AppColors.borderFor(context);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final currentRole = currentUser?.role;
    final primaryModules = _primaryModulesForRole(currentRole);
    final effectiveModule = _canAccessModule(currentRole, _selectedModule)
        ? _selectedModule
        : _defaultModuleForRole(currentRole);

    if (effectiveModule != _selectedModule) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        setState(() {
          _selectedModule = effectiveModule;
        });
      });
    }

    final canManageUsers =
        currentRole != null && AppRoles.canManageUsers(currentRole);
    final canViewLogs =
        currentRole != null && AppRoles.canViewLogs(currentRole);
    final canUseCalculator =
        currentRole != null && AppRoles.isAdminRole(currentRole);
    final canManageCash =
        currentRole != null && AppRoles.canManageCash(currentRole);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }

        _handleSystemBack(effectiveModule);
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppHeader(
          title: _titleFor(effectiveModule),
          leading:
              effectiveModule == MainModule.inventory &&
                  _inventoryController.canGoBack
              ? IconButton(
                  tooltip: 'Volver a categorías',
                  icon: Icon(Icons.arrow_back_rounded),
                  onPressed: _inventoryController.closeCategory,
                )
              : null,
          actions: [
            IconButton(
              tooltip: 'Más módulos',
              icon: Icon(Icons.menu_rounded),
              onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
            ),
          ],
        ),
        endDrawer: Drawer(
          width: drawerWidth,
          backgroundColor: cardSurface,
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
                          color: headerNav,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: border, width: 0.5),
                        ),
                        child: Icon(Icons.apps_rounded, color: textPrimary),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Más módulos',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Cerrar',
                        icon: Icon(Icons.close_rounded),
                        color: textPrimary,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const _DrawerSeparator(),
                  _OtherModuleTile(
                    icon: Icons.receipt_long_rounded,
                    label: 'Historial de ventas',
                    selected: effectiveModule == MainModule.salesHistory,
                    onTap: () => _selectOtherModule(
                      MainModule.salesHistory,
                      currentRole,
                    ),
                  ),
                  if (canManageUsers)
                    _OtherModuleTile(
                      icon: Icons.group_rounded,
                      label: 'Usuarios',
                      selected: effectiveModule == MainModule.users,
                      onTap: () =>
                          _selectOtherModule(MainModule.users, currentRole),
                    ),
                  _OtherModuleTile(
                    icon: Icons.receipt_long_rounded,
                    label: 'Pagos pendientes',
                    selected: effectiveModule == MainModule.pendingPayments,
                    onTap: () => _selectOtherModule(
                      MainModule.pendingPayments,
                      currentRole,
                    ),
                  ),
                  if (canUseCalculator)
                    _OtherModuleTile(
                      icon: Icons.calculate_rounded,
                      label: 'Calculadora',
                      selected: effectiveModule == MainModule.calculator,
                      onTap: () => _selectOtherModule(
                        MainModule.calculator,
                        currentRole,
                      ),
                    ),
                  if (canViewLogs)
                    _OtherModuleTile(
                      icon: Icons.history_rounded,
                      label: 'Logs',
                      selected: effectiveModule == MainModule.logs,
                      onTap: () =>
                          _selectOtherModule(MainModule.logs, currentRole),
                    ),
                  const Spacer(),
                  const _DrawerSeparator(),
                  if (currentRole != null)
                    _OtherModuleTile(
                      icon: Icons.settings_rounded,
                      label: 'Configuración',
                      selected: effectiveModule == MainModule.settings,
                      onTap: () =>
                          _selectOtherModule(MainModule.settings, currentRole),
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
        body: _screenFor(effectiveModule),
        bottomNavigationBar: AppNavBar(
          currentIndex: _currentNavIndex(primaryModules),
          hasActiveItem: primaryModules.contains(effectiveModule),
          showDashboard: primaryModules.contains(MainModule.dashboard),
          showCash: canManageCash,
          onItemSelected: (index) => _onNavSelected(index, primaryModules),
        ),
      ),
    );
  }
}

class _DrawerSeparator extends StatelessWidget {
  const _DrawerSeparator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Divider(
        height: 1,
        thickness: 0.5,
        color: AppColors.borderFor(context),
      ),
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
    final headerNav = AppColors.headerNavFor(context);
    final bodyBg = AppColors.bodyBgFor(context);
    final cardSurface = AppColors.cardSurfaceFor(context);
    final border = AppColors.borderFor(context);
    final textPrimary = AppColors.textPrimaryFor(context);
    final textSecondary = AppColors.textSecondaryFor(context);
    final iconInactive = AppColors.iconInactiveFor(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: selected ? headerNav : bodyBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border, width: 0.5),
        ),
        child: Icon(
          icon,
          color: selected ? textPrimary : iconInactive,
          size: 22,
        ),
      ),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: selected ? textPrimary : textSecondary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: iconInactive),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      tileColor: selected ? headerNav : cardSurface,
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
    final bodyBg = AppColors.bodyBgFor(context);
    final cardSurface = AppColors.cardSurfaceFor(context);
    final border = AppColors.borderFor(context);
    final textSecondary = AppColors.textSecondaryFor(context);
    final iconInactive = AppColors.iconInactiveFor(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: bodyBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border, width: 0.5),
        ),
        child: Icon(icon, color: iconInactive, size: 22),
      ),
      title: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: textSecondary),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      tileColor: cardSurface,
      onTap: onTap,
    );
  }
}
