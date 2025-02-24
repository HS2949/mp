import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:mp_db/constants/styles.dart';

// 추가: 그리드뷰 UI 및 관련 모델/함수
import 'compression/image_compression.dart';
import 'dialog_ImagePick.dart';
// 추가: FFmpeg를 통한 이미지 압축/리사이징 및 webp 변환 기능 호출


class UploadImage {
  /// 파일 선택 후 그리드뷰로 선택한 이미지와 정보를 보여주고,
  /// 상단 업로드 버튼을 누르면 수정된 정보와 함께 이미지 파일들을 반환하여
  /// 나머지 업로드 코드를 진행할 수 있도록 함.
  static Future<List<String>?> uploadNewImage(
    BuildContext context, {
    bool multiple = false,
    String folder = 'uploads',
    int targetWidth = 0, // 현재는 내부에서 사용하지 않음
    int imageQuality = 100, // 현재는 내부에서 사용하지 않음
  }) async {
    final List<XFile> imageFiles = [];
    // (파일 선택 관련 기존 코드 생략)

    // 선택한 각 이미지의 정보 취합
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

      // 수정된 파일명 사용
      String fileName = imageInfo.fileName;

      try {
        // FFmpeg를 사용하여 이미지 압축, 리사이징, webp 변환
        // 여기서 imageInfo에는 imageQuality, width, height 속성이 포함되어 있다고 가정합니다.
        File? processedFile = await ImageCompressor.compressAndResize(
          inputFile: file,
          quality: imageInfo.imageQuality, // 예: 80
          width: imageInfo.width,          // 예: 800
          height: imageInfo.height,        // 예: 600
        );

        // 변환 실패 시 예외 처리 또는 continue 처리
        if (processedFile == null) {
          print("이미지 처리 실패: $fileName");
          continue;
        }

        // 처리된 파일의 바이트 읽기
        Uint8List fileBytes = await processedFile.readAsBytes();

        // Firebase Storage 업로드 준비
        Reference storageRef =
            FirebaseStorage.instance.ref().child('$folder/$fileName');

        bool loadingShown = false;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (innerContext) {
            loadingShown = true;
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
                      '$fileName 업로드 중..',
                      style: AppTheme.fieldLabelTextStyle
                          .copyWith(decoration: TextDecoration.none),
                    ),
                    SizedBox(height: 16),
                    CircularProgressIndicator(),
                  ],
                ),
              ),
            );
          },
        );

        String? mimeType = lookupMimeType(fileName);
        UploadTask uploadTask = storageRef.putData(
          fileBytes,
          SettableMetadata(
            contentDisposition: 'inline',
            contentType: mimeType ?? 'application/octet-stream',
          ),
        );
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);

        if (loadingShown) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        // Firestore에 파일 메타데이터 저장
        await FirebaseFirestore.instance.collection('files').add({
          'folder': folder,
          'fileName': fileName,
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
