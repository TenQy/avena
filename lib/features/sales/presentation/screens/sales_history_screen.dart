import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_roles.dart';
import '../../../../core/constants/app_sales.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/constants/payment_methods.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../authentication/providers/auth_provider.dart';
import '../../providers/sales_provider.dart';
import '../utils/sale_messages.dart';
import '../widgets/sale_cancel_sheet.dart';
import '../widgets/sale_edit_sheet.dart';
import '../widgets/sales_history_card.dart';

class SalesHistoryScreen extends ConsumerStatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  ConsumerState<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends ConsumerState<SalesHistoryScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedPaymentMethod;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final canCancelSales =
        currentUser != null && AppRoles.canCancelSales(currentUser.role);
    final filter = SalesHistoryFilter(
      date: _selectedDate,
      paymentMethod: _selectedPaymentMethod,
    );
    final salesState = ref.watch(salesHistoryProvider(filter));

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: [
        _SalesHistoryFiltersCard(
          selectedDate: _selectedDate,
          selectedPaymentMethod: _selectedPaymentMethod,
          onSelectDate: _selectDate,
          onPaymentMethodSelected: (method) {
            setState(() {
              _selectedPaymentMethod = method;
            });
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        salesState.when(
          data: (sales) {
            if (sales.isEmpty) {
              return SalesHistoryMessageCard(
                icon: Icons.receipt_long_outlined,
                message:
                    'No hay ventas registradas para ${_formatDate(_selectedDate)} con los filtros seleccionados.',
              );
            }

            return Column(
              children: [
                for (final sale in sales) ...[
                  SalesHistoryCard(
                    sale: sale,
                    onLongPress:
                        canCancelSales &&
                            sale.saleStatus == AppSaleStatuses.completed
                        ? () => _showSaleActions(currentUser, sale)
                        : null,
                  ),
                  if (sale != sales.last) const SizedBox(height: AppSpacing.md),
                ],
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const SalesHistoryMessageCard(
            icon: Icons.error_outline_rounded,
            message: 'No se pudo cargar el historial de ventas.',
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Seleccionar fecha de ventas',
      cancelText: 'Cancelar',
      confirmText: 'Seleccionar',
    );

    if (!mounted || selectedDate == null) {
      return;
    }

    setState(() {
      _selectedDate = selectedDate;
    });
  }

  Future<void> _cancelSale(User actor, Sale sale) async {
    final result = await SaleCancelSheet.show(
      context,
      actor: actor,
      sale: sale,
    );

    if (!mounted || result == null) {
      return;
    }

    showSaleCancelResult(context, result);
  }

  Future<void> _showSaleActions(User actor, Sale sale) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardSurfaceFor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final canEdit = sale.paymentStatus == AppPaymentStatuses.paid;

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
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderFor(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (canEdit)
                  _SaleActionTile(
                    icon: Icons.edit_note_rounded,
                    label: 'Editar venta',
                    onTap: () {
                      Navigator.of(context).pop();
                      _editSale(actor, sale);
                    },
                  ),
                _SaleActionTile(
                  icon: Icons.cancel_outlined,
                  label: 'Cancelar venta',
                  onTap: () {
                    Navigator.of(context).pop();
                    _cancelSale(actor, sale);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _editSale(User actor, Sale sale) async {
    final result = await SaleEditSheet.show(context, actor: actor, sale: sale);

    if (!mounted || result == null) {
      return;
    }

    showSaleEditResult(context, result);
  }
}

class _SalesHistoryFiltersCard extends StatelessWidget {
  const _SalesHistoryFiltersCard({
    required this.selectedDate,
    required this.selectedPaymentMethod,
    required this.onSelectDate,
    required this.onPaymentMethodSelected,
  });

  final DateTime selectedDate;
  final String? selectedPaymentMethod;
  final VoidCallback onSelectDate;
  final ValueChanged<String?> onPaymentMethodSelected;

  @override
  Widget build(BuildContext context) {
    final isToday = _isSameDate(selectedDate, DateTime.now());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isToday ? 'Historial de hoy' : 'Historial de ventas',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Consulta ventas por fecha y metodo de pago.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryFor(context),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(
              onPressed: onSelectDate,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDate(selectedDate)),
                  Icon(Icons.calendar_today_rounded),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Metodo de pago',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimaryFor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                ChoiceChip(
                  label: const Text('Todos'),
                  selected: selectedPaymentMethod == null,
                  onSelected: (_) => onPaymentMethodSelected(null),
                ),
                for (final method in AppPaymentMethods.mixable)
                  ChoiceChip(
                    label: Text(paymentMethodLabel(method)),
                    selected: selectedPaymentMethod == method,
                    onSelected: (_) => onPaymentMethodSelected(method),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');

  return '$day/$month/${value.year}';
}

bool _isSameDate(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

class _SaleActionTile extends StatelessWidget {
  const _SaleActionTile({
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
          color: AppColors.bodyBgFor(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderFor(context), width: 0.5),
        ),
        child: Icon(icon, color: AppColors.iconInactiveFor(context), size: 22),
      ),
      title: Text(label, style: Theme.of(context).textTheme.bodyLarge),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: AppColors.iconInactiveFor(context),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onTap: onTap,
    );
  }
}
