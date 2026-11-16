import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore document shape: products/{productId}
class ProductModel {
  final String id;
  final String sellerId;
  final String shopId;
  final String shopName;
  final String name;
  final String description;
  final double price;
  final double? discountPrice;
  final int stockQuantity;
  final String? sku;
  final String category;
  final String? subcategory;
  final String? brand;
  final List<String> imageUrls;
  final String? videoUrl;
  final bool deliveryAvailable;
  final bool cashOnDeliveryAvailable;
  final bool onlinePaymentAvailable;
  final String status; // active | hidden
  final int viewCount;
  final int salesCount;
  final double rating;
  final int reviewCount;
  final DateTime createdAt;

  const ProductModel({
    required this.id,
    required this.sellerId,
    required this.shopId,
    this.shopName = '',
    required this.name,
    this.description = '',
    required this.price,
    this.discountPrice,
    this.stockQuantity = 0,
    this.sku,
    this.category = '',
    this.subcategory,
    this.brand,
    this.imageUrls = const [],
    this.videoUrl,
    this.deliveryAvailable = false,
    this.cashOnDeliveryAvailable = true,
    this.onlinePaymentAvailable = true,
    this.status = 'active',
    this.viewCount = 0,
    this.salesCount = 0,
    this.rating = 0,
    this.reviewCount = 0,
    required this.createdAt,
  });

  /// The price to actually charge/display as the "current" price.
  double get effectivePrice => discountPrice ?? price;

  bool get hasDiscount => discountPrice != null && discountPrice! < price;

  int get discountPercent => hasDiscount
      ? (((price - discountPrice!) / price) * 100).round()
      : 0;

  factory ProductModel.fromMap(Map<String, dynamic> map, String id) {
    return ProductModel(
      id: id,
      sellerId: map['sellerId'] ?? '',
      shopId: map['shopId'] ?? '',
      shopName: map['shopName'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      discountPrice: (map['discountPrice'] as num?)?.toDouble(),
      stockQuantity: map['stockQuantity'] ?? 0,
      sku: map['sku'],
      category: map['category'] ?? '',
      subcategory: map['subcategory'],
      brand: map['brand'],
      imageUrls: List<String>.from(map['imageUrls'] ?? const []),
      videoUrl: map['videoUrl'],
      deliveryAvailable: map['deliveryAvailable'] ?? false,
      cashOnDeliveryAvailable: map['cashOnDeliveryAvailable'] ?? true,
      onlinePaymentAvailable: map['onlinePaymentAvailable'] ?? true,
      status: map['status'] ?? 'active',
      viewCount: map['viewCount'] ?? 0,
      salesCount: map['salesCount'] ?? 0,
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: map['reviewCount'] ?? 0,
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sellerId': sellerId,
      'shopId': shopId,
      'shopName': shopName,
      'name': name,
      'description': description,
      'price': price,
      'discountPrice': discountPrice,
      'stockQuantity': stockQuantity,
      'sku': sku,
      'category': category,
      'subcategory': subcategory,
      'brand': brand,
      'imageUrls': imageUrls,
      'videoUrl': videoUrl,
      'deliveryAvailable': deliveryAvailable,
      'cashOnDeliveryAvailable': cashOnDeliveryAvailable,
      'onlinePaymentAvailable': onlinePaymentAvailable,
      'status': status,
      'viewCount': viewCount,
      'salesCount': salesCount,
      'rating': rating,
      'reviewCount': reviewCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
