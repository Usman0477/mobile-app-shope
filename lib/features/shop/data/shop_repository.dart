import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../models/shop_model.dart';

class ShopRepository {
  ShopRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<ShopModel?> fetchShop(String shopId) async {
    final doc =
        await _firestore.collection(FirestorePaths.shops).doc(shopId).get();
    if (!doc.exists) return null;
    return ShopModel.fromMap(doc.data()!, doc.id);
  }
}
