import 'package:flutter/material.dart';

import '../../../../core/constants/app_roles.dart';

IconData userRoleIcon(String role) {
  return switch (role) {
    AppRoles.superadmin => Icons.workspace_premium_rounded,
    AppRoles.admin => Icons.admin_panel_settings_rounded,
    _ => Icons.badge_rounded,
  };
}

String userRoleLabel(String role) {
  return switch (role) {
    AppRoles.superadmin => 'Superadmin',
    AppRoles.admin => 'Administrador',
    _ => 'Empleado',
  };
}
