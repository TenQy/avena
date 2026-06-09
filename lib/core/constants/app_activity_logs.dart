class AppActivityLogActions {
  const AppActivityLogActions._();

  static const login = 'login';
  static const logout = 'logout';
  static const openCash = 'open_cash';
  static const closeCash = 'close_cash';
  static const createCashMovement = 'create_cash_movement';
  static const createUser = 'create_user';
  static const updateUser = 'update_user';
  static const setUserActive = 'set_user_active';
  static const deleteUser = 'delete_user';
  static const createCategory = 'create_category';
  static const createSubcategory = 'create_subcategory';
  static const deleteSubcategory = 'delete_subcategory';
  static const setMainCategory = 'set_main_category';
  static const deleteCategory = 'delete_category';
  static const createProduct = 'create_product';
  static const updateProduct = 'update_product';
  static const deleteProduct = 'delete_product';
  static const createSale = 'create_sale';
  static const cancelSale = 'cancel_sale';
  static const createPendingPayment = 'create_pending_payment';
  static const createPaymentEntry = 'create_payment_entry';
  static const exportBackup = 'export_backup';
  static const restoreBackup = 'restore_backup';
  static const resetOperationalData = 'reset_operational_data';
  static const clearLogs = 'clear_logs';
  static const clearSyncQueue = 'clear_sync_queue';
}

class AppActivityLogEntities {
  const AppActivityLogEntities._();

  static const session = 'session';
  static const cashSession = 'cash_session';
  static const cashMovement = 'cash_movement';
  static const user = 'user';
  static const category = 'category';
  static const subcategory = 'subcategory';
  static const product = 'product';
  static const sale = 'sale';
  static const pendingPayment = 'pending_payment';
  static const maintenance = 'maintenance';
}
