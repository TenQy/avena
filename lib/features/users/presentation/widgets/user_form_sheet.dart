import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_roles.dart';
import '../../../../core/database/app_database.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../data/users_repository.dart';
import '../../providers/users_provider.dart';
import 'user_result_messages.dart';
import 'user_role_ui.dart';

class UserFormSheet extends ConsumerStatefulWidget {
  const UserFormSheet({super.key, required this.actor, this.user});

  final User actor;
  final User? user;

  static Future<UserSaveResult?> show(
    BuildContext context, {
    required User actor,
    User? user,
  }) {
    return showModalBottomSheet<UserSaveResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardSurfaceFor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => UserFormSheet(actor: actor, user: user),
    );
  }

  @override
  ConsumerState<UserFormSheet> createState() => _UserFormSheetState();
}

class _UserFormSheetState extends ConsumerState<UserFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _phoneController;
  late String _role;
  bool _isSaving = false;
  bool _obscurePassword = true;

  bool get _isEditing => widget.user != null;

  List<String> get _availableRoles {
    if (widget.actor.role == AppRoles.superadmin) {
      if (widget.user?.role == AppRoles.superadmin) {
        return const [AppRoles.superadmin];
      }

      return const [AppRoles.employee, AppRoles.admin];
    }

    return const [AppRoles.employee];
  }

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user?.username);
    _passwordController = TextEditingController();
    _phoneController = TextEditingController(text: widget.user?.phone);
    _role = widget.user?.role ?? _availableRoles.first;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg + bottomInset,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                _isEditing ? 'Editar usuario' : 'Nuevo usuario',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              Divider(
                height: 1,
                thickness: 0.5,
                color: AppColors.borderFor(context),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _usernameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Usuario',
                  prefixIcon: Icon(Icons.person_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa un usuario.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: _isEditing
                      ? 'Nueva contraseña opcional'
                      : 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_rounded),
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword
                        ? 'Mostrar contraseña'
                        : 'Ocultar contraseña',
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (!_isEditing && (value == null || value.trim().isEmpty)) {
                    return 'Ingresa una contraseña.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Teléfono opcional',
                  prefixIcon: Icon(Icons.phone_rounded),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: const InputDecoration(
                  labelText: 'Rol',
                  prefixIcon: Icon(Icons.admin_panel_settings_rounded),
                ),
                items: _availableRoles.map((role) {
                  return DropdownMenuItem<String>(
                    value: role,
                    child: Text(userRoleLabel(role)),
                  );
                }).toList(),
                onChanged: _availableRoles.length == 1
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _role = value;
                        });
                      },
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_isEditing ? 'Guardar cambios' : 'Crear usuario'),
                    const SizedBox(width: AppSpacing.sm),
                    if (_isSaving)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(Icons.save_rounded),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final repository = ref.read(usersRepositoryProvider);
      final result = _isEditing
          ? await repository.updateUser(
              actor: widget.actor,
              target: widget.user!,
              username: _usernameController.text,
              password: _passwordController.text,
              phone: _phoneController.text,
              role: _role,
            )
          : await repository.createUser(
              actor: widget.actor,
              username: _usernameController.text,
              password: _passwordController.text,
              phone: _phoneController.text,
              role: _role,
            );

      if (!mounted) {
        return;
      }

      if (result == UserSaveResult.success) {
        Navigator.of(context).pop(result);
        return;
      }

      showUserSaveResult(context, result);
    } catch (_) {
      if (!mounted) {
        return;
      }

      showAppSnackBar(
        context,
        'No se pudo guardar el usuario. Intenta nuevamente.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
