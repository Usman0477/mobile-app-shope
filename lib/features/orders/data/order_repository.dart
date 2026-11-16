import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../models/order_model.dart';

class OrderRepository {
  OrderRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection(FirestorePaths.orders);

  Future<String> createOrder(OrderModel order) async {
    final doc = await _orders.add(order.toMap());
    return doc.id;
  }

  /// A buyer's own order history, newest first.
  Stream<List<OrderModel>> watchBuyerOrders(String buyerId) {
    return _orders
        .where('buyerId', isEqualTo: buyerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => OrderModel.fromMap(d.data(), d.id)).toList());
  }

  /// Orders placed with a specific seller — used by the seller's own
  /// "Orders" tab in their dashboard.
  Stream<List<OrderModel>> watchSellerOrders(String sellerId) {
    return _orders
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => OrderModel.fromMap(d.data(), d.id)).toList());
  }

  Future<OrderModel?> fetchOrder(String orderId) async {
    final doc = await _orders.doc(orderId).get();
    if (!doc.exists) return null;
    return OrderModel.fromMap(doc.data()!, doc.id);
  }

  Future<void> updateStatus(String orderId, String status) {
    return _orders.doc(orderId).update({'status': status});
  }
}
