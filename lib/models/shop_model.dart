import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore document shape: shops/{shopId}
class ShopModel {
  final String id;
  final String ownerId;
  final String name;
  final String? logoUrl;
  final String? bannerUrl;
  final String description;
  final String address;
  final double? latitude;
  final double? longitude;
  final String? whatsapp;
  final String? phone;
  final String? easyPaisaNumber;
  final String? jazzCashNumber;
  final bool deliveryAvailable;
  final double deliveryCharges;
  final String status; // pending | approved | rejected | banned
  final double rating;
  final int reviewCount;
  final int followerCount;
  final DateTime createdAt;

  const ShopModel({
    required this.id,
    required this.ownerId,
    required this.name,
    this.logoUrl,
    this.bannerUrl,
    this.description = '',
    this.address = '',
    this.latitude,
    this.longitude,
    this.whatsapp,
    this.phone,
    this.easyPaisaNumber,
    this.jazzCashNumber,
    this.deliveryAvailable = false,
    this.deliveryCharges = 0,
    this.status = 'pending',
    this.rating = 0,
    this.reviewCount = 0,
    this.followerCount = 0,
    required this.createdAt,
  });

  factory ShopModel.fromMap(Map<String, dynamic> map, String id) {
    return ShopModel(
      id: id,
      ownerId: map['ownerId'] ?? '',
      name: map['name'] ?? '',
      logoUrl: map['logoUrl'],
      bannerUrl: map['bannerUrl'],
      description: map['description'] ?? '',
      address: map['address'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      whatsapp: map['whatsapp'],
      phone: map['phone'],
      easyPaisaNumber: map['easyPaisaNumber'],
      jazzCashNumber: map['jazzCashNumber'],
      deliveryAvailable: map['deliveryAvailable'] ?? false,
      deliveryCharges: (map['deliveryCharges'] as num?)?.toDouble() ?? 0,
      status: map['status'] ?? 'pending',
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: map['reviewCount'] ?? 0,
      followerCount: map['followerCount'] ?? 0,
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'name': name,
      'logoUrl': logoUrl,
      'bannerUrl': bannerUrl,
      'description': description,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'whatsapp': whatsapp,
      'phone': phone,
      'easyPaisaNumber': easyPaisaNumber,
      'jazzCashNumber': jazzCashNumber,
      'deliveryAvailable': deliveryAvailable,
      'deliveryCharges': deliveryCharges,
      'status': status,
      'rating': rating,
      'reviewCount': reviewCount,
      'followerCount': followerCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
