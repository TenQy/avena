import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_activity_logs.dart';
import '../../../../core/constants/app_roles.dart';
import '../../../../core/database/app_database.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../authentication/providers/auth_provider.dart';
import '../../providers/logs_provider.dart';

class LogsScreen extends ConsumerWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    if (currentUser == null || !AppRoles.canViewLogs(currentUser.role)) {
      return const EmptyState(
        icon: Icons.lock_outline_rounded,
        message: 'Sin acceso',
        description: 'No tienes permisos para consultar logs.',
      );
    }

    final logsState = ref.watch(filteredLogsProvider);
    final allLogs =
        ref.watch(logsProvider).valueOrNull ?? const <ActivityLog>[];
    final filters = ref.watch(logsFiltersProvider);

    return Column(
      children: [
        _LogsFiltersBar(allLogs: allLogs, filters: filters),
        Expanded(
          child: logsState.when(
            data: (logs) {
              if (logs.isEmpty) {
                return const EmptyState(
                  icon: Icons.history_rounded,
                  message: 'Sin logs para mostrar',
                  description:
                      'Ajusta los filtros o realiza una acción en la app.',
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                ),
                itemBuilder: (context, index) => _LogCard(log: logs[index]),
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.md),
                itemCount: logs.length,
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const EmptyState(
              icon: Icons.error_outline_rounded,
              message: 'No se pudieron cargar los logs',
              description: 'Intenta nuevamente.',
            ),
          ),
        ),
      ],
    );
  }
}

class _LogsFiltersBar extends ConsumerWidget {
  const _LogsFiltersBar({required this.allLogs, required this.filters});

  final List<ActivityLog> allLogs;
  final LogsFilters filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = <String, ActivityLog>{};
    final actions = <String>{};

    for (final log in allLogs) {
      if (log.userId != null) {
        users.putIfAbsent(log.userId!, () => log);
      }
      actions.add(log.action);
    }

    final sortedUsers = users.values.toList()
      ..sort((a, b) => a.userNameSnapshot.compareTo(b.userNameSnapshot));
    final sortedActions = actions.toList()..sort();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useVerticalFilters = constraints.maxWidth < 560;

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  if (useVerticalFilters)
                    Column(
                      children: [
                        _UserFilterField(
                          filters: filters,
                          sortedUsers: sortedUsers,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _ActionFilterField(
                          filters: filters,
                          sortedActions: sortedActions,
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: _UserFilterField(
                            filters: filters,
                            sortedUsers: sortedUsers,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _ActionFilterField(
                            filters: filters,
                            sortedActions: sortedActions,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(child: _DateFilterButton(filters: filters)),
                      const SizedBox(width: AppSpacing.md),
                      TextButton(
                        onPressed: () {
                          ref.read(logsFiltersProvider.notifier).clear();
                        },
                        child: const Text('Limpiar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _UserFilterField extends ConsumerWidget {
  const _UserFilterField({required this.filters, required this.sortedUsers});

  final LogsFilters filters;
  final List<ActivityLog> sortedUsers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DropdownButtonFormField<String?>(
      initialValue: filters.userId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Usuario',
        prefixIcon: Icon(Icons.person_rounded),
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('Todos', overflow: TextOverflow.ellipsis),
        ),
        for (final userLog in sortedUsers)
          DropdownMenuItem<String?>(
            value: userLog.userId,
            child: Text(
              userLog.userNameSnapshot,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (value) {
        ref.read(logsFiltersProvider.notifier).setUserId(value);
      },
    );
  }
}

class _ActionFilterField extends ConsumerWidget {
  const _ActionFilterField({
    required this.filters,
    required this.sortedActions,
  });

  final LogsFilters filters;
  final List<String> sortedActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labels = ['Todas', ...sortedActions.map(_actionLabel)];

    return DropdownButtonFormField<String?>(
      initialValue: filters.action,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Acción',
        prefixIcon: Icon(Icons.tune_rounded),
      ),
      selectedItemBuilder: (context) {
        return [
          for (final label in labels)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
        ];
      },
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('Todas', overflow: TextOverflow.ellipsis),
        ),
        for (final action in sortedActions)
          DropdownMenuItem<String?>(
            value: action,
            child: Text(_actionLabel(action), overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (value) {
        ref.read(logsFiltersProvider.notifier).setAction(value);
      },
    );
  }
}

class _DateFilterButton extends ConsumerWidget {
  const _DateFilterButton({required this.filters});

  final LogsFilters filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () async {
        final currentDate = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          firstDate: DateTime(currentDate.year - 2),
          lastDate: currentDate,
          initialDate: filters.selectedDate ?? currentDate,
        );
        if (!context.mounted) {
          return;
        }
        ref.read(logsFiltersProvider.notifier).setDate(picked);
      },
      icon: Icon(Icons.calendar_today_rounded, size: 18),
      label: Text(
        filters.selectedDate == null
            ? 'Filtrar por fecha'
            : _dateLabel(filters.selectedDate!),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  const _LogCard({required this.log});

  final ActivityLog log;

  @override
  Widget build(BuildContext context) {
    final description = log.description?.trim();

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _showDetails(context),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.headerNavFor(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.borderFor(context),
                        width: 0.5,
                      ),
                    ),
                    child: Icon(
                      _iconFor(log.action),
                      color: AppColors.iconInactiveFor(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _actionLabel(log.action),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${log.userNameSnapshot} | ${_entityLabel(log.entityType)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.textSecondaryFor(context),
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    _timeLabel(log.createdAt),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.iconInactiveFor(context),
                    ),
                  ),
                ],
              ),
              if (description != null && description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDetails(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardSurfaceFor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderFor(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  _actionLabel(log.action),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: AppColors.borderFor(context),
                ),
                const SizedBox(height: AppSpacing.lg),
                _DetailRow(label: 'Usuario', value: log.userNameSnapshot),
                _DetailRow(label: 'Rol', value: log.userRoleSnapshot),
                _DetailRow(
                  label: 'Modulo',
                  value: _entityLabel(log.entityType),
                ),
                _DetailRow(
                  label: 'Fecha',
                  value: _fullDateLabel(log.createdAt),
                ),
                if (log.entityId != null)
                  _DetailRow(label: 'Referencia', value: log.entityId!),
                if ((log.description ?? '').trim().isNotEmpty)
                  _DetailRow(label: 'Detalle', value: log.description!),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.iconInactiveFor(context),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

String _actionLabel(String action) {
  switch (action) {
    case AppActivityLogActions.login:
      return 'Inicio de sesión';
    case AppActivityLogActions.logout:
      return 'Cierre de sesión';
    case AppActivityLogActions.openCash:
      return 'Apertura de caja';
    case AppActivityLogActions.closeCash:
      return 'Cierre de caja';
    case AppActivityLogActions.createCashMovement:
      return 'Movimiento de caja';
    case AppActivityLogActions.createUser:
      return 'Creación de usuario';
    case AppActivityLogActions.updateUser:
      return 'Edición de usuario';
    case AppActivityLogActions.setUserActive:
      return 'Cambio de estado de usuario';
    case AppActivityLogActions.deleteUser:
      return 'Eliminación de usuario';
    case AppActivityLogActions.createCategory:
      return 'Creación de categoría';
    case AppActivityLogActions.updateCategory:
      return 'Edicion de categoria';
    case AppActivityLogActions.createSubcategory:
      return 'Creación de subcategoría';
    case AppActivityLogActions.updateSubcategory:
      return 'Edicion de subcategoria';
    case AppActivityLogActions.deleteSubcategory:
      return 'Eliminación de subcategoría';
    case AppActivityLogActions.setMainCategory:
      return 'Categoría principal';
    case AppActivityLogActions.deleteCategory:
      return 'Eliminación de categoría';
    case AppActivityLogActions.createProduct:
      return 'Creación de producto';
    case AppActivityLogActions.updateProduct:
      return 'Edición de producto';
    case AppActivityLogActions.deleteProduct:
      return 'Eliminación de producto';
    case AppActivityLogActions.createSale:
      return 'Registro de venta';
    case AppActivityLogActions.editSale:
      return 'Edición de venta';
    case AppActivityLogActions.cancelSale:
      return 'Cancelacion de venta';
    case AppActivityLogActions.createPendingPayment:
      return 'Creación de pago pendiente';
    case AppActivityLogActions.createPaymentEntry:
      return 'Registro de abono';
    default:
      return action;
  }
}

String _entityLabel(String entityType) {
  switch (entityType) {
    case AppActivityLogEntities.session:
      return 'Sesión';
    case AppActivityLogEntities.cashSession:
      return 'Caja';
    case AppActivityLogEntities.cashMovement:
      return 'Caja';
    case AppActivityLogEntities.user:
      return 'Usuarios';
    case AppActivityLogEntities.category:
      return 'Inventario';
    case AppActivityLogEntities.subcategory:
      return 'Inventario';
    case AppActivityLogEntities.product:
      return 'Inventario';
    case AppActivityLogEntities.sale:
      return 'Ventas';
    case AppActivityLogEntities.pendingPayment:
      return 'Pagos pendientes';
    default:
      return entityType;
  }
}

IconData _iconFor(String action) {
  switch (action) {
    case AppActivityLogActions.login:
    case AppActivityLogActions.logout:
      return Icons.login_rounded;
    case AppActivityLogActions.openCash:
    case AppActivityLogActions.closeCash:
    case AppActivityLogActions.createCashMovement:
      return Icons.point_of_sale_rounded;
    case AppActivityLogActions.createUser:
    case AppActivityLogActions.updateUser:
    case AppActivityLogActions.setUserActive:
    case AppActivityLogActions.deleteUser:
      return Icons.group_rounded;
    case AppActivityLogActions.createCategory:
    case AppActivityLogActions.updateCategory:
    case AppActivityLogActions.createSubcategory:
    case AppActivityLogActions.updateSubcategory:
    case AppActivityLogActions.deleteSubcategory:
    case AppActivityLogActions.setMainCategory:
    case AppActivityLogActions.deleteCategory:
    case AppActivityLogActions.createProduct:
    case AppActivityLogActions.updateProduct:
    case AppActivityLogActions.deleteProduct:
      return Icons.inventory_2_rounded;
    case AppActivityLogActions.createSale:
    case AppActivityLogActions.editSale:
    case AppActivityLogActions.cancelSale:
      return Icons.receipt_long_rounded;
    case AppActivityLogActions.createPendingPayment:
    case AppActivityLogActions.createPaymentEntry:
      return Icons.payments_rounded;
    default:
      return Icons.history_rounded;
  }
}

String _dateLabel(DateTime value) {
  return '${_twoDigits(value.day)}/${_twoDigits(value.month)}/${value.year}';
}

String _timeLabel(DateTime value) {
  final hour12 = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final period = value.hour < 12 ? 'AM' : 'PM';
  return '${_twoDigits(hour12)}:${_twoDigits(value.minute)} $period';
}

String _fullDateLabel(DateTime value) {
  return '${_dateLabel(value)} ${_timeLabel(value)}';
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');
