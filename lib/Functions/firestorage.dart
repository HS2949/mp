// // 사용예제제
// // final service = FirestoreStorageService();

// // // 사진 업로드 및 URL 반환
// // String? photoUrl = await service.uploadPhoto('employee_photos/employee001.jpg');

// // if (photoUrl != null) {
// //   // Firestore에 저장
// //   await service.savePhotoUrlToFirestore(
// //     collectionName: 'employee',
// //     documentId: 'employee001',
// //     fieldName: 'photoUrl',
// //     photoUrl: photoUrl,
// //   );
// // }

// // //사진 삭제
// // await service.deletePhoto('employee_photos/employee001.jpg');

// // //사진 변경
// // // 새 파일 경로 지정
// // String newFilePath = 'path/to/new_photo.jpg';
// // // 사진 변경
// // String? newPhotoUrl = await service.updatePhoto(
// //   storagePath: 'employee_photos/employee001.jpg',
// //   newFilePath: newFilePath,
// // );
// // if (newPhotoUrl != null) {
// //   // Firestore에 새 URL 저장
// //   await service.savePhotoUrlToFirestore(
// //     collectionName: 'employee',
// //     documentId: 'employee001',
// //     fieldName: 'photoUrl',
// //     photoUrl: newPhotoUrl,
// //   );
// // }

// // //사진 조회
// // String? photoUrl = await service.getPhotoUrl('employee_photos/employee001.jpg');
// // if (photoUrl != null) {
// //   print('사진 URL: $photoUrl');
// // }

// import 'dart:io';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:file_picker/file_picker.dart';

// class FirestoreStorageService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseStorage _storage = FirebaseStorage.instance;

//   /// 1. 사진 업로드 및 URL 반환
//   Future<String?> uploadPhoto(String storagePath) async {
//     try {
//       // 파일 선택
//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         type: FileType.image,
//       );

//       if (result != null) {
//         File file = File(result.files.single.path!);

//         // Storage 경로에 업로드
//         final ref = _storage.ref(storagePath);
//         await ref.putFile(file);

//         // 업로드된 파일 URL 반환
//         String downloadUrl = await ref.getDownloadURL();
//         return downloadUrl;
//       } else {
//         print('파일 선택 취소');
//         return null;
//       }
//     } catch (e) {
//       print('사진 업로드 오류: $e');
//       return null;
//     }
//   }

//   /// 2. 업로드된 URL을 Firestore에 저장
//   Future<void> savePhotoUrlToFirestore({
//     required String collectionName,
//     required String documentId,
//     required String fieldName,
//     required String photoUrl,
//   }) async {
//     try {
//       await _firestore
//           .collection(collectionName)
//           .doc(documentId)
//           .set({fieldName: photoUrl}, SetOptions(merge: true));
//       print('사진 URL 저장 완료');
//     } catch (e) {
//       print('사진 URL 저장 오류: $e');
//     }
//   }

//   /// 3. 사진 삭제
//   Future<void> deletePhoto(String storagePath) async {
//     try {
//       final ref = _storage.ref(storagePath);
//       await ref.delete();
//       print('사진 삭제 완료');
//     } catch (e) {
//       print('사진 삭제 오류: $e');
//     }
//   }

//   /// 4. 사진 변경 (기존 사진 삭제 후 새로 업로드)
//   Future<String?> updatePhoto({
//     required String storagePath,
//     required String newFilePath,
//   }) async {
//     try {
//       // 기존 사진 삭제
//       await deletePhoto(storagePath);

//       // 새로운 사진 업로드
//       File file = File(newFilePath);
//       final ref = _storage.ref(storagePath);
//       await ref.putFile(file);

//       // 업로드된 새 파일의 URL 반환
//       String newDownloadUrl = await ref.getDownloadURL();
//       return newDownloadUrl;
//     } catch (e) {
//       print('사진 변경 오류: $e');
//       return null;
//     }
//   }

//   /// 5. 사진 URL 조회
//   Future<String?> getPhotoUrl(String storagePath) async {
//     try {
//       final ref = _storage.ref(storagePath);
//       String downloadUrl = await ref.getDownloadURL();
//       return downloadUrl;
//     } catch (e) {
//       print('사진 URL 조회 오류: $e');
//       return null;
//     }
//   }
// }
