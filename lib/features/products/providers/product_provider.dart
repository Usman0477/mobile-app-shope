import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/product_model.dart';
import '../data/product_repository.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

/// Static list for now — Phase 4 (admin panel) will make this
/// admin-managed via the `categories` Firestore collection instead.
const productCategories = <String>[
  'All',
  'Electronics',
  'Fashion',
  'Home & Living',
  'Beauty',
  'Groceries',
  'Sports',
  'Books',
  'Toys',
];

/// Which category chip is currently selected on the home screen.
final selectedCategoryProvider = StateProvider<String>((ref) => 'All');

/// Live product stream, filtered by whatever category is selected.
final productsStreamProvider = StreamProvider<List<ProductModel>>((ref) {
  final category = ref.watch(selectedCategoryProvider);
  final repo = ref.watch(productRepositoryProvider);
  return repo.watchProducts(category: category);
});

/// A single product's detail, fetched once (not a live stream) —
/// simple and cheap for a detail page.
final productDetailProvider =
    FutureProvider.family<ProductModel?, String>((ref, productId) {
  return ref.watch(productRepositoryProvider).fetchProduct(productId);
});

final relatedProductsProvider = FutureProvider.family<List<ProductModel>,
    ({String shopId, String excludeProductId})>((ref, args) {
  return ref.watch(productRepositoryProvider).fetchRelatedProducts(
        shopId: args.shopId,
        excludeProductId: args.excludeProductId,
      );
});
