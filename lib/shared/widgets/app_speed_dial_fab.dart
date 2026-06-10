import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class AppSpeedDialFab extends StatefulWidget {
  const AppSpeedDialFab({super.key, required this.actions, this.controller});

  final List<AppSpeedDialAction> actions;
  final AppSpeedDialController? controller;

  @override
  State<AppSpeedDialFab> createState() => _AppSpeedDialFabState();
}

class _AppSpeedDialFabState extends State<AppSpeedDialFab> {
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_syncControllerState);
  }

  @override
  void didUpdateWidget(covariant AppSpeedDialFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }

    oldWidget.controller?.removeListener(_syncControllerState);
    widget.controller?.addListener(_syncControllerState);
    _syncControllerState();
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_syncControllerState);
    super.dispose();
  }

  void _syncControllerState() {
    final controller = widget.controller;
    if (controller == null || controller.isOpen == _isOpen) {
      return;
    }

    setState(() {
      _isOpen = controller.isOpen;
    });
  }

  void _toggle() {
    final nextValue = !_isOpen;
    setState(() {
      _isOpen = nextValue;
    });
    widget.controller?._setOpen(nextValue);
  }

  void _runAction(VoidCallback action) {
    setState(() {
      _isOpen = false;
    });
    widget.controller?._setOpen(false);
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

class AppSpeedDialController extends ChangeNotifier {
  bool _isOpen = false;

  bool get isOpen => _isOpen;

  void close() {
    _setOpen(false);
  }

  void _setOpen(bool value) {
    if (_isOpen == value) {
      return;
    }

    _isOpen = value;
    notifyListeners();
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: AppColors.cardSurfaceFor(context),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Text(
              action.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimaryFor(context),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 50,
          height: 50,
          child: FloatingActionButton(
            heroTag: null,
            mini: true,
            tooltip: action.label,
            backgroundColor: AppColors.accentFor(context),
            foregroundColor: AppColors.isDark(context)
                ? const Color(0xFF2B1D14)
                : AppColors.textPrimaryFor(context),
            onPressed: onPressed,
            child: Icon(action.icon, size: 20),
          ),
        ),
      ],
    );
  }
}
