import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/order_model.dart';
import '../../../models/product_model.dart';
import '../../../models/shop_model.dart';
import '../../../models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository();
});

/// True only once the signed-in user's Firestore profile has
/// `role == 'admin'`. There is deliberately no client-side way to
/// grant yourself this role — Firestore rules block a user from
/// changing their own `role` field, so it must be set manually in the
/// Firebase console (see PHASE5_INSTRUCTIONS.md).
final isAdminProvider = Provider<bool>((ref) {
  final profile = ref.watch(userProfileProvider).value;
  return profile?.role == AppConstants.roleAdmin;
});

final allShopsProvider = StreamProvider<List<ShopModel>>((ref) {
  return ref.watch(adminRepositoryProvider).watchAllShops();
});

final allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.watch(adminRepositoryProvider).watchAllUsers();
});

final allProductsAdminProvider = StreamProvider<List<ProductModel>>((ref) {
  return ref.watch(adminRepositoryProvider).watchAllProducts();
});

final allOrdersAdminProvider = StreamProvider<List<OrderModel>>((ref) {
  return ref.watch(adminRepositoryProvider).watchAllOrders();
});
