import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_roles.dart';
import '../../../../core/database/app_database.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../providers/users_provider.dart';
import 'user_form_sheet.dart';
import 'user_result_messages.dart';
import 'user_role_ui.dart';

class UserCard extends ConsumerWidget {
  const UserCard({super.key, required this.currentUser, required this.user});

  final User currentUser;
  final User user;

  bool get _isCurrentUser => currentUser.id == user.id;

  bool get _canEdit {
    if (_isCurrentUser) {
      return currentUser.role == AppRoles.superadmin ||
          currentUser.role == AppRoles.admin;
    }

    if (currentUser.role == AppRoles.superadmin) {
      return user.role != AppRoles.superadmin;
    }

    return currentUser.role == AppRoles.admin && user.role == AppRoles.employee;
  }

  bool get _canChangeState {
    if (_isCurrentUser || user.role == AppRoles.superadmin) {
      return false;
    }

    if (currentUser.role == AppRoles.superadmin) {
      return true;
    }

    return currentUser.role == AppRoles.admin && user.role == AppRoles.employee;
  }

  bool get _canDelete {
    if (_isCurrentUser || user.role == AppRoles.superadmin) {
      return false;
    }

    if (currentUser.role == AppRoles.superadmin) {
      return true;
    }

    return currentUser.role == AppRoles.admin && user.role == AppRoles.employee;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasActions = _canEdit || _canChangeState || _canDelete;

    return GestureDetector(
      onLongPress: hasActions ? () => _showUserActions(context, ref) : null,
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
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.headerNavFor(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.borderFor(context),
                        width: 0.5,
                      ),
                    ),
                    child: Icon(
                      userRoleIcon(user.role),
                      color: AppColors.iconInactiveFor(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.username,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          userRoleLabel(user.role),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(isActive: user.isActive),
                ],
              ),
              if (user.phone != null && user.phone!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Icon(
                      Icons.phone_rounded,
                      color: AppColors.iconInactiveFor(context),
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      _formatPhone(user.phone!),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showUserActions(BuildContext context, WidgetRef ref) async {
    final parentContext = context;

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
                if (_canEdit)
                  _UserActionTile(
                    icon: Icons.edit_rounded,
                    label: 'Editar',
                    onTap: () {
                      Navigator.of(context).pop();
                      _editUser(parentContext);
                    },
                  ),
                if (_canChangeState)
                  _UserActionTile(
                    icon: user.isActive
                        ? Icons.person_off_rounded
                        : Icons.person_rounded,
                    label: user.isActive ? 'Inhabilitar' : 'Habilitar',
                    onTap: () {
                      Navigator.of(context).pop();
                      _changeState(parentContext, ref);
                    },
                  ),
                if (_canDelete)
                  _UserActionTile(
                    icon: Icons.delete_rounded,
                    label: 'Eliminar',
                    onTap: () {
                      Navigator.of(context).pop();
                      _deleteUser(parentContext, ref);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _editUser(BuildContext context) async {
    final result = await UserFormSheet.show(
      context,
      actor: currentUser,
      user: user,
    );

    if (!context.mounted || result == null) {
      return;
    }

    showUserSaveResult(context, result, successMessage: 'Usuario actualizado.');
  }

  Future<void> _changeState(BuildContext context, WidgetRef ref) async {
    final shouldContinue = await ConfirmDialog.show(
      context,
      title: user.isActive ? 'Inhabilitar usuario' : 'Habilitar usuario',
      message: user.isActive
          ? 'El usuario no podrá iniciar sesión mientras esté inhabilitado.'
          : 'El usuario podrá iniciar sesión nuevamente.',
      confirmLabel: user.isActive ? 'Inhabilitar' : 'Habilitar',
      icon: user.isActive ? Icons.person_off_rounded : Icons.person_rounded,
    );

    if (!context.mounted || !shouldContinue) {
      return;
    }

    final result = await ref
        .read(usersRepositoryProvider)
        .setUserActive(
          actor: currentUser,
          target: user,
          isActive: !user.isActive,
        );

    if (!context.mounted) {
      return;
    }

    showUserActionResult(
      context,
      result,
      successMessage: user.isActive
          ? 'Usuario inhabilitado.'
          : 'Usuario habilitado.',
    );
  }

  Future<void> _deleteUser(BuildContext context, WidgetRef ref) async {
    final shouldContinue = await ConfirmDialog.show(
      context,
      title: 'Eliminar usuario',
      message: 'El usuario se eliminará de la lista y no podrá iniciar sesión.',
      confirmLabel: 'Eliminar',
      icon: Icons.delete_rounded,
    );

    if (!context.mounted || !shouldContinue) {
      return;
    }

    final result = await ref
        .read(usersRepositoryProvider)
        .deleteUser(actor: currentUser, target: user);

    if (!context.mounted) {
      return;
    }

    showUserActionResult(context, result, successMessage: 'Usuario eliminado.');
  }
}

String _formatPhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length <= 2) {
    return digits;
  }

  if (digits.length <= 6) {
    return '${digits.substring(0, 2)} ${digits.substring(2)}';
  }

  final cappedDigits = digits.length <= 10 ? digits : digits.substring(0, 10);
  return '${cappedDigits.substring(0, 2)} ${cappedDigits.substring(2, 6)} ${cappedDigits.substring(6)}';
}

class _UserActionTile extends StatelessWidget {
  const _UserActionTile({
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.headerNavFor(context)
            : AppColors.bodyBgFor(context),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.borderFor(context), width: 0.5),
      ),
      child: Text(
        isActive ? 'Activo' : 'Inhabilitado',
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}
