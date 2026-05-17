import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_roles.dart';
import '../../../../core/database/app_database.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/widgets/app_fab.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../authentication/providers/auth_provider.dart';
import '../../providers/users_provider.dart';
import '../widgets/user_form_sheet.dart';
import '../widgets/user_result_messages.dart';
import '../widgets/user_card.dart';

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserState = ref.watch(currentUserProvider);

    return currentUserState.when(
      data: (currentUser) {
        if (currentUser == null || !AppRoles.canManageUsers(currentUser.role)) {
          return const _UsersAccessDenied();
        }

        final usersState = ref.watch(usersProvider);

        return usersState.when(
          data: (users) =>
              _UsersContent(currentUser: currentUser, users: users),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const _UsersError(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const _UsersAccessDenied(),
    );
  }
}

class _UsersContent extends StatelessWidget {
  const _UsersContent({required this.currentUser, required this.users});

  final User currentUser;
  final List<User> users;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (users.isEmpty)
          const _UsersEmptyState()
        else
          ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              104,
            ),
            itemBuilder: (context, index) {
              return UserCard(currentUser: currentUser, user: users[index]);
            },
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemCount: users.length,
          ),
        Positioned(
          right: AppSpacing.lg,
          bottom: 0,
          child: SnackBarAwareFab(
            baseBottom: AppSpacing.lg,
            child: AppFab(
              tooltip: 'Nuevo usuario',
              icon: Icons.person_add_rounded,
              onPressed: () => _showUserForm(context, currentUser),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showUserForm(BuildContext context, User currentUser) async {
    final result = await UserFormSheet.show(context, actor: currentUser);

    if (!context.mounted || result == null) {
      return;
    }

    showUserSaveResult(context, result, successMessage: 'Usuario creado.');
  }
}

class _UsersEmptyState extends StatelessWidget {
  const _UsersEmptyState();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.group_rounded,
      message: 'Sin usuarios',
      description: 'Toca + para crear un usuario.',
    );
  }
}

class _UsersAccessDenied extends StatelessWidget {
  const _UsersAccessDenied();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.lock_rounded,
      message: 'Sin acceso',
      description: 'No tienes permisos para administrar usuarios.',
    );
  }
}

class _UsersError extends StatelessWidget {
  const _UsersError();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.error_outline_rounded,
      message: 'No se pudieron cargar los usuarios',
      description: 'Intenta nuevamente.',
    );
  }
}
