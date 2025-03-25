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
    bool autoGenerateId = true,
  }) async {
    try {
      if (autoGenerateId) {
        // 자동 ID 생성
        await _firestore.collection(collectionName).add(data);
      } else {
        // 수동 ID 부여
        // Firestore 컬렉션 가져오기
        final collection = _firestore.collection(collectionName);
        final snapshot = await collection.get();
        print('데이터 읽기 ');

        // 기존 문서의 ID를 정수 리스트로 수집
        final List<int> existingIds = [];
        for (var doc in snapshot.docs) {
          final int? id = int.tryParse(doc.id); // 문서 ID를 정수로 변환
          if (id != null) {
            existingIds.add(id);
          }
        }

        // 정렬된 ID 리스트
        existingIds.sort();

        // 중간에 빠진 ID를 찾는 로직
        bool chk = false;
        int newId = 1; // 기본적으로 첫 번째 ID를 1로 설정
        for (int i = 0; i < existingIds.length; i++) {
          if (existingIds[i] != i + 1) {
            newId = i + 1; // 빠진 ID 발견
            chk = true;
            break;
          }
        }

        // 중간에 빠진 ID가 없는 경우 가장 큰 ID + 1
        if (!chk && existingIds.length > 0) {
          newId = existingIds.last + 1;
        }

        // 새로운 문서 ID를 문자열로 변환
        final String newDocumentId = newId.toString();

        // Firestore에 데이터 저장
        await collection.doc(newDocumentId).set(data);
      }
      print('데이터 추가 성공');
    } catch (e) {
      print('데이터 추가 오류: $e');
    }
  }

  // 2. 데이터 조회
  Future<QuerySnapshot<Map<String, dynamic>>> getItems(
      String collectionName) async {
    try {
      final querySnapshot = await _firestore.collection(collectionName).get();
      print('데이터 읽기 ');
      print('데이터 조회 성공');
      return querySnapshot;
    } catch (e) {
      print('데이터 조회 오류: $e');
      rethrow;
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getItemsSnapshot(
      String collectionName) {
    try {
      // Firestore 컬렉션의 데이터를 실시간 스트림으로 구독
      final Stream<QuerySnapshot<Map<String, dynamic>>> stream =
          _firestore.collection(collectionName).snapshots();
      print('실시간 데이터 구독 성공');
      return stream;
    } catch (e) {
      print('실시간 데이터 구독 오류: $e');
      rethrow;
    }
  }

// Firestore 컬렉션에서 특정 문서 ID를 가져옴
// Stream<DocumentSnapshot<Map<String, dynamic>>> stream =
  //     getDocSnapshot('Items', 'EGA9krhnxChp3EcXHBG9');

  // stream.listen((DocumentSnapshot<Map<String, dynamic>> snapshot) {
  //   if (snapshot.exists) {
  //     print('문서 ID: ${snapshot.id}, 데이터: ${snapshot.data()}');
  //   } else {
  //     print('문서를 찾을 수 없음');
  //   }
  // }, onError: (error) {
  //   print('스트림 오류 발생: $error');
  // });
  Stream<DocumentSnapshot<Map<String, dynamic>>> getDocSnapshot(
      String collectionName, String documentId) {
    try {
      final Stream<DocumentSnapshot<Map<String, dynamic>>> stream =
          FirebaseFirestore.instance
              .collection(collectionName)
              .doc(documentId)
              .snapshots();

      print('문서 ID [$documentId] 실시간 데이터 구독 성공');
      return stream;
    } catch (e) {
      print('실시간 데이터 구독 오류: $e');
      rethrow;
    }
  }

// Firestore에서 특정 조건을 만족하는 문서들의 실시간 변경 사항을 스트림으로 반환합니다.
// getItemsSnapshot('your_collection_name', {
//   'IsDefault': true,   <--- 조건들들
//   'Category': 'Books',
// });
  // Stream<QuerySnapshot<Map<String, dynamic>>> stream =
  //     getConditionSnapshot('users', {'city': 'New York'});
  // stream.listen((snapshot) {
  //   for (var doc in snapshot.docs) {
  //     print('사용자: ${doc.data()}');
  //   }

  Stream<QuerySnapshot<Map<String, dynamic>>> getConditionSnapshot(
      String collectionName, Map<String, dynamic> conditions) {
    try {
      // Firestore 컬렉션에 접근
      Query<Map<String, dynamic>> query = _firestore.collection(collectionName);

      // 조건을 동적으로 추가
      conditions.forEach((field, value) {
        query = query.where(field, isEqualTo: value);
      });

      // 스트림 반환
      final Stream<QuerySnapshot<Map<String, dynamic>>> stream =
          query.snapshots();

      print('조건에 맞는 실시간 데이터 구독 성공');
      return stream;
    } catch (e) {
      print('실시간 데이터 구독 오류: $e');
      rethrow;
    }
  }

  // Firestore에서 특정 문서를 documentId를 이용하여 한 번만 조회하는 함수입니다.
  // 컬렉션 이름 과 Doc ID만 이용하여 데이터
  //   DocumentSnapshot<Map<String, dynamic>> snapshot =
  //     await getItemById(collectionName: 'users', documentId: 'user1');
  //     print('단일 사용자 정보: ${snapshot.data()}');
  Future<DocumentSnapshot<Map<String, dynamic>>> getItemById(
      {required String collectionName, required String documentId}) async {
    try {
      final docSnapshot =
          await _firestore.collection(collectionName).doc(documentId).get();
          print('데이터 읽기 ');
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
      await _firestore
          .collection(collectionName)
          .doc(documentId)
          .update(updatedData);
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
          print('데이터 읽기 ');

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
          print('데이터 읽기 ');

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

// 🔹 특정 필드 추가 함수
  Future<void> addKeywordValue(
      String itemId, String key, String value, bool isDefault) async {
    try {
      if (isDefault) {
        //  기본 아이템 필드 업데이트
        await _firestore.collection('Items').doc(itemId).set(
          {key: value},
          SetOptions(merge: true),
        );
        print(" Firestore 업데이트 성공 (기본 필드): $key -> $value");
      } else {
        //  하위 컬렉션 Sub_Items에 키-값 추가 (없으면 생성)
        DocumentReference subItemRef = _firestore
            .collection('Items')
            .doc(itemId)
            .collection('Sub_Items')
            .doc(); // 자동 생성된 문서 ID 사용

        await subItemRef.set({
          key: value,
        }, SetOptions(merge: true));

        print(" Firestore 업데이트 성공 (Sub_Items): $key -> $value");
      }
    } catch (e) {
      print(" Firestore 추가 오류: $e");
    }
  }

  // 🔹 특정 필드 삭제 함수 (기존에 있는 함수)
  Future<void> deleteKeywordValue(String itemId, String key) async {
    try {
      await _firestore.collection('Items').doc(itemId).update({
        key: FieldValue.delete(),
      });
    } catch (e) {
      print(" Firestore 삭제 오류: $e");
    }
  }
}
