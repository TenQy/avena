import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class _PendingPaymentsContent extends StatelessWidget {
  const _PendingPaymentsContent({
    required this.currentUser,
    required this.payments,
  });

  final User currentUser;
  final List<PendingPayment> payments;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (payments.isEmpty)
          const EmptyState(
            icon: Icons.receipt_long_outlined,
            message: 'Sin pagos pendientes',
            description: 'Toca + para agregar uno.',
          )
        else
          ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              104,
            ),
            itemBuilder: (context, index) {
              return PendingPaymentCard(payment: payments[index]);
            },
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemCount: payments.length,
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
      actor: currentUser,
    );

    if (!context.mounted || result == null) {
      return;
    }

    showPendingPaymentCreateResult(context, result);
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
