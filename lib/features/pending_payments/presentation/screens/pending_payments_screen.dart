import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_pending_payments.dart';
import '../../../../core/constants/app_roles.dart';
import '../../../../core/database/app_database.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/widgets/app_fab.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../authentication/providers/auth_provider.dart';
import '../../providers/pending_payments_provider.dart';
import '../utils/pending_payment_messages.dart';
import '../widgets/create_pending_payment_sheet.dart';
import '../widgets/payment_entry_sheet.dart';
import '../widgets/pending_payment_card.dart';

class PendingPaymentsScreen extends ConsumerWidget {
  const PendingPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserState = ref.watch(currentUserProvider);

    return currentUserState.when(
      data: (currentUser) {
        if (currentUser == null ||
            !AppRoles.canAccessPendingPayments(currentUser.role)) {
          return const _PendingPaymentsAccessDenied();
        }

        final paymentsState = ref.watch(pendingPaymentsProvider);
        return paymentsState.when(
          data: (payments) => _PendingPaymentsContent(
            currentUser: currentUser,
            payments: payments,
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const _PendingPaymentsError(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const _PendingPaymentsAccessDenied(),
    );
  }
}

enum _PendingPaymentsView { active, completed }

class _PendingPaymentsContent extends StatefulWidget {
  const _PendingPaymentsContent({
    required this.currentUser,
    required this.payments,
  });

  final User currentUser;
  final List<PendingPayment> payments;

  @override
  State<_PendingPaymentsContent> createState() =>
      _PendingPaymentsContentState();
}

class _PendingPaymentsContentState extends State<_PendingPaymentsContent> {
  _PendingPaymentsView _selectedView = _PendingPaymentsView.active;

  @override
  Widget build(BuildContext context) {
    final filteredPayments = widget.payments.where((payment) {
      final isCompleted = payment.status == AppPendingPaymentStatuses.completed;
      return _selectedView == _PendingPaymentsView.completed
          ? isCompleted
          : !isCompleted;
    }).toList();
    final showingCompleted = _selectedView == _PendingPaymentsView.completed;

    return Stack(
      children: [
        Column(
          children: [
            _PendingPaymentFilterBar(
              selectedView: _selectedView,
              activeCount: widget.payments
                  .where(
                    (payment) =>
                        payment.status != AppPendingPaymentStatuses.completed,
                  )
                  .length,
              completedCount: widget.payments
                  .where(
                    (payment) =>
                        payment.status == AppPendingPaymentStatuses.completed,
                  )
                  .length,
              onSelected: (view) {
                setState(() {
                  _selectedView = view;
                });
              },
            ),
            Expanded(
              child: filteredPayments.isEmpty
                  ? EmptyState(
                      icon: showingCompleted
                          ? Icons.task_alt_rounded
                          : Icons.receipt_long_outlined,
                      message: showingCompleted
                          ? 'Sin pagos completados'
                          : 'Sin pagos pendientes activos',
                      description: showingCompleted
                          ? 'Los pagos cubiertos aparecerán aquí.'
                          : 'Toca + para agregar uno.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        104,
                      ),
                      itemBuilder: (context, index) {
                        final payment = filteredPayments[index];
                        return PendingPaymentCard(
                          payment: payment,
                          onRegisterEntry: showingCompleted
                              ? null
                              : () => _showPaymentEntrySheet(context, payment),
                        );
                      },
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.md),
                      itemCount: filteredPayments.length,
                    ),
            ),
          ],
        ),
        Positioned(
          right: AppSpacing.lg,
          bottom: 0,
          child: SnackBarAwareFab(
            baseBottom: AppSpacing.lg,
            child: AppFab(
              tooltip: 'Nuevo pago pendiente',
              icon: Icons.add_rounded,
              onPressed: () => _showCreateSheet(context),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showCreateSheet(BuildContext context) async {
    final result = await CreatePendingPaymentSheet.show(
      context,
      actor: widget.currentUser,
    );

    if (!context.mounted || result == null) {
      return;
    }

    showPendingPaymentCreateResult(context, result);
  }

  Future<void> _showPaymentEntrySheet(
    BuildContext context,
    PendingPayment payment,
  ) async {
    final result = await PaymentEntrySheet.show(
      context,
      actor: widget.currentUser,
      payment: payment,
    );

    if (!context.mounted || result == null) {
      return;
    }

    showPendingPaymentEntryResult(context, result);
  }
}

class _PendingPaymentFilterBar extends StatelessWidget {
  const _PendingPaymentFilterBar({
    required this.selectedView,
    required this.activeCount,
    required this.completedCount,
    required this.onSelected,
  });

  final _PendingPaymentsView selectedView;
  final int activeCount;
  final int completedCount;
  final ValueChanged<_PendingPaymentsView> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          ChoiceChip(
            label: Text('Activos ($activeCount)'),
            selected: selectedView == _PendingPaymentsView.active,
            onSelected: (_) => onSelected(_PendingPaymentsView.active),
          ),
          const SizedBox(width: AppSpacing.sm),
          ChoiceChip(
            label: Text('Completados ($completedCount)'),
            selected: selectedView == _PendingPaymentsView.completed,
            onSelected: (_) => onSelected(_PendingPaymentsView.completed),
          ),
        ],
      ),
    );
  }
}

class _PendingPaymentsAccessDenied extends StatelessWidget {
  const _PendingPaymentsAccessDenied();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.lock_outline_rounded,
      message: 'Sin acceso',
      description: 'No tienes permisos para consultar pagos pendientes.',
    );
  }
}

class _PendingPaymentsError extends StatelessWidget {
  const _PendingPaymentsError();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.error_outline_rounded,
      message: 'No se pudieron cargar los pagos pendientes',
      description: 'Intenta nuevamente.',
    );
  }
}
