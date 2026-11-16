/// Global, non-secret constants for Dir Shopping Store.
class AppConstants {
  AppConstants._();

  static const String appName = 'Dir Shopping Store';

  // Shared preference / secure storage keys
  static const String prefRememberMe = 'pref_remember_me';
  static const String prefSavedEmail = 'pref_saved_email';
  static const String prefThemeMode = 'pref_theme_mode';
  static const String secureAuthToken = 'secure_auth_token';

  // Validation
  static const int minPasswordLength = 8;

  // Pagination
  static const int defaultPageSize = 20;

  // User roles (stored on the user document as `role`)
  static const String roleCustomer = 'customer';
  static const String roleSeller = 'seller';
  static const String roleAdmin = 'admin';

  // Shop approval states (stored on the shop document as `status`)
  static const String shopStatusPending = 'pending';
  static const String shopStatusApproved = 'approved';
  static const String shopStatusRejected = 'rejected';
  static const String shopStatusBanned = 'banned';
}
