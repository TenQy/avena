import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_roles.dart';
import '../../../../core/database/app_database.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../authentication/providers/auth_provider.dart';
import '../../data/cash_repository.dart';
import '../../providers/cash_provider.dart';
import '../utils/cash_messages.dart';
import '../widgets/cash_income_card.dart';
import '../widgets/cash_movement_sheet.dart';
import '../widgets/cash_movements_card.dart';
import '../widgets/closed_cash_card.dart';
import '../widgets/open_cash_card.dart';
import '../widgets/open_cash_sheet.dart';

class CashScreen extends ConsumerWidget {
  const CashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    if (currentUser == null || !AppRoles.canManageCash(currentUser.role)) {
      return const EmptyState(
        icon: Icons.lock_outline_rounded,
        message: 'Caja no disponible',
        description: 'Este módulo solo está disponible para administradores.',
      );
    }

    final cashSessionState = ref.watch(currentCashSessionProvider);

    return cashSessionState.when(
      data: (session) =>
          _CashContent(session: session, currentUser: currentUser),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const EmptyState(
        icon: Icons.error_outline_rounded,
        message: 'No se pudo cargar la caja',
        description: 'Intenta nuevamente.',
      ),
    );
  }
}

class _CashContent extends ConsumerWidget {
  const _CashContent({required this.session, required this.currentUser});

  final CashSession? session;
  final User currentUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: [
        if (session == null)
          ClosedCashCard(onOpenCash: () => _showOpenCashSheet(context))
        else
          ..._openCashSections(context, ref, session!),
      ],
    );
  }

  List<Widget> _openCashSections(
    BuildContext context,
    WidgetRef ref,
    CashSession session,
  ) {
    final movementsState = ref.watch(
      cashMovementsBySessionProvider(session.id),
    );

    return [
      OpenCashCard(
        session: session,
        onWithdrawal: () =>
            _showMovementSheet(context, session, CashMovementType.withdrawal),
        onDeposit: () =>
            _showMovementSheet(context, session, CashMovementType.deposit),
        onCloseCash: () => _closeCash(context, ref, session),
      ),
      const SizedBox(height: AppSpacing.lg),
      CashIncomeCard(session: session),
      const SizedBox(height: AppSpacing.lg),
      movementsState.when(
        data: (movements) => CashMovementsCard(movements: movements),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const EmptyState(
          icon: Icons.error_outline_rounded,
          message: 'No se pudieron cargar los movimientos',
          description: 'Intenta nuevamente.',
        ),
      ),
    ];
  }

  Future<void> _showOpenCashSheet(BuildContext context) async {
    final result = await showModalBottomSheet<OpenCashResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardSurfaceFor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return const OpenCashSheet();
      },
    );

    if (!context.mounted || result == null) {
      return;
    }

    showOpenCashResult(context, result);
  }

  Future<void> _showMovementSheet(
    BuildContext context,
    CashSession session,
    CashMovementType type,
  ) async {
    final result = await showModalBottomSheet<CashMovementResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardSurfaceFor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return CashMovementSheet(session: session, type: type);
      },
    );

    if (!context.mounted || result == null) {
      return;
    }

    showCashMovementResult(context, result);
  }

  Future<void> _closeCash(
    BuildContext context,
    WidgetRef ref,
    CashSession session,
  ) async {
    final shouldClose = await ConfirmDialog.show(
      context,
      title: 'Cerrar caja',
      message:
          'La caja actual se marcara como cerrada y deberas abrir una nueva para continuar operaciones.',
      confirmLabel: 'Cerrar caja',
      icon: Icons.lock_rounded,
    );

    if (!context.mounted || !shouldClose) {
      return;
    }

    final result = await ref
        .read(cashRepositoryProvider)
        .closeCashSession(actor: currentUser, session: session);

    if (!context.mounted) {
      return;
    }

    showCloseCashResult(context, result);
  }
}
