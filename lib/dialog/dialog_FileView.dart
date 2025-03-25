import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 클립보드 사용을 위해 추가
import 'package:intl/intl.dart';
import 'package:mp_db/constants/styles.dart';
import 'package:mp_db/dialog/dialog_ImageUpload.dart';
import 'package:mp_db/utils/fileViewer.dart';
import 'package:mp_db/utils/widget_help.dart';
import 'package:url_launcher/url_launcher.dart'; // URL 실행을 위해 추가

class FileListScreen extends StatefulWidget {
  // 예: 'uploads/{itemData.itemName}/files'
  final String folderName;
  const FileListScreen({Key? key, required this.folderName}) : super(key: key);

  @override
  _FileListScreenState createState() => _FileListScreenState();
}

class _FileListScreenState extends State<FileListScreen> {
  List<Map<String, dynamic>> files = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchFiles();
  }

  /// Firestore에서 파일 목록을 불러옵니다.
  Future<void> _fetchFiles() async {
    List<Map<String, dynamic>> fileList =
        await fetchFileListFromFirestore(folder: widget.folderName);

    setState(() {
      files = fileList;
      loading = false;
    });
  }

  /// 파일 업로드: file_picker로 파일 선택 후, Firebase Storage에 업로드하고
  /// Firestore에 파일 메타데이터(파일명, 다운로드 URL, 파일 용량 등)를 저장합니다.
  Future<void> _uploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.single.path == null) return;

    File file = File(result.files.single.path!);
    String fileName = result.files.single.name;

    // 로딩 다이얼로그 표시
    showProgressDialog(context, "$fileName 업로드 중...");

    try {
      // Firebase Storage 업로드
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('${widget.folderName}/$fileName');
      UploadTask uploadTask = storageRef.putFile(file);
      TaskSnapshot snapshot = await uploadTask;

      // 업로드된 파일의 다운로드 URL과 메타데이터 획득
      String downloadUrl = await snapshot.ref.getDownloadURL();
      FullMetadata metadata = await snapshot.ref.getMetadata();
      int fileSize = metadata.size ?? 0;

      // Firestore에 파일 메타데이터 저장
      await addFileToFirestore(
        folder: widget.folderName,
        fileName: fileName,
        downloadUrl: downloadUrl,
        fileSize: fileSize,
      );

      await _fetchFiles();
    } catch (e) {
      print("파일 업로드 실패: $e");
      showOverlayMessage(context, "파일 업로드 중 오류 발생");
    } finally {
      // 로딩 다이얼로그 닫기
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  /// 파일 삭제: 사용자가 확인하면 Storage와 Firestore에서 해당 파일을 삭제합니다.
  Future<void> _deleteFile(String docId, String downloadUrl) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("삭제 확인", style: AppTheme.appbarTitleTextStyle),
          content: Text("이 파일을 삭제하시겠습니까?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("취소", style: AppTheme.bodySmallTextStyle),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text("삭제", style: AppTheme.bodySmallTextStyle),
            ),
          ],
        );
      },
    );
    if (confirm != true) return;

    await deleteFile(docId, downloadUrl);
    await _fetchFiles();
    showOverlayMessage(context, "파일을 삭제하였습니다.");
  }

  /// 파일 항목 길게 누름 시 나타나는 옵션 메뉴 (다운로드, URL 복사)
  void _showOptions(String docId, String downloadUrl) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.download),
                title: Text("다운로드"),
                onTap: () async {
                  Navigator.pop(context);
                  final uri = Uri.parse(downloadUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  } else {
                    showOverlayMessage(context, "URL을 열 수 없습니다.");
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.copy),
                title: Text("주소 복사"),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: downloadUrl));
                  showOverlayMessage(context, "URL이 복사되었습니다.");
                },
              ),
              ListTile(
                leading: Icon(Icons.delete), // 아이콘도 delete로 변경
                title: Text("파일 삭제"),
                onTap: () {
                  Navigator.pop(context); // 시트를 닫고
                  _deleteFile(docId, downloadUrl);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("파일 목록", style: AppTheme.appbarTitleTextStyle),
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        double screenWidth = constraints.maxWidth; // 화면 너비
        double screenHeight = constraints.maxHeight; // 화면 높이
        return loading
            ? Align(
                alignment: Alignment.center,
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
                          ))),
                    ),
                  ),
                  files.isEmpty
                      ? Center(
                          child: Text(
                            "저장된 파일이 없습니다.",
                            style: AppTheme.bodySmallTextStyle
                                .copyWith(color: AppTheme.text4Color),
                          ),
                        )
                      : ListView.builder(
                          itemCount: files.length,
                          itemBuilder: (context, index) {
                            final fileData = files[index];
                            final fileName =
                                fileData['fileName'] as String? ?? '';
                            final downloadUrl =
                                fileData['downloadUrl'] as String? ?? '';
                            final docId = fileData['docId'] as String? ?? '';
                            final uploadedAt = fileData['uploadedAt'] != null
                                ? (fileData['uploadedAt'] as Timestamp).toDate()
                                : DateTime.now();
                            final fileSize = fileData['fileSize'] ?? 0;
                            return ListTile(
                              onTap: () {
                                if (fileName.toLowerCase().endsWith('.pdf')) {
                                  // PDF 뷰어 페이지로 이동
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          PDFViewerPage(url: downloadUrl),
                                    ),
                                  );
                                } else {
                                  // 다른 파일 형식은 기존 동작 또는 다른 처리 방식
                                  // 예를 들어 다운로드 처리 등
                                }
                              },
                              // 리스트 항목 길게 누르면 옵션 메뉴 표시
                              onLongPress: () =>
                                  _showOptions(docId, downloadUrl),
                              leading: Icon(fileName.contains('.pdf')
                                  ? Icons.picture_as_pdf_outlined
                                  : Icons.insert_drive_file),
                              title: Text(fileName),
                              subtitle: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text:
                                          "업로드 날짜: ${DateFormat('yy.MM.dd a hh:mm').format(uploadedAt.toLocal())}\n",
                                      style: AppTheme.textHintTextStyle
                                          .copyWith(fontSize: 14),
                                    ),
                                    TextSpan(
                                      text:
                                          "크기: ${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB",
                                      style: AppTheme.textLabelStyle
                                          .copyWith(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                              // trailing: IconButton(
                              //   icon:
                              //       Icon(Icons.delete, color: Colors.redAccent),
                              //   onPressed: () =>
                              //       _deleteFile(docId, downloadUrl),
                              // ),
                            );
                          },
                        ),
                ],
              );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uploadFile,
        icon: Icon(Icons.attach_file),
        label: Text('파일 추가'),
      ),
    );
  }
}

/// Firestore의 'files' 컬렉션에 파일 메타데이터를 저장합니다.
/// 파일 용량(fileSize)은 바이트 단위로 저장합니다.
Future<void> addFileToFirestore({
  required String folder,
  required String fileName,
  required String downloadUrl,
  required int fileSize,
}) async {
  final CollectionReference filesCollection =
      FirebaseFirestore.instance.collection('files');

  await filesCollection.add({
    'fileName': fileName,
    'downloadUrl': downloadUrl,
    'folder': folder,
    'uploadedAt': FieldValue.serverTimestamp(),
    'fileSize': fileSize,
  });
}

/// Firestore에서 특정 폴더의 파일 목록을 불러옵니다.
/// 업로드 시간(uploadedAt) 기준 내림차순으로 정렬합니다.
Future<List<Map<String, dynamic>>> fetchFileListFromFirestore(
    {required String folder}) async {
  final CollectionReference filesCollection =
      FirebaseFirestore.instance.collection('files');

  QuerySnapshot snapshot = await filesCollection
      .where('folder', isEqualTo: folder)
      .orderBy('uploadedAt', descending: true)
      .get();
  print('데이터 읽기 ');

  List<Map<String, dynamic>> files = snapshot.docs.map((doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    data['docId'] = doc.id;
    data['fileSize'] = data['fileSize'] ?? 0;
    return data;
  }).toList();

  return files;
}

/// Firestore와 Firebase Storage에서 파일을 삭제합니다.
Future<void> deleteFile(String docId, String downloadUrl) async {
  final CollectionReference filesCollection =
      FirebaseFirestore.instance.collection('files');

  try {
    await FirebaseStorage.instance.refFromURL(downloadUrl).delete();
  } catch (e) {
    debugPrint('🔥 Storage 파일 삭제 실패: $e');
  }

  await filesCollection.doc(docId).delete();
}
