import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// MIME 타입을 자동으로 감지하는 라이브러리
// 로그인 필요시 사용
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:mp_db/constants/styles.dart';
import 'package:mp_db/pages/dialog/dialog_ImageUpload.dart';
import 'package:mp_db/utils/widget_help.dart';

/// 파일 삭제 함수: Storage와 Firestore에서 모두 삭제
Future<void> deleteFile(
    BuildContext context, String docId, String downloadUrl) async {
  try {
    // Storage 삭제
    Reference storageRef = FirebaseStorage.instance.refFromURL(downloadUrl);
    await storageRef.delete();
    // Firestore 삭제
    await FirebaseFirestore.instance.collection('files').doc(docId).delete();
    showOverlayMessage(context, '이미지를 삭제하였습니다');
  } catch (e) {
    showOverlayMessage(context, '이미지 삭제 오류');
    print("삭제 실패: $e");
  }
}

/// Firestore에서 파일 목록을 조회 (문서 ID 포함)
/// 폴더명이 전달된 경우 해당 폴더의 파일만 조회
Future<List<Map<String, dynamic>>> fetchFileListFromFirestore({
  String? folder,
}) async {
  Query query = FirebaseFirestore.instance.collection('files');

  if (folder != null && folder.isNotEmpty) {
    query = query.where('folder', isEqualTo: folder);
  }

  query = query.orderBy('uploadedAt', descending: true);
  QuerySnapshot snapshot = await query.get();

  // 각 문서에 대한 처리를 병렬적으로 진행
  final futures = snapshot.docs.map((doc) async {
    final data = doc.data() as Map<String, dynamic>;
    data['docId'] = doc.id;
    String downloadUrl = data['downloadUrl'] as String? ?? "";

    try {
      // 비동기적으로 메타데이터 요청
      await FirebaseStorage.instance.refFromURL(downloadUrl).getMetadata();
      return data;
    } catch (e) {
      // 에러 발생 시 삭제 작업도 비동기적으로 처리
      await FirebaseFirestore.instance.collection('files').doc(doc.id).delete();
      print("Storage에 없는 파일 삭제: ${doc.id}");
      return null;
    }
  }).toList();

  // 모든 작업을 병렬적으로 실행한 후 결과 수집
  final results = await Future.wait(futures);

  // null이 아닌 유효한 파일만 반환
  return results
      .where((data) => data != null)
      .cast<Map<String, dynamic>>()
      .toList();
}

/// 기존 이미지 선택 다이얼로그 (그리드 형태 썸네일 및 파일명, 삭제 아이콘 포함)
class ExistingImagesDialog extends StatefulWidget {
  final String folder;
  const ExistingImagesDialog({Key? key, required this.folder})
      : super(key: key);

  @override
  _ExistingImagesDialogState createState() => _ExistingImagesDialogState();
}

class _ExistingImagesDialogState extends State<ExistingImagesDialog> {
  List<Map<String, dynamic>> files = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadFiles();
  }

  Future<void> loadFiles() async {
    // 전달받은 폴더명을 인자로 넘겨줍니다.
    files = await fetchFileListFromFirestore(folder: widget.folder);
    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Container(
        width: 800,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 제목
              Text(
                "기존 이미지 선택",
                style: AppTheme.appbarTitleTextStyle,
              ),
              SizedBox(height: 30),
              // 컨텐츠 (로딩 or 파일 목록)
              loading
                  ? Center(child: CircularProgressIndicator())
                  : files.isEmpty
                      ? Text("저장된 파일이 없습니다.")
                      : Container(
                          width: double.maxFinite,
                          height: 300,
                          child: GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: files.length,
                            itemBuilder: (context, index) {
                              final fileData = files[index];
                              final downloadUrl =
                                  fileData['downloadUrl'] as String? ?? "";
                              final fileName =
                                  fileData['fileName'] as String? ?? "No Name";
                              final docId = fileData['docId'] as String? ?? "";
                              return GestureDetector(
                                onTap: () {
                                  // 파일 선택 시 다이얼로그 종료하고 선택한 URL 반환
                                  Navigator.pop(context, downloadUrl);
                                },
                                child: Stack(
                                  children: [
                                    // 썸네일 이미지
                                    Positioned.fill(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: CachedNetworkImage(
                                          imageUrl: downloadUrl,
                                          fit: BoxFit.contain,
                                          fadeInDuration:
                                              const Duration(milliseconds: 500),
                                          placeholder: (context, url) =>
                                              Image.asset(
                                            'assets/images/loading.gif',
                                            width: 50, // 너비를 100으로 고정
                                            fit: BoxFit
                                                .contain, // placeholderFit 대응
                                          ),
                                          errorWidget: (context, url, error) =>
                                              const Text(
                                            '이미지 로드 실패',
                                            style: AppTheme.textErrorTextStyle,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // 파일명 오버레이 (하단 배경 반투명)
                                    Positioned(
                                      top: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        color: Colors.black54,
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 4, vertical: 2),
                                        child: Text(
                                          fileName,
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    // 삭제 아이콘 (우측 상단)
                                    Positioned(
                                      top: 10,
                                      right: 0,
                                      child: IconButton(
                                        icon: Icon(Icons.delete,
                                            color: Colors.redAccent, size: 18),
                                        onPressed: () async {
                                          // 삭제 확인 다이얼로그
                                          bool? confirm =
                                              await showDialog<bool>(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title: Text("삭제 확인",
                                                    style: AppTheme
                                                        .appbarTitleTextStyle),
                                                content:
                                                    Text("이 파일을 삭제하시겠습니까?"),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, false),
                                                    child: Text("취소"),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, true),
                                                    child: Text("삭제"),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                          if (confirm == true) {
                                            // 로딩 다이얼로그 표시
                                            showDialog(
                                              context: context,
                                              barrierDismissible:
                                                  false, // 사용자가 다이얼로그를 닫지 못하게 함
                                              builder: (context) => Center(
                                                  child:
                                                      CircularProgressIndicator()),
                                            );

                                            // 파일 삭제 및 목록 새로고침
                                            await deleteFile(
                                                context, docId, downloadUrl);
                                            await loadFiles();

                                            // 로딩 다이얼로그 닫기
                                            Navigator.pop(context);
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
              SizedBox(height: 10),
              // 취소 버튼
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: Text("취소"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 기존 이미지 선택: 그리드 다이얼로그 호출
Future<String?> selectExistingImage(BuildContext context,
    {required String folder}) async {
  return await showDialog<String>(
    context: context,
    builder: (context) {
      return ExistingImagesDialog(folder: folder);
    },
  );
}

/// 📌 다이얼로그를 통해 새 이미지 업로드 또는 기존 이미지 선택 제공
Future<String?> showImageSelectionDialog(BuildContext context,
    {required String folder}) async {
  return showDialog<String>(
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
                Text("이미지 선택", style: AppTheme.appbarTitleTextStyle),
                const SizedBox(height: 30),
                Text("새로운 이미지를 선택해 주세요.",
                    style: AppTheme.textCGreyStyle.copyWith(fontSize: 13)),
                const SizedBox(height: 20),
                Wrap(
                  children: [
                    TextButton(
                      onPressed: () async {
                        // List<String>? imageUrls = await UploadImage.uploadNewImage(context, multiple: true, folder: 'uploads/test');
                        // String? url = (await UploadImage.uploadNewImage(
                        //   context,
                        //   multiple: false,
                        //   folder: folder,
                        //   imageQuality: 80,
                        //   targetWidth: 800,
                        // ))
                        // ?.first;

                        List<String>? urls = await UploadImage.uploadNewImage(
                          context,
                          multiple: false,
                          folder: folder,
                        );

                        String? url =
                            urls?.isNotEmpty == true ? urls!.first : null;
                        Navigator.of(context).pop(url);
                      },
                      child: Text("새 이미지 업로드"),
                    ),
                    TextButton(
                      onPressed: () async {
                        String? url =
                            await selectExistingImage(context, folder: folder);
                        Navigator.of(context).pop(url);
                      },
                      child: Text("기존 파일 선택"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(null);
                      },
                      child: Text("취소"),
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
