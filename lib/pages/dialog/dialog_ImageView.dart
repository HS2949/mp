import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mp_db/constants/styles.dart';
import 'package:mp_db/pages/dialog/dialog_ImageFullView.dart';
import 'package:mp_db/pages/dialog/dialog_ImageUpload.dart';
import 'package:mp_db/pages/dialog/dialog_firestorage.dart';

class ImageGridScreen extends StatefulWidget {
  final String folderName;

  ImageGridScreen({required this.folderName});

  @override
  _ImageGridScreenState createState() => _ImageGridScreenState();
}

class _ImageGridScreenState extends State<ImageGridScreen> {
  List<Map<String, dynamic>> files = [];
  bool loading = true;
  final FocusNode _focusNode = FocusNode(); // FocusNode 선언

  @override
  void initState() {
    super.initState();
    _fetchImages();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode); // 포커스 설정
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
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

  String formatTitle(String folderName) {
    // 'uploads/' 제거
    String path = folderName.replaceFirst('uploads/', '');

    // '/' 기준으로 폴더 구조를 분리
    List<String> parts = path.split('/');

    if (parts.length == 1) {
      // 중분류만 있을 경우 → "{중분류} 사진"
      return "${parts[0]}";
    } else if (parts.length >= 2) {
      // 중분류 + 소분류 있을 경우 → "{중분류} 사진 : {소분류}"
      return " ${parts[0]} - ${parts[1]}";
    }

    return ""; // 예외 처리
  }

  List<TextSpan> _buildTitleSpans(String title) {
    List<TextSpan> spans = [];

    // "Photo :" 부분을 기본 색상으로 설정
    spans.add(TextSpan(
      text: "Photo :",
      style: AppTheme.appbarTitleTextStyle,
    ));

    if (title.contains(" - ")) {
      // 중분류와 소분류가 있는 경우 ("Photo : 중분류 - 소분류")
      List<String> parts = title.split(" - ");
      spans.add(TextSpan(
        text: " ${parts[0]}", // 중분류
        style: AppTheme.appbarTitleTextStyle
            .copyWith(color: AppTheme.text2Color, fontSize: 14), // 원하는 색상 적용
      ));
      spans.add(TextSpan(
        text: "  ${parts[1]}", // 소분류
        style: AppTheme.appbarTitleTextStyle.copyWith(
            color: AppTheme.text4Color,
            fontWeight: FontWeight.w600), // 원하는 색상 적용
      ));
    } else {
      // 중분류만 있는 경우 ("Photo : 중분류 사진")
      spans.add(TextSpan(
        text: " ${title.replaceFirst("Photo :", "").trim()}", // 중분류
        style: AppTheme.appbarTitleTextStyle
            .copyWith(color: AppTheme.text2Color, fontSize: 14), // 원하는 색상 적용
      ));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode, // FocusNode 할당
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.of(context).pop(); // Esc 키를 누르면 이전 화면으로 이동
        }
      },

      child: Scaffold(
        appBar: AppBar(
          title: Text.rich(
            TextSpan(
              children: _buildTitleSpans(formatTitle(widget.folderName)),
              style: AppTheme.appbarTitleTextStyle,
            ),
          ),
        ),
        body: LayoutBuilder(builder: (context, constraints) {
          double screenWidth = constraints.maxWidth; // 화면 너비
          double screenHeight = constraints.maxHeight; // 화면 높이
          return loading
              ? Center(child: CircularProgressIndicator()) // 데이터 로딩 중
              : Stack(
                  children: [
                    Center(
                      child: Opacity(
                        opacity: 0.1,
                        child: Container(
                            width: screenWidth * 0.8, // 화면 너비의 50%
                            height: screenHeight * 0.5, // 화면 높이의 30%
                            decoration: BoxDecoration(
                                image: DecorationImage(
                              image: AssetImage(
                                  'assets/images/miceplan_logo.png'), // 배경 이미지 경로
                              fit: BoxFit.contain, // 화면 전체 채우기
                            ))),
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

                                return GestureDetector(
                                  onTap: () {
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
                                  },
                                  child: Stack(
                                    children: [
                                      // 썸네일 이미지
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
                                              alignment:
                                                  Alignment.center, // 중앙 정렬
                                              child: Image.asset(
                                                'assets/images/loading.gif',
                                                width: 50, // 너비 고정
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
                                              fontSize: 10,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      // 삭제 아이콘 (우측 상단)
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: IconButton(
                                          icon: Icon(Icons.delete,
                                              color: Colors.redAccent,
                                              size: 18),
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
                                              await _fetchImages();

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
                  ],
                );
        }),
        floatingActionButton: Container(
          width: 150,
          height: 50,
          child: FloatingActionButton.extended(
            heroTag: null,
            onPressed: () async {
              // 업로드 시작 전 로딩 상태로 변경 및 로딩 다이얼로그 표시 (옵션)
              setState(() {
                loading = true;
              });

              // 이미지 업로드
              List<String>? imageUrls = await UploadImage.uploadNewImage(
                context,
                multiple: true,
                folder: widget.folderName,
              );

              // 업로드 후 이미지 목록 즉시 새로고침
              if (imageUrls != null && imageUrls.isNotEmpty) {
                await _fetchImages();
              }
              // 로딩 상태 해제
              setState(() {
                loading = false;
              });
            },
            icon: Icon(
              Icons.attach_file,
            ),
            label: Text('이미지 추가'),
            tooltip: '이미지를 추가합니다.',
          ),
        ),
      ),
    );
  }
}
