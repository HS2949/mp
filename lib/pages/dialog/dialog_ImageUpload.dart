import 'package:mp_db/constants/styles.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart'; // MIME 타입 자동 감지 라이브러리
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;

class UploadImage {
  /// 폴더 및 파일명 입력 다이얼로그 (단일 파일 선택 시 사용)
  static Future<Map<String, String>?> showFolderAndFileNameDialog(
    BuildContext context, {
    required String initialFileName,
    required String initialFolder, // 기본 폴더명을 전달받음
  }) async {
    // 확장자 분리
    String nameWithoutExtension =
        path.basenameWithoutExtension(initialFileName);
    String extension = path.extension(initialFileName);

    final TextEditingController fileNameController =
        TextEditingController(text: '$nameWithoutExtension$extension');

    bool isTapped = false; // 처음 터치 여부 체크

    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          child: SizedBox(
            width: 350,
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text("파일 이름 지정", style: AppTheme.appbarTitleTextStyle),
                  const SizedBox(height: 30),
                  TextField(
                    controller: fileNameController,
                    decoration:
                        const InputDecoration(labelText: "파일명 (확장자 포함)"),
                    onTap: () {
                      if (!isTapped) {
                        // 처음 터치한 경우에만 실행
                        isTapped = true;
                        fileNameController.selection = TextSelection(
                          baseOffset: 0,
                          extentOffset: nameWithoutExtension.length,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(null),
                        child: const Text("취소"),
                      ),
                      TextButton(
                        onPressed: () {
                          String enteredText = fileNameController.text.trim();
                          String finalFileName;

                          if (enteredText.isEmpty) {
                            finalFileName =
                                '${DateTime.now().millisecondsSinceEpoch}$extension';
                          } else {
                            // 사용자가 확장자를 변경하지 못하도록 원래 확장자 유지
                            if (!enteredText.endsWith(extension)) {
                              finalFileName = '$enteredText$extension';
                            } else {
                              finalFileName = enteredText;
                            }
                          }

                          Navigator.of(context).pop({
                            'folder': initialFolder,
                            'fileName': finalFileName
                          });
                        },
                        child: const Text("확인"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 이미지 업로드 및 Firestore에 메타데이터 저장 (단일 또는 다중 파일 지원)
  /// - targetWidth: 압축 후 이미지의 목표 가로 길이 (예: 800)
  /// - quality: JPEG 압축 품질 (0~100)
  /// - compress: true이면 이미지 압축 수행, false이면 원본 업로드
  static Future<List<String>?> uploadNewImage(
    BuildContext context, {
    bool multiple = false,
    String folder = 'uploads', // 호출 단계에서 폴더명을 전달할 수 있음
    int targetWidth = 800,
    int quality = 80,
    bool compress = true,
  }) async {
    final ImagePicker picker = ImagePicker();
    // imageQuality는 기본 내장 압축 옵션이므로 100으로 설정 (직접 압축 처리)
    final List<XFile>? imageFiles = multiple
        ? await picker.pickMultiImage(imageQuality: 100)
        : [
            await picker.pickImage(
                source: ImageSource.gallery, imageQuality: 100)
          ].whereType<XFile>().toList();

    if (imageFiles == null || imageFiles.isEmpty) return null;

    List<String> downloadUrls = [];

    // 다중 파일 업로드인 경우, 기본 파일명(폴더명 뒷부분)을 추출하고
    // Firestore에서 해당 폴더의 파일들 중 마지막 일련번호를 확인함.
    String baseName = '';
    int highestNumber = 0;
    if (imageFiles.length > 1) {
      baseName = folder.split('/').last; // 예: '환상숲_트레킹'
      final querySnapshot = await FirebaseFirestore.instance
          .collection('files')
          .where('folder', isEqualTo: folder)
          .get();
      for (var doc in querySnapshot.docs) {
        String fileName = doc.data()['fileName'];
        if (fileName.startsWith(baseName)) {
          // baseName 뒤에 붙은 일련번호와 확장자를 분리
          String numberPart = fileName.substring(baseName.length);
          int dotIndex = numberPart.lastIndexOf('.');
          if (dotIndex != -1) {
            numberPart = numberPart.substring(0, dotIndex);
          }
          int? number = int.tryParse(numberPart);
          if (number != null && number > highestNumber) {
            highestNumber = number;
          }
        }
      }
    }

    for (int i = 0; i < imageFiles.length; i++) {
      XFile imageFile = imageFiles[i];
      File file = File(imageFile.path);
      String extension = path.extension(imageFile.path); // 원본 확장자 (.png, .jpg 등)
      String fileName = '';
      String selectedFolder = folder;

      if (imageFiles.length == 1) {
        // 단일 파일 선택 시, 다이얼로그를 통해 파일명을 입력받음.
        String initialFileName = path.basename(imageFile.path);
        final options = await showFolderAndFileNameDialog(
          context,
          initialFileName: initialFileName,
          initialFolder: folder,
        );
        if (options == null) return null;
        selectedFolder =
            options['folder']!.isNotEmpty ? options['folder']! : folder;
        fileName = options['fileName']!.isNotEmpty
            ? options['fileName']!
            : '${DateTime.now().millisecondsSinceEpoch}$extension';
      } else {
        // 다중 파일 선택 시, 파일명을 자동으로 baseName + 일련번호 + 확장자로 생성함.
        int seqNumber = highestNumber + i + 1; // 기존 마지막 번호 다음부터 부여
        String seqString = seqNumber.toString().padLeft(3, '0'); // 3자리 번호
        fileName = '$baseName$seqString$extension';
      }

      // MIME 타입 자동 감지
      String? mimeType =
          lookupMimeType(file.path) ?? 'application/octet-stream';

      try {
        Reference storageRef =
            FirebaseStorage.instance.ref().child('$selectedFolder/$fileName');
        SettableMetadata metadata = SettableMetadata(
          contentDisposition: 'inline',
          contentType: mimeType,
        );

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

        List<int> fileBytes;
        if (compress) {
          // 압축 수행: 이미지 읽기, 디코딩, 리사이즈, 재인코딩
          List<int> originalBytes = await file.readAsBytes();
          img.Image? image = img.decodeImage(originalBytes);
          if (image == null) throw Exception("이미지 디코딩 실패");
          img.Image resizedImage = image;
          if (targetWidth < image.width) {
            resizedImage = img.copyResize(image, width: targetWidth);
          }
          fileBytes = img.encodeJpg(resizedImage, quality: quality);
        } else {
          // 압축하지 않고 원본 데이터 그대로 사용
          fileBytes = await file.readAsBytes();
        }

        // 압축(또는 원본) 데이터를 Firebase Storage에 업로드 (putData 사용)
        UploadTask uploadTask = storageRef.putData(
          Uint8List.fromList(fileBytes),
          metadata,
        );
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);

        if (loadingShown) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        // Firestore에 파일 메타데이터 저장
        await FirebaseFirestore.instance.collection('files').add({
          'folder': selectedFolder,
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
