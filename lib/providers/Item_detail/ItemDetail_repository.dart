import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mp_db/Functions/firestore.dart';
import 'package:mp_db/models/custom_error.dart';

class ItemDetailRepository {
  final FirestoreService firestoreService = FirestoreService();

  Future<Map<String, dynamic>?> getItem({
    required String collectionName,
    required String id,
  }) async {
    try {
      // FirestoreService의 getDocSnapshot을 사용하여 특정 문서 ID 스트림 가져오기
      Stream<DocumentSnapshot<Map<String, dynamic>>> stream =
          firestoreService.getDocSnapshot(collectionName, id);

      // 🔹 첫 번째 데이터 스냅샷만 가져오기 (Stream → Future 변환)
      DocumentSnapshot<Map<String, dynamic>> snapshot = await stream.first;

      if (snapshot.exists) {
        print('문서 ID: ${snapshot.id}, 데이터: ${snapshot.data()}');
        return snapshot.data();
      } else {
        print('문서를 찾을 수 없음');
        return null;
      }
    } catch (e) {
      print('아이템 조회 오류: $e');
      throw CustomError(
        code: 'Exception',
        message: e.toString(),
        plugin: 'flutter_error/server_error',
      );
    }
  }
}
