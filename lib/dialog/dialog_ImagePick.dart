// ignore_for_file: public_member_api_docs, sort_constructors_first, deprecated_member_use
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore import
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

import 'package:mp_db/constants/styles.dart';

// 모델 클래스: 선택한 이미지의 정보를 보관
class SelectedImageInfo {
  final XFile imageFile;
  String fileName;
  final int sizeInBytes;
  int width;
  int height;
  int imageQuality;
  final String extension;
  final int originalWidth; // 원본 너비 추가
  final int originalHeight; // 원본 높이 추가
  String originalfilename;
  final double fileSize;

  SelectedImageInfo({
    required this.imageFile,
    required this.fileName,
    required this.sizeInBytes,
    required this.width,
    required this.height,
    required this.imageQuality,
    required this.extension,
    required this.originalWidth,
    required this.originalHeight,
    required this.originalfilename,
    required this.fileSize,
  });
}

// Firestore에서 파일명 중복 확인 및 고유 파일명 생성 함수
Future<void> updateUniqueFileName(SelectedImageInfo imageInfo, String folder,
    List<SelectedImageInfo> images) async {
  // 원본 파일명에서 baseName과 확장자 분리 (예: "중복파일명.jpg" -> baseName: "중복파일명", extension: ".jpg")
  final original = imageInfo.originalfilename;
  final dotIndex = original.lastIndexOf('.');
  final baseName = dotIndex != -1 ? original.substring(0, dotIndex) : original;
  // final baseName = folder.replaceAll('/', '_').replaceAll('uploads_', '');
  final extension = dotIndex != -1 ? original.substring(dotIndex) : '';

  // 1단계: 로컬 images 리스트 내 중복 파일명 검사
  int highestLocalSequence = 0;
  bool localDuplicateFound = false;

  for (var img in images) {
    if (img == imageInfo) continue; // 자기 자신은 제외
    final existingName = img.fileName;
    // 원본과 정확히 동일한 경우
    if (existingName == original) {
      localDuplicateFound = true;
      highestLocalSequence = highestLocalSequence < 1 ? 1 : highestLocalSequence;
    } else {
      // "baseName_###extension" 형식인지 정규표현식으로 확인
      final regex = RegExp('^' +
          RegExp.escape(baseName) +
          r'_(\d{3})' +
          RegExp.escape(extension) +
          r'$');
      final match = regex.firstMatch(existingName);
      if (match != null) {
        localDuplicateFound = true;
        int seq = int.parse(match.group(1)!);
        if (seq > highestLocalSequence) {
          highestLocalSequence = seq;
        }
      }
    }
  }

  String candidateFileName;
  if (localDuplicateFound) {
    final newSequence = (highestLocalSequence + 1).toString().padLeft(3, '0');
    candidateFileName = '${baseName}_$newSequence$extension';
  } else {
    candidateFileName = original;
  }

  // 2단계: Firestore에서 해당 folder 내 파일명 중복 검사
  final firestore = FirebaseFirestore.instance;
  final querySnapshot = await firestore
      .collection('files')
      .where('folder', isEqualTo: folder)
      .get();
      print('데이터 읽기 ');

  int highestFirestoreSequence = 0;
  bool firestoreDuplicateFound = false;

  for (var doc in querySnapshot.docs) {
    final data = doc.data();
    if (!data.containsKey('fileName')) continue;
    final existingFileName = data['fileName'] as String;
    if (existingFileName == candidateFileName) {
      firestoreDuplicateFound = true;
      highestFirestoreSequence = highestFirestoreSequence < 1 ? 1 : highestFirestoreSequence;
    } else {
      final regex = RegExp('^' +
          RegExp.escape(baseName) +
          r'_(\d{3})' +
          RegExp.escape(extension) +
          r'$');
      final match = regex.firstMatch(existingFileName);
      if (match != null) {
        firestoreDuplicateFound = true;
        int seq = int.parse(match.group(1)!);
        if (seq > highestFirestoreSequence) {
          highestFirestoreSequence = seq;
        }
      }
    }
  }

  if (firestoreDuplicateFound) {
    final newSequence = (highestFirestoreSequence + 1).toString().padLeft(3, '0');
    candidateFileName = '${baseName}_$newSequence$extension';
  }

  // 최종적으로 고유한 파일명 설정
  imageInfo.fileName = candidateFileName;
}

// 이미지 파일로부터 정보를 계산하는 헬퍼 함수
Future<SelectedImageInfo> getImageInfo(XFile xfile) async {
  const int maxDimension = 2000; // 기본값 최대 크기 상수 지정
  const double minQuality = 20; // 기본값 최소 품질 값
  const double maxFileSizeMB = 2; // 기본값 최대 파일 크기 (메가가)

  File file = File(xfile.path);
  Uint8List bytes = await file.readAsBytes();
  int sizeInBytes = bytes.length;
  final decodedImage = await decodeImageFromList(bytes);
  int originalWidth = decodedImage.width;
  int originalHeight = decodedImage.height;
  String extension = path.extension(xfile.path);
  String fileName = path.basename(xfile.path);
  double fileSize =
      double.parse((sizeInBytes / 1024 / 1024).toStringAsFixed(2));

  // 품질 계산 (선형 보간)
  double m = (minQuality - 100) / (maxFileSizeMB - 0.5);
  double b = 100 - m * 0.5;
  int imageQuality = fileSize <= 0.5
      ? 100
      : fileSize >= maxFileSizeMB
          ? minQuality.toInt()
          : (m * fileSize + b).round().toInt().clamp(minQuality.toInt(), 100);

  // 리사이징 로직 (최대 크기 maxDimension)
  int width = originalWidth;
  int height = originalHeight;

  if (originalWidth > maxDimension || originalHeight > maxDimension) {
    double scale = maxDimension /
        (originalWidth > originalHeight ? originalWidth : originalHeight);
    width = (originalWidth * scale).round();
    height = (originalHeight * scale).round();
  }

  return SelectedImageInfo(
    imageFile: xfile,
    fileName: fileName,
    sizeInBytes: sizeInBytes,
    width: width,
    height: height,
    imageQuality: imageQuality,
    extension: extension,
    originalWidth: originalWidth,
    originalHeight: originalHeight,
    originalfilename: fileName,
    fileSize: fileSize,
  );
}

// 그리드뷰를 보여주는 위젯 (파일 선택 및 편집 UI)
class SelectedImagesGridView extends StatefulWidget {
  final List<SelectedImageInfo> initialImages;
  final String folder;
  const SelectedImagesGridView({
    Key? key,
    required this.initialImages,
    required this.folder,
  }) : super(key: key);

  @override
  _SelectedImagesGridViewState createState() => _SelectedImagesGridViewState();
}

class _SelectedImagesGridViewState extends State<SelectedImagesGridView> {
  late List<SelectedImageInfo> images;
  final ImagePicker picker = ImagePicker();
  final FocusNode _focusNode = FocusNode(); // FocusNode 선언

  @override
  void initState() {
    super.initState();
    images = List.from(widget.initialImages);
    _addImages();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode); // 포커스 설정
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _addImages() async {
    final List<XFile>? newFiles =
        await picker.pickMultiImage(imageQuality: 100);
    if (newFiles != null && newFiles.isNotEmpty) {
      final newImages = await Future.wait(
        newFiles.map((xfile) async {
          final imageInfo = await getImageInfo(xfile);
          // 추가 시 Firestore에서 중복 파일명 확인 후 고유 파일명 업데이트
          await updateUniqueFileName(imageInfo, widget.folder, images);
          return imageInfo;
        }),
      );
      setState(() {
        images.addAll(newImages);
      });
    }
  }

  void _editImage(int index) async {
    final imageInfo = images[index];
    TextEditingController fileNameController = TextEditingController(
        text: path.basenameWithoutExtension(imageInfo.fileName));
    double imageQuality = imageInfo.imageQuality.toDouble();
    double sizeFactor =
        (imageInfo.width / imageInfo.originalWidth) * 100; // 원본 크기 기준 비율

    // 텍스트 필드에 포커스와 전체 선택을 위한 FocusNode 생성
    FocusNode textFieldFocusNode = FocusNode();
    await showDialog(
      context: context,
      builder: (context) {
        // 다이얼로그 렌더링 후 포커스 요청 및 전체 선택 실행
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!textFieldFocusNode.hasFocus) {
            textFieldFocusNode.requestFocus();
            fileNameController.selection = TextSelection(
              baseOffset: 0,
              extentOffset: fileNameController.text.length,
            );
          }
        });
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("이미지 편집"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: fileNameController,
                          focusNode: textFieldFocusNode,
                          autofocus: true,
                          decoration: InputDecoration(labelText: "파일명"),
                        ),
                      ),
                      Text("${imageInfo.extension}")
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                      "${sizeFactor != 100 ? '변경 후' : '사이즈'} : ${(imageInfo.originalWidth * sizeFactor / 100).toInt()} x ${(imageInfo.originalHeight * sizeFactor / 100).toInt()}",
                      style: TextStyle(
                          color: sizeFactor != 100
                              ? AppTheme.text2Color
                              : Colors.black)),
                  Slider(
                    min: 1,
                    max: 100,
                    divisions: 99,
                    value: sizeFactor,
                    label: "${sizeFactor.toInt()}%",
                    onChanged: (value) {
                      setDialogState(() {
                        sizeFactor = value;
                      });
                    },
                  ),
                  SizedBox(height: 10),
                  Text("품질"),
                  Slider(
                    min: 1,
                    max: 100,
                    divisions: 99,
                    value: imageQuality,
                    label: "${imageQuality.toInt()}%",
                    onChanged: (value) {
                      setDialogState(() {
                        imageQuality = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    textFieldFocusNode.dispose();
                    Navigator.pop(context);
                  },
                  child: Text("취소"),
                ),
                TextButton(
                  onPressed: () async {
                    imageInfo.originalfilename =
                        "${fileNameController.text}${imageInfo.extension}";
                    await updateUniqueFileName(
                        imageInfo, widget.folder, images);
                    setState(() {
                      imageInfo.imageQuality = imageQuality.toInt();
                      imageInfo.width =
                          (imageInfo.originalWidth * sizeFactor / 100).toInt();
                      imageInfo.height =
                          (imageInfo.originalHeight * sizeFactor / 100).toInt();
                    });
                    textFieldFocusNode.dispose();
                    Navigator.pop(context);
                  },
                  child: Text("편집"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _focusNode, // FocusNode 할당
      onKey: (RawKeyEvent event) {
        if (event is RawKeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.of(context).pop(); // Esc 키를 누르면 이전 화면으로 이동
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.buttonlightbackgroundColor,
        appBar: AppBar(
          title: Wrap(
            spacing: 10,
            children: [
              Text(
                "파일 선택기",
                style: AppTheme.appbarTitleTextStyle.copyWith(
                    color: AppTheme.text2Color, fontWeight: FontWeight.w600),
              ),
              Text("추가할 이미지를 선택해주세요", style: AppTheme.appbarTitleTextStyle)
            ],
          ),
          actions: [
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Wrap(
                  spacing: 20,
                  runSpacing: 5,
                  children: [
                    Container(
                      width: 130,
                      height: 36,
                      child: FloatingActionButton.extended(
                        heroTag: null,
                        onPressed: _addImages,
                        label: Text('파일 선택'),
                        icon: Icon(Icons.add_to_photos_outlined),
                      ),
                    ),
                    Container(
                      width: 130,
                      height: 36,
                      child: FloatingActionButton.extended(
                        heroTag: null,
                        backgroundColor: AppTheme.backgroundColor,
                        hoverColor: AppTheme.text3Color.withOpacity(0.1),
                        onPressed: () {
                          Navigator.of(context).pop(images);
                        },
                        label: Text("사진 업로드",
                            style: TextStyle(color: AppTheme.text5Color)),
                        icon: Icon(Icons.cloud_upload,
                            color: AppTheme.text5Color),
                        tooltip: "사진을 업로드 합니다.",
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: LayoutBuilder(builder: (context, constraints) {
          double screenWidth = constraints.maxWidth; // 화면 너비
          return Stack(
            children: [
              Center(
                child: Opacity(
                  opacity: 0.5,
                  child: Container(
                    width: min(screenWidth * 0.5, 300), // 화면 너비의 50%
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(
                            'assets/images/miceplan_font.png'), // 배경 이미지 경로
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount =
                      (constraints.maxWidth / 150).floor().clamp(1, 5);
                  return GridView.builder(
                    padding: EdgeInsets.all(8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      final imageInfo = images[index];
                      return GestureDetector(
                        onLongPress: () async {
                          final action = await showModalBottomSheet<String>(
                            context: context,
                            builder: (BuildContext context) {
                              return Wrap(
                                children: <Widget>[
                                  ListTile(
                                    leading: Icon(Icons.add),
                                    title: Text('추가'),
                                    onTap: () => Navigator.pop(context, 'add'),
                                  ),
                                  ListTile(
                                    leading: Icon(Icons.delete),
                                    title: Text('삭제'),
                                    onTap: () async {
                                      bool? result = await showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Text("제거"),
                                            content: Text("목록에서 제거하시겠습니까?"),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context)
                                                        .pop(false),
                                                child: Text("취소"),
                                              ),
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context)
                                                        .pop(true),
                                                child: Text("제거"),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                      if (result == true) {
                                        Navigator.pop(context, 'delete');
                                      }
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                          if (action == 'delete') {
                            setState(() {
                              images.removeAt(index);
                            });
                          } else if (action == 'add') {
                            await _addImages();
                          }
                        },
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Image.file(
                                File(imageInfo.imageFile.path),
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: IconButton(
                                icon: Icon(Icons.delete,
                                    color: Colors.red, size: 16),
                                padding: EdgeInsets.all(2.0),
                                constraints: BoxConstraints(),
                                onPressed: () async {
                                  bool? confirmDelete = await showDialog<bool>(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: Text("제거"),
                                        content: Text("목록에서 제거하시겠습니까?"),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context)
                                                    .pop(false),
                                            child: Text("취소"),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(true),
                                            child: Text("제거"),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                  if (confirmDelete == true) {
                                    setState(() {
                                      images.removeAt(index);
                                    });
                                  }
                                },
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                color: Colors.black54,
                                padding: const EdgeInsets.all(4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: RichText(
                                        text: TextSpan(
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12),
                                          children: [
                                            TextSpan(
                                              text: '${imageInfo.fileSize} MB - (',
                                            ),
                                            TextSpan(
                                              text: '${imageInfo.width}',
                                              style: TextStyle(
                                                color: (imageInfo.originalWidth != imageInfo.width)
                                                    ? AppTheme.textStrongColor
                                                    : Colors.white,
                                              ),
                                            ),
                                            TextSpan(
                                              text: ' x ',
                                            ),
                                            TextSpan(
                                              text: '${imageInfo.height}',
                                              style: TextStyle(
                                                color: (imageInfo.originalHeight != imageInfo.height)
                                                    ? AppTheme.textStrongColor
                                                    : Colors.white,
                                              ),
                                            ),
                                            TextSpan(
                                              text: ') / ',
                                            ),
                                            TextSpan(
                                              text: '${imageInfo.imageQuality}%',
                                              style: TextStyle(
                                                color: (100 != imageInfo.imageQuality)
                                                    ? AppTheme.textStrongColor
                                                    : Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: RichText(
                                            text: TextSpan(
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12),
                                              children: [
                                                TextSpan(
                                                  text: '${imageInfo.fileName}',
                                                  style: TextStyle(
                                                    color: (imageInfo.fileName != imageInfo.originalfilename)
                                                        ? AppTheme.textStrongColor
                                                        : Colors.white,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: ' (${imageInfo.extension})',
                                                ),
                                              ],
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.edit,
                                              color: AppTheme.textStrongColor,
                                              size: 16),
                                          padding: EdgeInsets.all(2.0),
                                          constraints: BoxConstraints(),
                                          onPressed: () => _editImage(index),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          );
        }),
      ),
    );
  }
}
