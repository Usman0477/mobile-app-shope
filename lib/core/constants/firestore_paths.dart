/// Centralized Firestore collection paths so no screen ever hardcodes a
/// collection name. Keeping this in one place makes the schema easy to
/// audit and safe to refactor later (Phase 2+ will add shops/products/
/// orders/etc. here as those features are built).
class FirestorePaths {
  FirestorePaths._();

  static const String users = 'users';
  static const String shops = 'shops';
  static const String products = 'products';
  static const String orders = 'orders';
  static const String categories = 'categories';
  static const String reviews = 'reviews';
  static const String notifications = 'notifications';
  static const String reports = 'reports';
}
