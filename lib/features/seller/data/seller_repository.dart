import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../models/product_model.dart';
import '../../../models/shop_model.dart';

/// Every write a seller makes — creating their shop, adding/editing/
/// deleting/hiding products — goes through here. Firestore security
/// rules (already deployed) double-check that `ownerId`/`sellerId`
/// matches the signed-in user, so this repo doesn't need to re-verify
/// that itself.
class SellerRepository {
  SellerRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _shops =>
      _firestore.collection(FirestorePaths.shops);

  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection(FirestorePaths.products);

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirestorePaths.users);

  // ---- Shop ----

  /// Creates the shop document, then links it to the owner's user
  /// profile via `shopId` so the app knows this user now has a shop.
  Future<String> createShop(ShopModel shop) async {
    final doc = await _shops.add(shop.toMap());
    await _users.doc(shop.ownerId).update({'shopId': doc.id});
    return doc.id;
  }

  Future<void> updateShop(String shopId, Map<String, dynamic> changes) {
    return _shops.doc(shopId).update(changes);
  }

  Future<ShopModel?> fetchShop(String shopId) async {
    final doc = await _shops.doc(shopId).get();
    if (!doc.exists) return null;
    return ShopModel.fromMap(doc.data()!, doc.id);
  }

  // ---- Products ----

  Future<String> addProduct(ProductModel product) async {
    final doc = await _products.add(product.toMap());
    return doc.id;
  }

  Future<void> updateProduct(String productId, Map<String, dynamic> changes) {
    return _products.doc(productId).update(changes);
  }

  Future<void> deleteProduct(String productId) {
    return _products.doc(productId).delete();
  }

  Future<void> toggleHidden(String productId, bool hide) {
    return _products.doc(productId).update({
      'status': hide ? 'hidden' : 'active',
    });
  }

  /// All of this seller's products, any status — used by the seller's
  /// own dashboard (customers only ever see `watchProducts`, which
  /// filters to status == active).
  Stream<List<ProductModel>> watchSellerProducts(String sellerId) {
    return _products
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ProductModel.fromMap(d.data(), d.id))
            .toList());
  }
}
