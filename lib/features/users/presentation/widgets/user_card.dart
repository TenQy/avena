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
      return currentUser.role == AppRoles.superadmin;
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
    return currentUser.role == AppRoles.superadmin &&
        !_isCurrentUser &&
        user.role != AppRoles.superadmin;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
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
                    border: Border.all(color: AppColors.borderFor(context), width: 0.5),
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
                    user.phone!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
            if (_canEdit || _canChangeState || _canDelete) ...[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  if (_canEdit)
                    _UserActionButton(
                      icon: Icons.edit_rounded,
                      label: 'Editar',
                      onPressed: () => _editUser(context),
                    ),
                  if (_canChangeState)
                    _UserActionButton(
                      icon: user.isActive
                          ? Icons.person_off_rounded
                          : Icons.person_rounded,
                      label: user.isActive ? 'Inhabilitar' : 'Habilitar',
                      onPressed: () => _changeState(context, ref),
                    ),
                  if (_canDelete)
                    _UserActionButton(
                      icon: Icons.delete_rounded,
                      label: 'Eliminar',
                      onPressed: () => _deleteUser(context, ref),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
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
          ? 'El usuario no podrÃƒÂ¡ iniciar sesiÃƒÂ³n mientras estÃƒÂ© inhabilitado.'
          : 'El usuario podrÃƒÂ¡ iniciar sesiÃƒÂ³n nuevamente.',
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
      message: 'El usuario se eliminarÃƒÂ¡ de la lista y no podrÃƒÂ¡ iniciar sesiÃƒÂ³n.',
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

class _UserActionButton extends StatelessWidget {
  const _UserActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textSecondaryFor(context),
        side: BorderSide(color: AppColors.borderFor(context), width: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: AppSpacing.sm),
          Icon(icon, size: 18),
        ],
      ),
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
        color: isActive ? AppColors.headerNavFor(context) : AppColors.bodyBgFor(context),
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
