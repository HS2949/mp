import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mp_db/constants/styles.dart';

// 추가: 그리드뷰 UI 및 관련 모델/함수
import 'compression/image_compression.dart';
import 'dialog_ImagePick.dart';

/// 진행 상태 다이얼로그를 표시하는 함수 (반환값 없음)
void showProgressDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (innerContext) {
      return Center(
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                style: AppTheme.fieldLabelTextStyle.copyWith(
                  decoration: TextDecoration.none,
                ),
              ),
              SizedBox(height: 16),
              CircularProgressIndicator(),
            ],
          ),
        ),
      );
    },
  );
}

class UploadImage {
  /// 파일 선택 후 그리드뷰로 선택한 이미지와 정보를 보여주고,
  /// 상단 업로드 버튼을 누르면 수정된 정보와 함께 이미지 파일들을 반환하여
  /// 나머지 업로드 코드를 진행할 수 있도록 함.
  static Future<List<String>?> uploadNewImage(
    BuildContext context, {
    bool multiple = false,
    String folder = 'uploads',
  }) async {
    final List<XFile> imageFiles = [];

    // 선택한 각 이미지의 정보 취합 (예시로 getImageInfo 함수 사용)
    List<SelectedImageInfo> imagesInfo = await Future.wait(
      imageFiles.map((xfile) => getImageInfo(xfile)),
    );

    // 그리드뷰 화면으로 이동하여 사용자에게 확인 및 파일명 수정 기능 제공
    List<SelectedImageInfo>? finalImages = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            SelectedImagesGridView(initialImages: imagesInfo, folder: folder),
      ),
    );

    // 사용자가 업로드를 취소한 경우
    if (finalImages == null || finalImages.isEmpty) return null;

    List<String> downloadUrls = [];
    for (int i = 0; i < finalImages.length; i++) {
      SelectedImageInfo imageInfo = finalImages[i];
      File file = File(imageInfo.imageFile.path);
      String fileName = imageInfo.fileName; // 기존 파일명 (예: image.jpg)

      // 미리 새 파일명 생성 (extension을 webp로 변경)
      String newFileName = fileName.replaceAll(
        RegExp(r'\.(jpg|jpeg|png)$', caseSensitive: false),
        '.webp',
      );

      try {
        // 변환 단계 진행 메시지 생성
        String transformMessage = finalImages.length > 1
            ? "$newFileName 변환 중..\n(${i + 1}/${finalImages.length})"
            : "$newFileName 변환 중..";
        showProgressDialog(context, transformMessage);

        File? processedFile = await ImageCompressor.compressAndResize(
          inputFile: file,
          quality: imageInfo.imageQuality, // 예: 80
          targetWidth: imageInfo.width, // 필요한 경우
          targetHeight: imageInfo.height, // 필요한 경우
        );
        // 변환 완료 후 다이얼로그 닫기
        Navigator.of(context, rootNavigator: true).pop();

        // 변환 실패 시 건너뜁니다.
        if (processedFile == null) {
          print("이미지 처리 실패: $fileName");
          continue;
        }

        // 처리된 파일의 바이트 읽기
        Uint8List fileBytes = await processedFile.readAsBytes();

        // Firebase Storage 업로드 준비 (새로운 파일명 사용)
        Reference storageRef =
            FirebaseStorage.instance.ref().child('$folder/$newFileName');

        // 업로드 진행 메시지 생성 (파일이 여러 개일 경우 진행 상황 표시)
        String uploadMessage = finalImages.length > 1
            ? "$newFileName 업로드 중..\n(${i + 1}/${finalImages.length})"
            : "$newFileName 업로드 중..";
        showProgressDialog(context, uploadMessage);

        // 명시적으로 webp MIME 타입 사용
        String mimeType = 'image/webp';
        UploadTask uploadTask = storageRef.putData(
          fileBytes,
          SettableMetadata(
            contentDisposition: 'inline',
            contentType: mimeType,
          ),
        );
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);

        // 업로드 완료 후 다이얼로그 닫기
        Navigator.of(context, rootNavigator: true).pop();

        // Firestore에 파일 메타데이터 저장
        await FirebaseFirestore.instance.collection('files').add({
          'folder': folder,
          'fileName': newFileName,
          'downloadUrl': downloadUrl,
          'uploadedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print("업로드 실패: $e");
        Navigator.of(context, rootNavigator: true).pop();
        return null;
      }
    }

    return downloadUrls;
  }
}
