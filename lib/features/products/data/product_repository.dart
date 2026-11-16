import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../models/product_model.dart';

/// All product read queries go through here. Keeping Firestore query
/// logic in one place makes it easy to add pagination/caching later
/// without touching every screen that lists products.
class ProductRepository {
  ProductRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection(FirestorePaths.products);

  /// Active products, newest first. Optionally filtered by category.
  Stream<List<ProductModel>> watchProducts({String? category, int limit = 30}) {
    Query<Map<String, dynamic>> query =
        _products.where('status', isEqualTo: 'active');

    if (category != null && category.isNotEmpty && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    query = query.orderBy('createdAt', descending: true).limit(limit);

    return query.snapshots().map((snap) => snap.docs
        .map((d) => ProductModel.fromMap(d.data(), d.id))
        .toList());
  }

  Future<ProductModel?> fetchProduct(String productId) async {
    final doc = await _products.doc(productId).get();
    if (!doc.exists) return null;
    return ProductModel.fromMap(doc.data()!, doc.id);
  }

  /// Other active products from the same shop, excluding the current one.
  Future<List<ProductModel>> fetchRelatedProducts({
    required String shopId,
    required String excludeProductId,
    int limit = 6,
  }) async {
    final snap = await _products
        .where('shopId', isEqualTo: shopId)
        .where('status', isEqualTo: 'active')
        .limit(limit + 1)
        .get();

    return snap.docs
        .map((d) => ProductModel.fromMap(d.data(), d.id))
        .where((p) => p.id != excludeProductId)
        .take(limit)
        .toList();
  }

  /// All active products belonging to one shop — used by the shop page.
  Stream<List<ProductModel>> watchShopProducts(String shopId) {
    return _products
        .where('shopId', isEqualTo: shopId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ProductModel.fromMap(d.data(), d.id))
            .toList());
  }

  Future<void> incrementViewCount(String productId) {
    return _products.doc(productId).update({
      'viewCount': FieldValue.increment(1),
    });
  }
}
