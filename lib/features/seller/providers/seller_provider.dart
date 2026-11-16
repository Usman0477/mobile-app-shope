import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/product_model.dart';
import '../../../models/shop_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/seller_repository.dart';

final sellerRepositoryProvider = Provider<SellerRepository>((ref) {
  return SellerRepository();
});

/// The signed-in user's own shop, if they have one (based on
/// `shopId` on their user profile). Null if they haven't created a
/// shop yet.
final myShopProvider = FutureProvider<ShopModel?>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  if (profile?.shopId == null) return null;
  return ref.watch(sellerRepositoryProvider).fetchShop(profile!.shopId!);
});

/// Live list of the signed-in seller's own products (all statuses).
final myProductsProvider = StreamProvider<List<ProductModel>>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final uid = authState.value?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(sellerRepositoryProvider).watchSellerProducts(uid);
});
