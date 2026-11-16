import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/shop_model.dart';
import '../../../models/product_model.dart';
import '../../products/providers/product_provider.dart';
import '../data/shop_repository.dart';

final shopRepositoryProvider = Provider<ShopRepository>((ref) => ShopRepository());

final shopDetailProvider =
    FutureProvider.family<ShopModel?, String>((ref, shopId) {
  return ref.watch(shopRepositoryProvider).fetchShop(shopId);
});

final shopProductsProvider =
    StreamProvider.family<List<ProductModel>, String>((ref, shopId) {
  return ref.watch(productRepositoryProvider).watchShopProducts(shopId);
});
