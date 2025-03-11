import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// MIME 타입을 자동으로 감지하는 라이브러리
// 로그인 필요시 사용
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:mp_db/constants/styles.dart';
import 'package:mp_db/dialog/dialog_ImageUpload.dart';
import 'package:mp_db/dialog/dialog_ImageView.dart';
import 'package:mp_db/utils/widget_help.dart';
import 'package:url_launcher/url_launcher.dart';

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

//// 기존 이미지 선택 다이얼로그 (그리드 형태 썸네일 및 파일명, 삭제 아이콘 포함)
class ExistingImagesDialog extends StatefulWidget {
  final String folder;
  final List<String> addFolder; // 추가된 폴더

  const ExistingImagesDialog({
    Key? key,
    required this.folder,
    required this.addFolder, // 새로운 폴더 인수 추가
  }) : super(key: key);

  @override
  _ExistingImagesDialogState createState() => _ExistingImagesDialogState();
}

class _ExistingImagesDialogState extends State<ExistingImagesDialog> {
  List<Map<String, dynamic>> files = [];
  bool loading = true;

  // 다중 선택 관련 상태 변수
  bool isMultiSelectMode = false;
  Set<String> selectedFiles = {};

  @override
  void initState() {
    super.initState();
    loadFiles();
  }

  Future<void> loadFiles() async {
    setState(() {
      loading = true;
    });

    try {
      // 기본 폴더에서 파일 리스트 가져오기
      List<Map<String, dynamic>> filesFromMainFolder =
          await fetchFileListFromFirestore(folder: widget.folder);

      List<Map<String, dynamic>> filesFromAddFolders = [];

      // 추가 폴더 리스트에서 모든 파일 가져오기
      for (String aFolder in widget.addFolder) {
        List<Map<String, dynamic>> filesFromFolder =
            await fetchFileListFromFirestore(folder: aFolder);
        filesFromAddFolders.addAll(filesFromFolder);
      }

      // 파일 리스트 병합 후 정렬
      files = [...filesFromMainFolder, ...filesFromAddFolders];
      files.sort((a, b) => b['uploadedAt'].compareTo(a['uploadedAt']));
    } catch (e) {
      showOverlayMessage(context, "파일 로드 중 오류가 발생했습니다: $e");
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  // 다중 선택 모드 진입
  void _enterMultiSelectMode(String docId) {
    setState(() {
      isMultiSelectMode = true;
      selectedFiles.add(docId);
    });
  }

  // 선택 토글
  void _toggleSelection(String docId) {
    setState(() {
      if (selectedFiles.contains(docId)) {
        selectedFiles.remove(docId);
      } else {
        selectedFiles.add(docId);
      }
      if (selectedFiles.isEmpty) {
        isMultiSelectMode = false;
      }
    });
  }

  // 선택된 파일들 삭제
  Future<void> _deleteSelectedFiles() async {
    if (selectedFiles.isEmpty) return;

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("삭제 확인", style: AppTheme.appbarTitleTextStyle),
          content: Text("${selectedFiles.length}개의 파일을 삭제하시겠습니까?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("취소"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text("삭제"),
            ),
          ],
        );
      },
    );
    if (confirm != true) return;

    for (String docId in selectedFiles) {
      final file = files.firstWhere((element) => element['docId'] == docId);
      try {
        // deleteFile() 함수는 Firestore와 Storage에서 파일을 삭제합니다.
        await deleteFile(context, docId, file['downloadUrl'] as String);
      } catch (e) {
        showOverlayMessage(context, "파일 삭제 중 오류가 발생했습니다: $e");
      }
    }
    setState(() {
      selectedFiles.clear();
      isMultiSelectMode = false;
    });
    await loadFiles();
  }

  // 선택된 파일들 다운로드
  Future<void> _downloadSelectedFiles() async {
    if (selectedFiles.isEmpty) return;

    for (String docId in selectedFiles) {
      final file = files.firstWhere((element) => element['docId'] == docId);
      final downloadUrl = file['downloadUrl'] as String;
      final uri = Uri.parse(downloadUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        showOverlayMessage(context, "${file['fileName']} 다운로드 실패");
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("선택한 파일 다운로드가 완료되었습니다.")),
    );
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
              // 제목 및 다중 선택 모드 액션 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isMultiSelectMode ? "다중 선택 모드" : "기존 이미지 선택",
                    style: AppTheme.appbarTitleTextStyle,
                  ),
                  if (isMultiSelectMode)
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.download),
                          onPressed: _downloadSelectedFiles,
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: _deleteSelectedFiles,
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              isMultiSelectMode = false;
                              selectedFiles.clear();
                            });
                          },
                        ),
                      ],
                    ),
                ],
              ),
              SizedBox(height: 30),
              // 컨텐츠 (로딩 or 파일 목록)
              loading
                  ? Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(),
                      ),
                    )
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

                              final bool isSelected =
                                  selectedFiles.contains(docId);

                              return GestureDetector(
                                onTap: () {
                                  if (isMultiSelectMode) {
                                    _toggleSelection(docId);
                                  } else {
                                    // 파일 선택 시 다이얼로그 종료하고 선택한 URL 반환
                                    Navigator.pop(context, downloadUrl);
                                  }
                                },
                                onLongPress: () {
                                  if (!isMultiSelectMode) {
                                    _enterMultiSelectMode(docId);
                                  }
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
                                            width: 50,
                                            fit: BoxFit.contain,
                                          ),
                                          errorWidget: (context, url, error) =>
                                              const Text(
                                            '이미지 로드 실패',
                                            style: AppTheme.textErrorTextStyle,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // 파일명 오버레이 (상단 배경 반투명)
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
                                    // 다중 선택 모드가 아닐 경우 삭제 아이콘 (우측 상단)
                                    if (!isMultiSelectMode)
                                      Positioned(
                                        top: 10,
                                        right: 0,
                                        child: IconButton(
                                          icon: Icon(Icons.delete,
                                              color: Colors.redAccent,
                                              size: 18),
                                          onPressed: () async {
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
                                              try {
                                                await deleteFile(context, docId,
                                                    downloadUrl);
                                                await loadFiles();
                                              } catch (e) {
                                                showOverlayMessage(context,
                                                    "파일 삭제 중 오류가 발생했습니다: $e");
                                              }
                                            }
                                          },
                                        ),
                                      ),
                                    // 다중 선택 모드인 경우 선택 표시 (우측 상단)
                                    if (isMultiSelectMode)
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: Icon(
                                          isSelected
                                              ? Icons.check_circle
                                              : Icons.radio_button_unchecked,
                                          color: isSelected
                                              ? Colors.blue
                                              : Colors.white,
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
              SizedBox(height: 10),
              // 취소 버튼 (다중 선택 모드가 아닐 때만 표시)
              if (!isMultiSelectMode)
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
    {required String folder, required List<String> addFolder}) async {
  return await showDialog<String>(
    context: context,
    builder: (context) {
      return ExistingImagesDialog(folder: folder, addFolder: addFolder);
    },
  );
}

/// 📌 다이얼로그를 통해 새 이미지 업로드 또는 기존 이미지 선택 제공
Future<String?> showImageSelectionDialog(BuildContext context,
    {required String folder, required List<String> addFolder}) async {
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
                        List<String>? urls = await UploadImage.uploadNewImage(
                          context,
                          multiple: false,
                          folder: folder,
                        );

                        String? url =
                            urls?.isNotEmpty == true ? urls!.first : null;
                        Navigator.of(context).pop(url);
                      },
                      child: Text("새 이미지"),
                    ),
                    Tooltip(
                      message: '길게 누르기 : 파일 편집 모드',
                      child: TextButton(
                        onPressed: () async {
                          String? url = await selectExistingImage(context,
                              folder: folder, addFolder: addFolder);
                          Navigator.of(context).pop(url);
                        },
                        onLongPress: () {
                          //창림
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ImageGridScreen(folderName: folder),
                            ),
                          );
                        },
                        child: Text("기존 파일 선택"),
                      ),
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
