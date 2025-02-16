import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
// 로그인 필요시 사용
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mp_db/constants/styles.dart';
import 'package:path/path.dart' as path;

/// 재귀적으로 Firebase Storage에서 모든 폴더 목록 가져오기
/// 파일 경로를 파싱하여 폴더 목록(중복 없이)을 Set으로 반환
Future<Set<String>> fetchFolders([Reference? ref]) async {
  final Reference reference =
      ref ?? FirebaseStorage.instance.ref().child('uploads');
  final Set<String> folders = {};

  try {
    print("Fetching folders for: ${reference.fullPath}");
    ListResult result = await reference.listAll();
    print(
        "Found ${result.items.length} items, ${result.prefixes.length} prefixes for ${reference.fullPath}");

    for (Reference fileRef in result.items) {
      String fullPath = fileRef.fullPath;
      List<String> parts = fullPath.split('/');
      if (parts.length > 1) {
        String pathAccumulator = "";
        for (int i = 0; i < parts.length - 1; i++) {
          pathAccumulator = pathAccumulator.isEmpty
              ? parts[i]
              : "$pathAccumulator/${parts[i]}";
          folders.add(pathAccumulator);
        }
      }
    }

    for (Reference prefix in result.prefixes) {
      print("Found prefix: ${prefix.fullPath}");
      folders.add(prefix.fullPath);
      Set<String> subFolders = await fetchFolders(prefix);
      folders.addAll(subFolders);
    }
  } catch (e) {
    print("폴더 목록 가져오기 실패: $e");
  }

  return folders;
}

/// 폴더와 파일명을 입력받는 다이얼로그 함수
Future<Map<String, String>?> showFolderAndFileNameDialog(
  BuildContext context, {
  required String initialFileName,
}) async {
  final TextEditingController fileNameController =
      TextEditingController(text: initialFileName);
  const String selectedFolder = "uploads"; // 기본 폴더 설정

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
                  decoration: const InputDecoration(labelText: "파일명 (확장자 포함)"),
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
                        final fileName = fileNameController.text.trim().isEmpty
                            ? '${DateTime.now().millisecondsSinceEpoch}.jpg'
                            : fileNameController.text.trim();
                        Navigator.of(context).pop(
                            {'folder': selectedFolder, 'fileName': fileName});
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

/// 파일 업로드 후 Firestore에 메타데이터 저장
Future<String?> uploadNewImage(BuildContext context) async {
  final ImagePicker picker = ImagePicker();
  final XFile? imageFile = await picker.pickImage(source: ImageSource.gallery);
  if (imageFile == null) return null;

  File file = File(imageFile.path);
  String initialFileName = path.basename(imageFile.path);

  // 폴더 및 파일명 입력 다이얼로그 호출
  final options = await showFolderAndFileNameDialog(
    context,
    initialFileName: initialFileName,
  );
  if (options == null) return null;

  final String folder =
      options['folder']!.isNotEmpty ? options['folder']! : 'uploads';
  final String fileName = options['fileName']!.isNotEmpty
      ? options['fileName']!
      : '${DateTime.now().millisecondsSinceEpoch}.jpg';

  try {
    Reference storageRef =
        FirebaseStorage.instance.ref().child('$folder/$fileName');

    SettableMetadata metadata = SettableMetadata(
      contentDisposition: 'inline',
      contentType: 'image/jpeg',
    );

    bool loadingShown = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        loadingShown = true;
        return Center(child: CircularProgressIndicator());
      },
    );

    UploadTask uploadTask = storageRef.putFile(file, metadata);
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();

    if (loadingShown) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    // Firestore에 파일 메타데이터 저장 (문서 ID를 위해 add() 후 반환되는 docRef.id 사용)
    await FirebaseFirestore.instance.collection('files').add({
      'folder': folder,
      'fileName': fileName,
      'downloadUrl': downloadUrl,
      'uploadedAt': FieldValue.serverTimestamp(),
    });

    return downloadUrl;
  } catch (e) {
    print("업로드 실패: $e");
    Navigator.of(context, rootNavigator: true).pop();
    return null;
  }
}

/// 파일 삭제 함수: Storage와 Firestore에서 모두 삭제
Future<void> deleteFile(String docId, String downloadUrl) async {
  try {
    // Storage 삭제
    Reference storageRef = FirebaseStorage.instance.refFromURL(downloadUrl);
    await storageRef.delete();
    // Firestore 삭제
    await FirebaseFirestore.instance.collection('files').doc(docId).delete();
  } catch (e) {
    print("삭제 실패: $e");
  }
}

/// Firestore에서 파일 목록을 조회 (문서 ID 포함)
Future<List<Map<String, dynamic>>> fetchFileListFromFirestore() async {
  QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection('files')
      .orderBy('uploadedAt', descending: true)
      .get();

  return snapshot.docs.map((doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['docId'] = doc.id;
    return data;
  }).toList();
}

/// 기존 이미지 선택 다이얼로그 (그리드 형태 썸네일 및 파일명, 삭제 아이콘 포함)
class ExistingImagesDialog extends StatefulWidget {
  const ExistingImagesDialog({Key? key}) : super(key: key);

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
    files = await fetchFileListFromFirestore();
    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        "기존 이미지 선택",
        style: AppTheme.appbarTitleTextStyle,
      ),
      content: loading
          ? Center(child: CircularProgressIndicator())
          : files.isEmpty
              ? Text("저장된 파일이 없습니다.")
              : Container(
                  width: double.maxFinite,
                  height: 300,
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
                                child: Image.network(
                                  downloadUrl,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            // 파일명 오버레이 (하단 배경 반투명)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                color: Colors.black54,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                child: Text(
                                  fileName,
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 10),
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
                                    color: Colors.redAccent, size: 18),
                                onPressed: () async {
                                  // 삭제 확인 다이얼로그
                                  bool? confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: Text("삭제 확인",
                                            style:
                                                AppTheme.appbarTitleTextStyle),
                                        content: Text("이 파일을 삭제하시겠습니까?"),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: Text("취소"),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: Text("삭제"),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                  if (confirm == true) {
                                    await deleteFile(docId, downloadUrl);
                                    // 목록 새로고침
                                    await loadFiles();
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text("취소"),
        ),
      ],
    );
  }
}

/// 기존 이미지 선택: 그리드 다이얼로그 호출
Future<String?> selectExistingImage(BuildContext context) async {
  return await showDialog<String>(
    context: context,
    builder: (context) {
      return ExistingImagesDialog();
    },
  );
}

/// 📌 다이얼로그를 통해 새 이미지 업로드 또는 기존 이미지 선택 제공
Future<String?> showImageSelectionDialog(BuildContext context) async {
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
                        String? url = await uploadNewImage(context);
                        Navigator.of(context).pop(url);
                      },
                      child: Text("새 이미지 업로드"),
                    ),
                    TextButton(
                      onPressed: () async {
                        String? url = await selectExistingImage(context);
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

/// 파일 목록을 표시하는 화면 (Firestore 데이터 사용)
class FileListScreen extends StatelessWidget {
  const FileListScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('파일 목록 (Firestore)')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchFileListFromFirestore(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('파일이 없습니다.'));
          }
          final files = snapshot.data!;
          return ListView.builder(
            itemCount: files.length,
            itemBuilder: (context, index) {
              final data = files[index];
              return ListTile(
                title: Text(data['fileName'] ?? 'No Name',
                    style: AppTheme.appbarTitleTextStyle),
                subtitle: Text(data['downloadUrl'] ?? '',
                    style: AppTheme.appbarTitleTextStyle),
                onTap: () {
                  print('선택한 파일 URL: ${data['downloadUrl']}');
                },
              );
            },
          );
        },
      ),
    );
  }
}

/// 예제 메인 위젯
class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? selectedImageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('이미지 선택 및 목록', style: AppTheme.appbarTitleTextStyle),
        actions: [
          IconButton(
            icon: Icon(Icons.list),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const FileListScreen()));
            },
          )
        ],
      ),
      body: Center(
        child: selectedImageUrl == null
            ? Text('이미지를 선택하세요.')
            : Image.network(selectedImageUrl!),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          String? url = await showImageSelectionDialog(context);
          if (url != null) {
            setState(() {
              selectedImageUrl = url;
            });
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Storage & Firestore Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}
