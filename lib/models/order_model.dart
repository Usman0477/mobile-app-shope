import 'package:cloud_firestore/cloud_firestore.dart';

/// A single line item snapshot inside an order — deliberately copies
/// name/price/image at time of purchase rather than referencing the
/// live product, so an order's history stays accurate even if the
/// seller later edits or deletes that product.
class OrderItem {
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String? imageUrl;

  const OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.imageUrl,
  });

  double get lineTotal => price * quantity;

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      quantity: map['quantity'] ?? 1,
      imageUrl: map['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        'price': price,
        'quantity': quantity,
        'imageUrl': imageUrl,
      };
}

/// Firestore document shape: orders/{orderId}
class OrderModel {
  final String id;
  final String buyerId;
  final String buyerName;
  final String sellerId;
  final String shopId;
  final String shopName;
  final List<OrderItem> items;

  final String deliveryOption; // delivery | pickup
  final String? addressLine; // house/street/area
  final String? city;
  final String? phone;
  final String? specialInstructions;

  final String paymentMethod; // cod | easypaisa | jazzcash
  final String? paymentReference; // transaction ID the buyer enters

  /// pending -> confirmed -> completed, or cancelled at any point
  /// before completed.
  final String status;

  final double subtotal;
  final double deliveryCharges;
  final double total;
  final DateTime createdAt;

  const OrderModel({
    required this.id,
    required this.buyerId,
    this.buyerName = '',
    required this.sellerId,
    required this.shopId,
    this.shopName = '',
    required this.items,
    this.deliveryOption = 'pickup',
    this.addressLine,
    this.city,
    this.phone,
    this.specialInstructions,
    this.paymentMethod = 'cod',
    this.paymentReference,
    this.status = 'pending',
    required this.subtotal,
    this.deliveryCharges = 0,
    required this.total,
    required this.createdAt,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, String id) {
    return OrderModel(
      id: id,
      buyerId: map['buyerId'] ?? '',
      buyerName: map['buyerName'] ?? '',
      sellerId: map['sellerId'] ?? '',
      shopId: map['shopId'] ?? '',
      shopName: map['shopName'] ?? '',
      items: (map['items'] as List<dynamic>? ?? [])
          .map((e) => OrderItem.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      deliveryOption: map['deliveryOption'] ?? 'pickup',
      addressLine: map['addressLine'],
      city: map['city'],
      phone: map['phone'],
      specialInstructions: map['specialInstructions'],
      paymentMethod: map['paymentMethod'] ?? 'cod',
      paymentReference: map['paymentReference'],
      status: map['status'] ?? 'pending',
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
      deliveryCharges: (map['deliveryCharges'] as num?)?.toDouble() ?? 0,
      total: (map['total'] as num?)?.toDouble() ?? 0,
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'buyerId': buyerId,
      'buyerName': buyerName,
      'sellerId': sellerId,
      'shopId': shopId,
      'shopName': shopName,
      'items': items.map((e) => e.toMap()).toList(),
      'deliveryOption': deliveryOption,
      'addressLine': addressLine,
      'city': city,
      'phone': phone,
      'specialInstructions': specialInstructions,
      'paymentMethod': paymentMethod,
      'paymentReference': paymentReference,
      'status': status,
      'subtotal': subtotal,
      'deliveryCharges': deliveryCharges,
      'total': total,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
