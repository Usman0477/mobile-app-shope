import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';

/// Firestore document shape: users/{uid}
class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String? phone;
  final String? photoUrl;
  final String role; // customer | seller | admin
  final bool emailVerified;
  final String? shopId; // set once the user opens a shop
  final List<String> favoriteShopIds;
  final List<String> wishlistProductIds;
  final DateTime createdAt;
  final bool isBanned;

  const UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    this.phone,
    this.photoUrl,
    this.role = AppConstants.roleCustomer,
    this.emailVerified = false,
    this.shopId,
    this.favoriteShopIds = const [],
    this.wishlistProductIds = const [],
    required this.createdAt,
    this.isBanned = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      photoUrl: map['photoUrl'],
      role: map['role'] ?? AppConstants.roleCustomer,
      emailVerified: map['emailVerified'] ?? false,
      shopId: map['shopId'],
      favoriteShopIds: List<String>.from(map['favoriteShopIds'] ?? const []),
      wishlistProductIds:
          List<String>.from(map['wishlistProductIds'] ?? const []),
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      isBanned: map['isBanned'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'role': role,
      'emailVerified': emailVerified,
      'shopId': shopId,
      'favoriteShopIds': favoriteShopIds,
      'wishlistProductIds': wishlistProductIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'isBanned': isBanned,
    };
  }

  UserModel copyWith({
    String? fullName,
    String? phone,
    String? photoUrl,
    String? role,
    bool? emailVerified,
    String? shopId,
    List<String>? favoriteShopIds,
    List<String>? wishlistProductIds,
    bool? isBanned,
  }) {
    return UserModel(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      emailVerified: emailVerified ?? this.emailVerified,
      shopId: shopId ?? this.shopId,
      favoriteShopIds: favoriteShopIds ?? this.favoriteShopIds,
      wishlistProductIds: wishlistProductIds ?? this.wishlistProductIds,
      createdAt: createdAt,
      isBanned: isBanned ?? this.isBanned,
    );
  }
}
