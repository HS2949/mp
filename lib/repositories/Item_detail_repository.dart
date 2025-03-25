import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart'; // 🔹 RxDart 패키지 추가
import '../models/item_model.dart'; // Item, SubItem 모델 import

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
      Stream<QuerySnapshot<Map<String, dynamic>>> subItemsStream = firestore
          .collection(collectionName)
          .doc(itemId)
          .collection(subcollectionName)
          .snapshots();

      // 🔹 두 개의 스트림을 결합하여 하나의 Stream<Item>으로 변환
      return Rx.combineLatest2(
        itemStream,
        subItemsStream,
        (DocumentSnapshot<Map<String, dynamic>> itemSnapshot,
            QuerySnapshot<Map<String, dynamic>> subItemsSnapshot) {
          if (!itemSnapshot.exists) return null;

          Map<String, dynamic> itemData = itemSnapshot.data() ?? {};

          // 🔹 하위 컬렉션 데이터를 리스트로 변환
          List<SubItem> subItems = subItemsSnapshot.docs
              .map((doc) => SubItem.fromFirestore(doc.id, doc.data()))
              .toList();

          // 🔹 `Item` 객체 생성 및 반환
          return Item.fromFirestore(itemId, itemData, subItems);
        },
      );
    } catch (e) {
      print('🔥 Firestore 실시간 데이터 감지 오류: $e');
      return const Stream.empty();
    }
  }
}
