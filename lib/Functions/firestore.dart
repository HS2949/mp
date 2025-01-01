// 사용 예제
// final firestoreService = FirestoreService();
// // 데이터 추가
// firestoreService.addItem(
//   collectionName: 'users',
//   data: {'name': 'John Doe', 'email': 'john@example.com'},
// );

// // 데이터 조회
// firestoreService.getItems('users').then((querySnapshot) {
//   for (var doc in querySnapshot.docs) {
//     print(doc.data());
//   }
// });

// // 데이터 수정
// firestoreService.updateItem(
//   collectionName: 'users',
//   documentId: 'documentIdHere',
//   updatedData: {'email': 'new_email@example.com'},
// );

// // 데이터 삭제
// firestoreService.deleteItem(
//   collectionName: 'users',
//   documentId: 'documentIdHere',
// );

// // 문서 ID 조회
// String? documentId = await firestoreService.findDocumentId(
//   collectionName: 'users',
//   fieldName: 'email',
//   value: 'john@example.com',
// );



// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. 데이터 추가
  Future<void> addItem({
    required String collectionName,
    required Map<String, dynamic> data,
    String? documentId,
  }) async {
    try {
      if (documentId != null) {
        await _firestore.collection(collectionName).doc(documentId).set(data);
      } else {
        await _firestore.collection(collectionName).add(data);
      }
      print('데이터 추가 성공');
    } catch (e) {
      print('데이터 추가 오류: $e');
    }
  }

  // 2. 데이터 조회
  Future<QuerySnapshot<Map<String, dynamic>>> getItems(String collectionName) async {
    try {
      final querySnapshot = await _firestore.collection(collectionName).get();
      print('데이터 조회 성공');
      return querySnapshot;
    } catch (e) {
      print('데이터 조회 오류: $e');
      rethrow;
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getItemById(
      {required String collectionName, required String documentId}) async {
    try {
      final docSnapshot = await _firestore.collection(collectionName).doc(documentId).get();
      print('단일 데이터 조회 성공');
      return docSnapshot;
    } catch (e) {
      print('단일 데이터 조회 오류: $e');
      rethrow;
    }
  }

  // 3. 데이터 수정
  Future<void> updateItem({
    required String collectionName,
    required String documentId,
    required Map<String, dynamic> updatedData,
  }) async {
    try {
      await _firestore.collection(collectionName).doc(documentId).update(updatedData);
      print('데이터 수정 성공');
    } catch (e) {
      print('데이터 수정 오류: $e');
    }
  }

  // 4. 데이터 삭제
  Future<void> deleteItem({
    required String collectionName,
    required String documentId,
  }) async {
    try {
      await _firestore.collection(collectionName).doc(documentId).delete();
      print('데이터 삭제 성공');
    } catch (e) {
      print('데이터 삭제 오류: $e');
    }
  }


   // 조건으로 문서 검색 후 ID 가져오기
  Future<String?> findDocumentId({
    required String collectionName,
    required String fieldName,
    required dynamic value,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(collectionName)
          .where(fieldName, isEqualTo: value)
          .limit(1) // 조건에 맞는 첫 번째 문서만 가져옴
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      } else {
        print('조건에 맞는 문서가 없습니다.');
        return null;
      }
    } catch (e) {
      print('문서 ID 조회 오류: $e');
      return null;
    }
  }


  //조건으로 조회 후 문서 전체 데이터를 가져오기
  Future<Map<String, dynamic>?> findDocumentData({
  required String collectionName,
  required String fieldName,
  required dynamic value,
}) async {
  try {
    final querySnapshot = await _firestore
        .collection(collectionName)
        .where(fieldName, isEqualTo: value)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.data();
    } else {
      print('조건에 맞는 문서가 없습니다.');
      return null;
    }
  } catch (e) {
    print('문서 데이터 조회 오류: $e');
    return null;
  }
}

}
