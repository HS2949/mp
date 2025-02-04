import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/item_model.dart'; // Item, SubItem 모델 import


class ItemDetailRepository {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  /// 🔹 특정 아이템 문서의 실시간 데이터 감지 (하위 컬렉션 포함)
  Stream<Item?> streamItemWithSubItems({
    required String collectionName,
    required String subcollectionName,
    required String itemId,
  }) {
    try {
      // 🔹 아이템 데이터 실시간 감지
      Stream<DocumentSnapshot<Map<String, dynamic>>> itemStream =
          firestore.collection(collectionName).doc(itemId).snapshots();

      // 🔹 하위 컬렉션(`Sub_items`) 실시간 감지
      Stream<QuerySnapshot<Map<String, dynamic>>> subItemsStream =
          firestore.collection(collectionName).doc(itemId).collection(subcollectionName).snapshots();

      return itemStream.asyncMap((itemSnapshot) async {
        if (!itemSnapshot.exists) return null;

        Map<String, dynamic> itemData = itemSnapshot.data() ?? {};

        // 🔹 하위 컬렉션 데이터 가져오기
        QuerySnapshot<Map<String, dynamic>> subItemsSnapshot = await subItemsStream.first;

        List<SubItem> subItems = subItemsSnapshot.docs
            .map((doc) => SubItem.fromFirestore(doc.id, doc.data()))
            .toList();

        // 🔹 `Item` 객체 변환
        return Item.fromFirestore(itemId, itemData, subItems);
      });
    } catch (e) {
      print('🔥 Firestore 실시간 데이터 감지 오류: $e');
      return const Stream.empty();
    }
  }
}
