import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/order_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/order_repository.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository();
});

/// The signed-in user's own order history (as a buyer).
final myOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final uid = ref.watch(authStateChangesProvider).value?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(orderRepositoryProvider).watchBuyerOrders(uid);
});

/// Orders placed with the signed-in user's shop (as a seller).
final sellerOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final uid = ref.watch(authStateChangesProvider).value?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(orderRepositoryProvider).watchSellerOrders(uid);
});

final orderDetailProvider =
    FutureProvider.family<OrderModel?, String>((ref, orderId) {
  return ref.watch(orderRepositoryProvider).fetchOrder(orderId);
});
