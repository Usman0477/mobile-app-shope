import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../models/order_model.dart';
import '../../../models/product_model.dart';
import '../../../models/shop_model.dart';
import '../../../models/user_model.dart';

/// Every admin-only Firestore operation goes through here. The
/// Firestore rules (already deployed) independently re-check
/// `role == 'admin'` on the caller's own user doc before allowing any
/// of these writes to actually succeed — this repo doesn't grant
/// access by itself, it just organizes the queries.
class AdminRepository {
  AdminRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _shops =>
      _firestore.collection(FirestorePaths.shops);
  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirestorePaths.users);
  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection(FirestorePaths.products);
  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection(FirestorePaths.orders);

  // ---- Shops ----

  Stream<List<ShopModel>> watchAllShops() {
    return _shops.orderBy('createdAt', descending: true).snapshots().map(
        (snap) =>
            snap.docs.map((d) => ShopModel.fromMap(d.data(), d.id)).toList());
  }

  Future<void> setShopStatus(String shopId, String status) {
    return _shops.doc(shopId).update({'status': status});
  }

  // ---- Users ----

  Stream<List<UserModel>> watchAllUsers() {
    return _users.orderBy('createdAt', descending: true).snapshots().map(
        (snap) => snap.docs
            .map((d) => UserModel.fromMap(d.data(), d.id))
            .toList());
  }

  Future<void> setUserBanned(String uid, bool banned) {
    return _users.doc(uid).update({'isBanned': banned});
  }

  // ---- Products (marketplace-wide moderation) ----

  Stream<List<ProductModel>> watchAllProducts() {
    return _products.orderBy('createdAt', descending: true).snapshots().map(
        (snap) => snap.docs
            .map((d) => ProductModel.fromMap(d.data(), d.id))
            .toList());
  }

  Future<void> deleteProduct(String productId) {
    return _products.doc(productId).delete();
  }

  Future<void> setProductHidden(String productId, bool hide) {
    return _products.doc(productId).update({
      'status': hide ? 'hidden' : 'active',
    });
  }

  // ---- Orders (for the revenue/analytics overview) ----

  Stream<List<OrderModel>> watchAllOrders() {
    return _orders.orderBy('createdAt', descending: true).snapshots().map(
        (snap) => snap.docs
            .map((d) => OrderModel.fromMap(d.data(), d.id))
            .toList());
  }
}
