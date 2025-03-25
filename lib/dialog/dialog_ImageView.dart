// ignore_for_file: deprecated_member_use

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // compute() 사용을 위해
import 'package:flutter/services.dart';
import 'package:mp_db/constants/styles.dart';
import 'package:mp_db/dialog/dialog_ImageFullView.dart';
import 'package:mp_db/dialog/dialog_ImageUpload.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mp_db/utils/widget_help.dart';
import 'package:path/path.dart' as p;

class ImageGridScreen extends StatefulWidget {
  final List<String> folderName;
  final bool isUrl;

  ImageGridScreen({
    Key? key,
    required this.folderName,
    required this.isUrl,
  }) : super(key: key);

  @override
  _ImageGridScreenState createState() => _ImageGridScreenState();
}

class _ImageGridScreenState extends State<ImageGridScreen> {
  List<Map<String, dynamic>> files = [];
  bool loading = true;

  // 다중 선택 모드 관련 변수
  bool isMultiSelectMode = false;
  Set<String> selectedFiles = {};

  @override
  void initState() {
    super.initState();
    _fetchImages();
  }

  /// Firestore 요청은 Future.wait()와 timeout()을 이용해 각 폴더별 쿼리를 병렬 실행합니다.
  /// (불필요한 필드는 제거하여 fileName, uploadedAt, downloadUrl만 가져옵니다.)
  /// 정렬과 같이 CPU 부담이 있는 부분은 compute()를 사용하여 백그라운드에서 처리합니다.
  Future<void> _fetchImages() async {
    try {
      List<Map<String, dynamic>> fileList = await fetchFileListFromFirestore(
        folders: widget.folderName,
      );
      // 정렬을 별도 isolate에서 처리 (파일 수가 많을 경우 UI 스레드 부담 완화)
      fileList = await compute(_sortFiles, fileList);
      setState(() {
        files = fileList;
      });
    } catch (e) {
      showOverlayMessage(context, "파일 목록 로드 오류: $e");
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  /// 각 폴더별 Firestore 요청을 병렬로 실행하는 함수
  Future<List<Map<String, dynamic>>> fetchFileListFromFirestore({
    List<String>? folders,
  }) async {
    if (folders == null || folders.isEmpty) return [];

    // 각 폴더에 대해 별도의 쿼리 실행 (쿼리당 10초 timeout 적용)
    List<Future<List<Map<String, dynamic>>>> futures =
        folders.map((folder) async {
      Query query = FirebaseFirestore.instance
          .collection('files')
          .where('folder', isEqualTo: folder);
      QuerySnapshot snapshot = await query.get().timeout(Duration(seconds: 10));
      print('데이터 읽기 ');
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['docId'] = doc.id;
        return data;
      }).toList();
    }).toList();

    // 모든 폴더에 대한 쿼리를 병렬 실행하고 10초 timeout 적용
    List<List<Map<String, dynamic>>> results =
        await Future.wait(futures).timeout(Duration(seconds: 10));
    // 여러 폴더의 결과를 하나의 리스트로 병합
    List<Map<String, dynamic>> combinedResults =
        results.expand((x) => x).toList();
    return combinedResults;
  }

  /// 백그라운드 isolate에서 파일 리스트를 정렬 (업로드 시간 내림차순)
  static List<Map<String, dynamic>> _sortFiles(
      List<Map<String, dynamic>> files) {
    files.sort((a, b) {
      DateTime aTime = (a['uploadedAt'] as Timestamp).toDate();
      DateTime bTime = (b['uploadedAt'] as Timestamp).toDate();
      return bTime.compareTo(aTime);
    });
    return files;
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

  /// 다중 선택된 파일들 삭제
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

    // 삭제 진행 상황 다이얼로그 표시 (진행률 없이 단순히 "삭제 중.." 타이틀과 로딩 인디케이터만 표시)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const DeleteProgressDialog(),
    );

    // 선택된 파일들을 병렬 처리하여 삭제 (각 삭제 요청에 timeout 적용 가능)
    List<Future<void>> deletionFutures = selectedFiles.map((docId) async {
      final file = files.firstWhere((element) => element['docId'] == docId);
      try {
        await deleteFile(context, docId, file['downloadUrl'] as String);
      } catch (e) {
        showOverlayMessage(context, "파일 삭제 중 오류가 발생했습니다: $e");
      }
    }).toList();

    try {
      await Future.wait(deletionFutures).timeout(Duration(seconds: 10));
    } catch (e) {
      showOverlayMessage(context, "삭제 작업에 시간이 초과되었습니다: $e");
    }

    // 삭제 진행 다이얼로그 닫기
    Navigator.of(context).pop();

    setState(() {
      selectedFiles.clear();
      isMultiSelectMode = false;
    });
    await _fetchImages();
  }

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

  /// 다중 선택된 파일들을 한 번에 다운로드
  Future<void> _downloadSelectedFiles() async {
    if (selectedFiles.isEmpty) return;

    // 선택한 파일들을 모음
    List<Map<String, dynamic>> filesToDownload = [];
    for (String docId in selectedFiles) {
      final file = files.firstWhere((element) => element['docId'] == docId);
      filesToDownload.add(file);
    }

    // 다운로드할 파일 목록을 리스트로 보여주고 확인
    bool confirm = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("다운로드 확인", style: AppTheme.appbarTitleTextStyle),
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
      isMultiSelectMode = false;
      selectedFiles.clear();
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

  String formatTitle(String folderName) {
    String path = folderName.replaceFirst('uploads/', '');
    List<String> parts = path.split('/');
    if (parts.length == 1) {
      return "${parts[0]}";
    } else if (parts.length >= 2) {
      return " ${parts[0]} - ${parts[1]}";
    }
    return "";
  }

  List<TextSpan> _buildTitleSpans(String title) {
    List<TextSpan> spans = [];
    spans.add(TextSpan(
      text: "Photo :",
      style: AppTheme.appbarTitleTextStyle,
    ));
    if (title.contains(" - ")) {
      List<String> parts = title.split(" - ");
      spans.add(TextSpan(
        text: " ${parts[0]}",
        style: AppTheme.appbarTitleTextStyle
            .copyWith(color: AppTheme.text2Color, fontSize: 14),
      ));
      spans.add(TextSpan(
        text: "  ${parts[1]}",
        style: AppTheme.appbarTitleTextStyle
            .copyWith(color: AppTheme.text4Color, fontWeight: FontWeight.w600),
      ));
    } else {
      spans.add(TextSpan(
        text: " ${title.replaceFirst("Photo :", "").trim()}",
        style: AppTheme.appbarTitleTextStyle
            .copyWith(color: AppTheme.text2Color, fontSize: 14),
      ));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKey: (event) {
        if (event is RawKeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: isMultiSelectMode
              ? Text("다중 선택 모드", style: AppTheme.appbarTitleTextStyle)
              : Text.rich(
                  TextSpan(
                    children:
                        _buildTitleSpans(formatTitle(widget.folderName[0])),
                    style: AppTheme.appbarTitleTextStyle,
                  ),
                ),
          actions: isMultiSelectMode
              ? [
                  IconButton(
                    icon: Icon(Icons.download),
                    tooltip: "선택한 파일 다운로드",
                    onPressed: _downloadSelectedFiles,
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    tooltip: "선택한 파일 삭제",
                    onPressed: _deleteSelectedFiles,
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    tooltip: "선택 모드 취소",
                    onPressed: () {
                      setState(() {
                        isMultiSelectMode = false;
                        selectedFiles.clear();
                      });
                    },
                  ),
                ]
              : null,
        ),
        body: LayoutBuilder(builder: (context, constraints) {
          double screenWidth = constraints.maxWidth;
          double screenHeight = constraints.maxHeight;
          return loading
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : Stack(
                  children: [
                    Center(
                      child: Opacity(
                        opacity: 0.1,
                        child: Container(
                          width: screenWidth * 0.8,
                          height: screenHeight * 0.5,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image:
                                  AssetImage('assets/images/miceplan_logo.png'),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                    files.isEmpty
                        ? Center(
                            child: Text(
                            "저장된 파일이 없습니다.",
                            style: AppTheme.bodySmallTextStyle
                                .copyWith(color: AppTheme.text4Color),
                          ))
                        : Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: GridView.builder(
                              itemCount: files.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount:
                                    MediaQuery.of(context).size.width >
                                            narrowScreenWidthThreshold
                                        ? 5
                                        : 2,
                                crossAxisSpacing: 4.0,
                                mainAxisSpacing: 4.0,
                              ),
                              itemBuilder: (context, index) {
                                final fileData = files[index];
                                final downloadUrl =
                                    fileData['downloadUrl'] as String? ?? "";
                                final fileName =
                                    fileData['fileName'] as String? ?? "";
                                final docId =
                                    fileData['docId'] as String? ?? "";
                                bool isSelected = selectedFiles.contains(docId);

                                return GestureDetector(
                                  onTap: () {
                                    if (isMultiSelectMode) {
                                      _toggleSelection(docId);
                                    } else {
                                      if (!widget.isUrl) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                FullScreenImageViewer(
                                              imageUrls: files
                                                  .map((f) => f['downloadUrl']
                                                      as String)
                                                  .toList(),
                                              initialIndex: index,
                                            ),
                                          ),
                                        );
                                      } else {
                                        Navigator.pop(context, downloadUrl);
                                      }
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
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          child: CachedNetworkImage(
                                            imageUrl: downloadUrl,
                                            fit: BoxFit.contain,
                                            fadeInDuration: const Duration(
                                                milliseconds: 500),
                                            placeholder: (context, url) =>
                                                Align(
                                              alignment: Alignment.center,
                                              child: Image.asset(
                                                'assets/images/loading.gif',
                                                width: 50,
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    const Center(
                                              child: Text(
                                                '이미지 로드 실패',
                                                style:
                                                    AppTheme.textErrorTextStyle,
                                              ),
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
                                              fontSize: 10,
                                            ),
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
                  ],
                );
        }),
        floatingActionButton: isMultiSelectMode
            ? null
            : Container(
                width: 150,
                height: 50,
                child: FloatingActionButton.extended(
                  heroTag: null,
                  onPressed: () async {
                    setState(() {
                      loading = true;
                    });
                    List<String>? imageUrls = await UploadImage.uploadNewImage(
                      context,
                      multiple: true,
                      folder: widget.folderName[0],
                    );
                    if (imageUrls != null && imageUrls.isNotEmpty) {
                      await _fetchImages();
                    }
                    setState(() {
                      loading = false;
                    });
                  },
                  icon: Icon(Icons.attach_file),
                  label: Text('이미지 추가'),
                  tooltip: '이미지를 추가합니다.',
                ),
              ),
      ),
    );
  }
}

/// 삭제 진행 상황을 표시하는 다이얼로그 위젯 (진행률 표시 없이 단순 "삭제 중.." 타이틀)
class DeleteProgressDialog extends StatelessWidget {
  const DeleteProgressDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        "삭제 중..",
        style: AppTheme.appbarTitleTextStyle,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 진행률 대신 단순 로딩 인디케이터만 표시
          CircularProgressIndicator(),
        ],
      ),
    );
  }
}

/// 다운로드 진행 상황을 표시하는 다이얼로그 위젯 (Top-level)
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
          Text("\n다운로드 진행률: ${_progress.toStringAsFixed(0)}%",
              style: AppTheme.textLabelStyle),
        ],
      ),
    );
  }
}
