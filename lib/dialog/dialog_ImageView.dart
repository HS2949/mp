import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mp_db/constants/styles.dart';
import 'package:mp_db/dialog/dialog_ImageFullView.dart';
import 'package:mp_db/dialog/dialog_ImageUpload.dart';
import 'package:mp_db/dialog/dialog_firestorage.dart'; // deleteFile, fetchFileListFromFirestore 등 포함

// 추가적으로 다운로드 관련 패키지 import
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mp_db/utils/widget_help.dart';
import 'package:path/path.dart' as p;

class ImageGridScreen extends StatefulWidget {
  final String folderName;

  ImageGridScreen({required this.folderName});

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

  /// Firestore에서 특정 폴더의 이미지 리스트 가져오기
  Future<void> _fetchImages() async {
    List<Map<String, dynamic>> fileList =
        await fetchFileListFromFirestore(folder: widget.folderName);

    setState(() {
      files = fileList;
      loading = false;
    });
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
    await _fetchImages();
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
        style: AppTheme.appbarTitleTextStyle.copyWith(
            color: AppTheme.text4Color, fontWeight: FontWeight.w600),
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
    return Scaffold(
      appBar: AppBar(
        title: isMultiSelectMode
            ? Text("다중 선택 모드", style: AppTheme.appbarTitleTextStyle)
            : Text.rich(
                TextSpan(
                  children: _buildTitleSpans(formatTitle(widget.folderName)),
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
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(),
                ),
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
                            image: AssetImage('assets/images/miceplan_logo.png'),
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
                              crossAxisCount: MediaQuery.of(context).size.width >
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
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            FullScreenImageViewer(
                                          imageUrls: files
                                              .map((f) =>
                                                  f['downloadUrl'] as String)
                                              .toList(),
                                          initialIndex: index,
                                        ),
                                      ),
                                    );
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
                                          fadeInDuration:
                                              const Duration(milliseconds: 500),
                                          placeholder: (context, url) => Align(
                                            alignment: Alignment.center,
                                            child: Image.asset(
                                              'assets/images/loading.gif',
                                              width: 50,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                          errorWidget: (context, url, error) =>
                                              const Center(
                                            child: Text(
                                              '이미지 로드 실패',
                                              style: AppTheme.textErrorTextStyle,
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
                    folder: widget.folderName,
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
          Text("\n다운로드 진행률: ${_progress.toStringAsFixed(0)}%",style: AppTheme.textLabelStyle),
        ],
      ),
    );
  }
}
