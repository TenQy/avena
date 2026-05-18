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
        description: 'Este modulo solo esta disponible para administradores.',
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
          _ClosedCashCard(onOpenCash: () => _showOpenCashSheet(context))
        else
          _OpenCashCard(
            session: session!,
            onCloseCash: () => _closeCash(context, ref, session!),
          ),
      ],
    );
  }

  Future<void> _showOpenCashSheet(BuildContext context) async {
    final result = await showModalBottomSheet<OpenCashResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardSurface,
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

class _ClosedCashCard extends StatelessWidget {
  const _ClosedCashCard({required this.onOpenCash});

  final VoidCallback onOpenCash;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _CashIconHeader(
              icon: Icons.account_balance_wallet_rounded,
              label: 'Caja cerrada',
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No hay una caja abierta.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Abre caja registrando el efectivo inicial.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: onOpenCash,
              icon: const Icon(Icons.lock_open_rounded),
              label: const Text('Abrir caja'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpenCashCard extends StatelessWidget {
  const _OpenCashCard({required this.session, required this.onCloseCash});

  final CashSession session;
  final VoidCallback onCloseCash;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _CashIconHeader(
              icon: Icons.lock_open_rounded,
              label: 'Caja abierta',
            ),
            const SizedBox(height: AppSpacing.lg),
            _CashDetailRow(
              label: 'Dinero inicial',
              value: _money(session.openingCashAmount),
            ),
            const SizedBox(height: AppSpacing.md),
            _CashDetailRow(
              label: 'Apertura',
              value: _dateTime(session.openedAt),
            ),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton.icon(
              onPressed: onCloseCash,
              icon: const Icon(Icons.lock_rounded),
              label: const Text('Cerrar caja'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CashIconHeader extends StatelessWidget {
  const _CashIconHeader({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.headerNav,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Icon(icon, color: AppColors.textPrimary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.titleLarge),
        ),
      ],
    );
  }
}

class _CashDetailRow extends StatelessWidget {
  const _CashDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

String _money(double value) {
  return '\$${value.toStringAsFixed(2)}';
}

String _dateTime(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final year = value.year.toString();
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');

  return '$day/$month/$year $hour:$minute';
}
