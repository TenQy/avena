import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class AppSpeedDialFab extends StatefulWidget {
  const AppSpeedDialFab({super.key, required this.actions});

  final List<AppSpeedDialAction> actions;

  @override
  State<AppSpeedDialFab> createState() => _AppSpeedDialFabState();
}

class _AppSpeedDialFabState extends State<AppSpeedDialFab> {
  bool _isOpen = false;

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
    });
  }

  void _runAction(VoidCallback action) {
    setState(() {
      _isOpen = false;
    });
    action();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isOpen) ...[
          for (final action in widget.actions) ...[
            _SpeedDialActionButton(
              action: action,
              onPressed: () => _runAction(action.onPressed),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
        FloatingActionButton(
          onPressed: _toggle,
          tooltip: _isOpen ? 'Cerrar opciones' : 'Agregar',
          child: Icon(_isOpen ? Icons.close_rounded : Icons.add_rounded),
        ),
      ],
    );
  }
}

class AppSpeedDialAction {
  const AppSpeedDialAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
}

class _SpeedDialActionButton extends StatelessWidget {
  const _SpeedDialActionButton({required this.action, required this.onPressed});

  final AppSpeedDialAction action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                action.label,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(action.icon, color: AppColors.iconInactive, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
