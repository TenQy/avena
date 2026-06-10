import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;

import '../../../../core/database/app_database.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../providers/settings_provider.dart';
import 'settings_formatters.dart';
import 'settings_rows.dart';
import 'settings_section_card.dart';

class SuperadminMaintenanceSection extends ConsumerWidget {
  const SuperadminMaintenanceSection({super.key, required this.currentUser});

  final User currentUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maintenanceState = ref.watch(maintenanceProvider);
    final isBusy = maintenanceState.isLoading;

    return SettingsSectionCard(
      title: 'Mantenimiento',
      icon: Icons.admin_panel_settings_rounded,
      children: [
        MaintenanceActionButton(
          icon: Icons.ios_share_rounded,
          label: 'Compartir respaldo',
          onPressed: isBusy
              ? null
              : () => _exportBackup(context, ref, currentUser),
        ),
        MaintenanceActionButton(
          icon: Icons.upload_file_rounded,
          label: 'Importar respaldo',
          isDestructive: true,
          onPressed: isBusy
              ? null
              : () => _restoreBackup(context, ref, currentUser),
        ),
        MaintenanceActionButton(
          icon: Icons.cleaning_services_rounded,
          label: 'Reiniciar datos operativos',
          isDestructive: true,
          onPressed: isBusy
              ? null
              : () => _resetOperationalData(context, ref, currentUser),
        ),
        MaintenanceActionButton(
          icon: Icons.receipt_long_rounded,
          label: 'Limpiar logs',
          isDestructive: true,
          onPressed: isBusy
              ? null
              : () => _clearActivityLogs(context, ref, currentUser),
        ),
        MaintenanceActionButton(
          icon: Icons.sync_problem_rounded,
          label: 'Limpiar cola de sincronización',
          isDestructive: true,
          onPressed: isBusy
              ? null
              : () => _clearSyncQueue(context, ref, currentUser),
        ),
        MaintenanceActionButton(
          icon: Icons.delete_forever_rounded,
          label: 'Reiniciar aplicación completa',
          isDestructive: true,
          onPressed: isBusy
              ? null
              : () => _resetApplicationData(context, ref, currentUser),
        ),
        if (isBusy) ...[
          const SizedBox(height: AppSpacing.md),
          const LinearProgressIndicator(),
        ],
      ],
    );
  }

  Future<void> _exportBackup(
    BuildContext context,
    WidgetRef ref,
    User actor,
  ) async {
    try {
      final result = await ref
          .read(maintenanceProvider.notifier)
          .createShareableBackup(actor: actor);

      if (!context.mounted) {
        return;
      }

      await Share.shareXFiles(
        [
          XFile(
            result.path,
            mimeType: 'application/zip',
            name: p.basename(result.path),
          ),
        ],
        subject: 'Respaldo de Tienda',
        text: 'Respaldo de Tienda',
      );
    } catch (error) {
      if (context.mounted) {
        showAppSnackBar(context, maintenanceErrorMessage(error));
      }
    }
  }

  Future<void> _restoreBackup(
    BuildContext context,
    WidgetRef ref,
    User actor,
  ) async {
    final confirmed = await _confirmTwice(
      context,
      title: 'Importar respaldo',
      message:
          'Seleccionarás un archivo de respaldo. Se reemplazará la base local y la configuración.',
      confirmLabel: 'Importar',
      secondMessage:
          'Confirma nuevamente. Los datos locales actuales se reemplazarán.',
    );

    if (!confirmed || !context.mounted) {
      return;
    }

    try {
      final pickedFile = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip', 'tiendabak', 'bin'],
        allowMultiple: false,
      );
      final packagePath = pickedFile?.files.single.path;

      if (packagePath == null) {
        return;
      }

      await ref
          .read(maintenanceProvider.notifier)
          .restoreBackupPackage(actor: actor, packagePath: packagePath);

      if (context.mounted) {
        showAppSnackBar(context, 'Respaldo importado. La app se recargará.');
      }
    } catch (error) {
      if (context.mounted) {
        showAppSnackBar(context, maintenanceErrorMessage(error));
      }
    }
  }

  Future<void> _resetOperationalData(
    BuildContext context,
    WidgetRef ref,
    User actor,
  ) async {
    final confirmed = await _confirmTwice(
      context,
      title: 'Reiniciar datos operativos',
      message:
          'Se eliminarán ventas, caja, pagos pendientes, turnos y cola sync. Inventario y usuarios se conservan.',
      confirmLabel: 'Reiniciar',
      secondMessage:
          'Confirma nuevamente para conservar inventario y limpiar datos operativos.',
    );

    if (!confirmed || !context.mounted) {
      return;
    }

    await _runMaintenance(
      context,
      () => ref
          .read(maintenanceProvider.notifier)
          .resetOperationalData(actor: actor),
      successMessage: 'Datos operativos reiniciados.',
    );
  }

  Future<void> _clearActivityLogs(
    BuildContext context,
    WidgetRef ref,
    User actor,
  ) async {
    final confirmed = await _confirmTwice(
      context,
      title: 'Limpiar logs',
      message: 'Se limpiará el historial local de actividad.',
      confirmLabel: 'Limpiar',
      secondMessage:
          'Confirma nuevamente. Se conservará un nuevo log de esta acción.',
    );

    if (!confirmed || !context.mounted) {
      return;
    }

    await _runMaintenance(
      context,
      () => ref
          .read(maintenanceProvider.notifier)
          .clearActivityLogs(actor: actor),
      successMessage: 'Logs locales limpiados.',
    );
  }

  Future<void> _clearSyncQueue(
    BuildContext context,
    WidgetRef ref,
    User actor,
  ) async {
    final confirmed = await _confirmTwice(
      context,
      title: 'Limpiar cola sync',
      message: 'Se eliminarán las operaciones locales pendientes de sync.',
      confirmLabel: 'Limpiar',
      secondMessage:
          'Confirma nuevamente. Usa esto solo después de respaldar o preparar una base limpia.',
    );

    if (!confirmed || !context.mounted) {
      return;
    }

    await _runMaintenance(
      context,
      () => ref.read(maintenanceProvider.notifier).clearSyncQueue(actor: actor),
      successMessage: 'Cola de sincronización limpiada.',
    );
  }

  Future<void> _resetApplicationData(
    BuildContext context,
    WidgetRef ref,
    User actor,
  ) async {
    final confirmed = await _confirmTwice(
      context,
      title: 'Reiniciar aplicación completa',
      message:
          'Se borrarán los datos locales y la configuración. Se conservará tu superadmin actual.',
      confirmLabel: 'Reiniciar todo',
      secondMessage:
          'Confirma nuevamente. Inventario, ventas, caja, empleados y logs se eliminarán.',
    );

    if (!confirmed || !context.mounted) {
      return;
    }

    try {
      await ref
          .read(maintenanceProvider.notifier)
          .resetApplicationData(actor: actor);

      if (context.mounted) {
        showAppSnackBar(
          context,
          'Aplicación reiniciada conservando superadmin.',
        );
      }
    } catch (error) {
      if (context.mounted) {
        showAppSnackBar(context, maintenanceErrorMessage(error));
      }
    }
  }

  Future<void> _runMaintenance(
    BuildContext context,
    Future<void> Function() action, {
    required String successMessage,
  }) async {
    try {
      await action();

      if (context.mounted) {
        showAppSnackBar(context, successMessage);
      }
    } catch (error) {
      if (context.mounted) {
        showAppSnackBar(context, maintenanceErrorMessage(error));
      }
    }
  }

  Future<bool> _confirmTwice(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required String secondMessage,
  }) async {
    final firstConfirmation = await ConfirmDialog.show(
      context,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      icon: Icons.warning_rounded,
    );

    if (!firstConfirmation || !context.mounted) {
      return false;
    }

    return ConfirmDialog.show(
      context,
      title: 'Confirmacion final',
      message: secondMessage,
      confirmLabel: confirmLabel,
      icon: Icons.warning_rounded,
    );
  }
}
