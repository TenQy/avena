import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../data/auth_repository.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ref
        .read(authProvider.notifier)
        .login(
          username: _usernameController.text,
          password: _passwordController.text,
        );

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });

    switch (result) {
      case LoginResult.success:
        return;
      case LoginResult.invalidCredentials:
        setState(() {
          _errorMessage = 'Usuario o contrasena incorrectos.';
        });
      case LoginResult.inactiveUser:
        setState(() {
          _errorMessage = 'Este usuario está inhabilitado.';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: AppColors.headerNavFor(context),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Icon(
                            Icons.storefront_rounded,
                            color: AppColors.textPrimaryFor(context),
                            size: 72,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      Text(
                        AppConstants.appName,
                        textAlign: TextAlign.center,
                        style: textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Inicia sesión para continuar',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondaryFor(context),
                        ),
                      ),
                      const SizedBox(height: 44),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: _LoginInput(
                          controller: _usernameController,
                          icon: Icons.person_rounded,
                          hintText: 'Usuario',
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ingresa tu usuario.';
                            }

                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: _LoginInput(
                          controller: _passwordController,
                          icon: Icons.lock_rounded,
                          hintText: 'Contrasena',
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          trailing: IconButton(
                            tooltip: _obscurePassword
                                ? 'Mostrar contraseña'
                                : 'Ocultar contraseña',
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                            ),
                            color: AppColors.iconInactiveFor(context),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa tu contraseña.';
                            }

                            return null;
                          },
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 36),
                      Center(
                        child: SizedBox(
                          width: 160,
                          child: FilledButtonTheme(
                            data: FilledButtonThemeData(
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            child: FilledButton(
                              onPressed: _isLoading ? null : _submit,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Entrar'),
                                  const SizedBox(width: AppSpacing.sm),
                                  if (_isLoading)
                                    const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  else
                                    Icon(Icons.login_rounded),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginInput extends StatelessWidget {
  const _LoginInput({
    required this.controller,
    required this.icon,
    required this.hintText,
    this.obscureText = false,
    this.textInputAction,
    this.onFieldSubmitted,
    this.trailing,
    this.validator,
  });

  final TextEditingController controller;
  final IconData icon;
  final String hintText;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final Widget? trailing;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIconConstraints: const BoxConstraints(
          minWidth: 64,
          minHeight: 48,
        ),
        prefixIcon: IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 52,
                child: Icon(icon, color: AppColors.iconInactiveFor(context)),
              ),
              VerticalDivider(
                width: 1,
                thickness: 0.5,
                color: AppColors.borderFor(context),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
          ),
        ),
        suffixIcon: trailing,
        border: _inputBorder(AppColors.borderFor(context)),
        enabledBorder: _inputBorder(AppColors.borderFor(context)),
        focusedBorder: _inputBorder(AppColors.accentFor(context)),
        errorBorder: _inputBorder(Theme.of(context).colorScheme.error),
        focusedErrorBorder: _inputBorder(Theme.of(context).colorScheme.error),
      ),
    );
  }

  OutlineInputBorder _inputBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color.withValues(alpha: 0.65), width: 0.5),
    );
  }
}
