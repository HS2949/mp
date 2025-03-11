import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:mp_db/constants/styles.dart';
import 'package:mp_db/dialog/dialog_ImageUpload.dart';
import 'package:mp_db/dialog/dialog_ImageView.dart';
import 'package:mp_db/utils/widget_help.dart';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

/// 파일 삭제 함수: Storage와 Firestore에서 모두 삭제
Future<void> deleteFile(
    BuildContext context, String docId, String downloadUrl) async {
  try {
    Reference storageRef = FirebaseStorage.instance.refFromURL(downloadUrl);
    await storageRef.delete();
    await FirebaseFirestore.instance.collection('files').doc(docId).delete();
    showOverlayMessage(context, '이미지를 삭제하였습니다');
  } catch (e) {
    showOverlayMessage(context, '이미지 삭제 오류');
    print("삭제 실패: $e");
  }
}

/// Firestore에서 파일 목록을 조회 (문서 ID 포함)
Future<List<Map<String, dynamic>>> fetchFileListFromFirestore({
  String? folder,
}) async {
  Query query = FirebaseFirestore.instance.collection('files');
  if (folder != null && folder.isNotEmpty) {
    query = query.where('folder', isEqualTo: folder);
  }
  query = query.orderBy('uploadedAt', descending: true);
  QuerySnapshot snapshot = await query.get();

  final futures = snapshot.docs.map((doc) async {
    final data = doc.data() as Map<String, dynamic>;
    data['docId'] = doc.id;
    String downloadUrl = data['downloadUrl'] as String? ?? "";
    try {
      await FirebaseStorage.instance.refFromURL(downloadUrl).getMetadata();
      return data;
    } catch (e) {
      await FirebaseFirestore.instance.collection('files').doc(doc.id).delete();
      print("Storage에 없는 파일 삭제: ${doc.id}");
      return null;
    }
  }).toList();

  final results = await Future.wait(futures);
  return results
      .where((data) => data != null)
      .cast<Map<String, dynamic>>()
      .toList();
}

/// 다운로드 진행 상황을 표시하는 다이얼로그 (Top-level)
class DownloadProgressDialog extends StatefulWidget {
  final String fileName;
  final int currentFile;
  final int totalFiles;

  const DownloadProgressDialog({
    Key? key,
    required this.fileName,
    required this.currentFile,
    required this.totalFiles,
  }) : super(key: key);

  @override
  DownloadProgressDialogState createState() => DownloadProgressDialogState();
}

class DownloadProgressDialogState extends State<DownloadProgressDialog> {
  double _progress = 0;
  void updateProgress(double progress) {
    setState(() {
      _progress = progress;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("다운로드 중.."),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.fileName),
          Text("(${widget.currentFile}/${widget.totalFiles})"),
          Text("\n다운로드 진행률: ${_progress.toStringAsFixed(0)}%",style: AppTheme.textLabelStyle),
        ],
      ),
    );
  }
}

/// 기존 이미지 선택 다이얼로그 (그리드 형태)
class ExistingImagesDialog extends StatefulWidget {
  final String folder;
  final List<String> addFolder; // 추가된 폴더

  const ExistingImagesDialog({
    Key? key,
    required this.folder,
    required this.addFolder,
  }) : super(key: key);

  @override
  _ExistingImagesDialogState createState() => _ExistingImagesDialogState();
}

class _ExistingImagesDialogState extends State<ExistingImagesDialog> {
  List<Map<String, dynamic>> files = [];
  bool loading = true;
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
      List<Map<String, dynamic>> filesFromMainFolder =
          await fetchFileListFromFirestore(folder: widget.folder);
      List<Map<String, dynamic>> filesFromAddFolders = [];
      for (String aFolder in widget.addFolder) {
        List<Map<String, dynamic>> filesFromFolder =
            await fetchFileListFromFirestore(folder: aFolder);
        filesFromAddFolders.addAll(filesFromFolder);
      }
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

  void _enterMultiSelectMode(String docId) {
    setState(() {
      isMultiSelectMode = true;
      selectedFiles.add(docId);
    });
  }

  void _toggleSelection(String docId) {
    setState(() {
      if (selectedFiles.contains(docId)) {
        selectedFiles.remove(docId);
      } else {
        selectedFiles.add(docId);
      }
      if (selectedFiles.isEmpty) isMultiSelectMode = false;
    });
  }

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
                child: Text("취소")),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text("삭제")),
          ],
        );
      },
    );
    if (confirm != true) return;

    for (String docId in selectedFiles) {
      final file = files.firstWhere((element) => element['docId'] == docId);
      try {
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

  /// 여러 파일을 한 번에 다운로드하는 함수
  Future<void> _downloadSelectedFiles() async {
    if (selectedFiles.isEmpty) return;

    // 선택한 파일들을 가져옴
    List<Map<String, dynamic>> filesToDownload = [];
    for (String docId in selectedFiles) {
      final file = files.firstWhere((element) => element['docId'] == docId);
      filesToDownload.add(file);
    }

    // 파일 목록을 다이얼로그로 보여주고 일괄 다운로드 확인
    bool confirm = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(
                "다운로드 확인",
                style: AppTheme.appbarTitleTextStyle,
              ),
              content: Container(
                width: double.minPositive,
                child: ListView(
                  shrinkWrap: true,
                  children: filesToDownload
                      .map((file) =>
                          Text(file['fileName'] as String? ?? "No Name"))
                      .toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text("취소"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text("다운로드"),
                ),
              ],
            );
          },
        ) ??
        false;
    if (!confirm) return;

    // 한 번의 폴더 선택 (모든 파일 동일 폴더에 다운로드)
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '다운로드할 폴더 선택',
    );
    if (selectedDirectory == null) {
      showOverlayMessage(context, "폴더 선택이 취소되었습니다.");
      return;
    }

    int totalFiles = filesToDownload.length;
    // 각 파일을 순차적으로 다운로드
    for (int i = 0; i < totalFiles; i++) {
      final file = filesToDownload[i];
      final downloadUrl = file['downloadUrl'] as String;
      final fileName = file['fileName'] as String;
      String savePath = p.join(selectedDirectory, fileName);
      await _downloadFileWithProgress(
          context, downloadUrl, fileName, i + 1, totalFiles, savePath);
    }
    setState(() {
      // selectedFiles.clear();
      isMultiSelectMode = false;
    });
    showOverlayMessage(context, "선택한 파일 다운로드가 완료되었습니다.");
  }

  /// 단일 파일 다운로드 (진행 상황 다이얼로그 포함)
  Future<void> _downloadFileWithProgress(
    BuildContext context,
    String url,
    String fileName,
    int currentFile,
    int totalFiles,
    String savePath,
  ) async {
    final GlobalKey<DownloadProgressDialogState> progressKey =
        GlobalKey<DownloadProgressDialogState>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return DownloadProgressDialog(
          key: progressKey,
          fileName: fileName,
          currentFile: currentFile,
          totalFiles: totalFiles,
        );
      },
    );

    try {
      await Dio().download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            double progress = received / total * 100;
            progressKey.currentState?.updateProgress(progress);
          }
        },
      );
      Navigator.of(context).pop(); // 진행 다이얼로그 닫기
    } catch (e) {
      Navigator.of(context).pop();
      showOverlayMessage(context, "다운로드 에러: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                                    if (isMultiSelectMode)
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: Icon(
                                          isSelected
                                              ? Icons.check_circle
                                              : Icons.radio_button_unchecked,
                                          color: isSelected
                                              ? AppTheme.text9Color
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

/// 기존 이미지 선택 다이얼로그 호출
Future<String?> selectExistingImage(BuildContext context,
    {required String folder, required List<String> addFolder}) async {
  return await showDialog<String>(
    context: context,
    builder: (context) {
      return ExistingImagesDialog(folder: folder, addFolder: addFolder);
    },
  );
}

/// 새 이미지 업로드 또는 기존 이미지 선택 다이얼로그
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
