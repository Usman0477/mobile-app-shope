import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/product_model.dart';

class CartItem {
  final ProductModel product;
  final int quantity;

  const CartItem({required this.product, this.quantity = 1});

  double get lineTotal => product.effectivePrice * quantity;

  CartItem copyWith({int? quantity}) =>
      CartItem(product: product, quantity: quantity ?? this.quantity);
}

/// In-memory cart for now (Phase 2 scope: browse + add to cart).
/// Phase 3 checkout will persist the order to Firestore and clear
/// this on successful placement. Living in memory is intentional
/// here — a cart doesn't need to survive an app kill before checkout
/// exists to consume it.
class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super(const []);

  void add(ProductModel product, {int quantity = 1}) {
    final index = state.indexWhere((item) => item.product.id == product.id);
    if (index == -1) {
      state = [...state, CartItem(product: product, quantity: quantity)];
    } else {
      final updated = [...state];
      updated[index] =
          updated[index].copyWith(quantity: updated[index].quantity + quantity);
      state = updated;
    }
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      remove(productId);
      return;
    }
    state = [
      for (final item in state)
        if (item.product.id == productId)
          item.copyWith(quantity: quantity)
        else
          item,
    ];
  }

  void remove(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  void clear() => state = const [];

  int get itemCount => state.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => state.fold(0, (sum, item) => sum + item.lineTotal);
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

final cartItemCountProvider = Provider<int>((ref) {
  final items = ref.watch(cartProvider);
  return items.fold(0, (sum, item) => sum + item.quantity);
});

final cartSubtotalProvider = Provider<double>((ref) {
  final items = ref.watch(cartProvider);
  return items.fold(0, (sum, item) => sum + item.lineTotal);
});
