class AppRoles {
  const AppRoles._();

  static const superadmin = 'superadmin';
  static const admin = 'admin';
  static const employee = 'employee';

  static const all = [superadmin, admin, employee];

  static bool isValid(String role) => all.contains(role);

  static bool isAdminRole(String role) {
    return role == superadmin || role == admin;
  }

  static bool canManageAdmins(String role) => role == superadmin;

  static bool canManageUsers(String role) => isAdminRole(role);

  static bool canViewLogs(String role) => isAdminRole(role);

  static bool canCancelSales(String role) => isAdminRole(role);

  static bool canEditProducts(String role) => isAdminRole(role);

  static bool canManageCash(String role) => isAdminRole(role);

  static bool canModifySettings(String role) => isAdminRole(role);

  static bool canAccessPendingPayments(String role) {
    return isAdminRole(role) || role == employee;
  }

  static bool canAccessSales(String role) {
    return isAdminRole(role) || role == employee;
  }

  static bool canReadInventory(String role) {
    return isAdminRole(role) || role == employee;
  }
}
