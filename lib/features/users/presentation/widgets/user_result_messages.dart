import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_snack_bar.dart';
import '../../data/users_repository.dart';

void showUserSaveResult(
  BuildContext context,
  UserSaveResult result, {
  String? successMessage,
}) {
  final message = switch (result) {
    UserSaveResult.success => successMessage ?? 'Cambios guardados.',
    UserSaveResult.forbidden => 'No tienes permisos para esta acciÃƒÂ³n.',
    UserSaveResult.invalidRole => 'El rol seleccionado no es vÃƒÂ¡lido.',
    UserSaveResult.usernameTaken => 'Ese usuario ya existe.',
    UserSaveResult.notFound => 'El usuario ya no existe.',
  };

  showAppSnackBar(context, message);
}

void showUserActionResult(
  BuildContext context,
  UserActionResult result, {
  required String successMessage,
}) {
  final message = switch (result) {
    UserActionResult.success => successMessage,
    UserActionResult.forbidden => 'No tienes permisos para esta acciÃƒÂ³n.',
    UserActionResult.notFound => 'El usuario ya no existe.',
  };

  showAppSnackBar(context, message);
}
