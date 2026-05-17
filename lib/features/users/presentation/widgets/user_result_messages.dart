import 'package:flutter/material.dart';

import '../../data/users_repository.dart';

final usersSnackBarVisible = ValueNotifier<bool>(false);

void showUserSaveResult(
  BuildContext context,
  UserSaveResult result, {
  String? successMessage,
}) {
  final message = switch (result) {
    UserSaveResult.success => successMessage ?? 'Cambios guardados.',
    UserSaveResult.forbidden => 'No tienes permisos para esta acción.',
    UserSaveResult.invalidRole => 'El rol seleccionado no es válido.',
    UserSaveResult.usernameTaken => 'Ese usuario ya existe.',
    UserSaveResult.notFound => 'El usuario ya no existe.',
  };

  _showUsersSnackBar(context, message);
}

void showUserActionResult(
  BuildContext context,
  UserActionResult result, {
  required String successMessage,
}) {
  final message = switch (result) {
    UserActionResult.success => successMessage,
    UserActionResult.forbidden => 'No tienes permisos para esta acción.',
    UserActionResult.notFound => 'El usuario ya no existe.',
  };

  _showUsersSnackBar(context, message);
}

void _showUsersSnackBar(BuildContext context, String message) {
  usersSnackBarVisible.value = true;

  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message))).closed.whenComplete(() {
    usersSnackBarVisible.value = false;
  });
}
