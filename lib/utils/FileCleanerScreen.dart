import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:mp_db/constants/styles.dart';
import 'package:path/path.dart' as p;

class CombinedFileCheckerScreen extends StatefulWidget {
  @override
  _CombinedFileCheckerScreenState createState() =>
      _CombinedFileCheckerScreenState();
}

class _CombinedFileCheckerScreenState extends State<CombinedFileCheckerScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  List<String> logMessages = [];
  bool isProcessing = false;
  double progress = 0.0;

  // [1] 삭제 후보: 스토리지에 파일이 없는 files 문서
  List<Map<String, String>> deletionCandidates = [];
  // [2] 폴더 매칭 오류 후보: folder 값이 Items/Sub_Items와 일치하지 않는 문서
  List<Map<String, String>> mismatchCandidates = [];
  List<List<String>> mismatchList = [];

  // [3] 스토리지에는 존재하지만 files 컬렉션에 없는 파일 목록
  List<String> untrackedFiles = [];
  bool isFindingUntracked = false;

  // 복구 진행 상태
  bool isRecovering = false;
  double recoverProgress = 0.0;

  /// 로그 메시지 추가
  void addLog(String message) {
    setState(() {
      logMessages.add(message);
    });
  }

  Map<String, String> extractFirebasePath(String url) {
    Uri uri = Uri.parse(url);

    // "o/" 위치 찾기
    String path = uri.path;
    int index = path.indexOf("/o/");

    if (index == -1) {
      return {'folder': '', 'filename': ''};
    }

    // "o/" 다음 경로 가져오기 (URL 디코딩)
    String fullPath = Uri.decodeFull(path.substring(index + 3));

    // 파일명과 폴더 경로 분리
    List<String> pathSegments = fullPath.split('/');
    String filename = pathSegments.isNotEmpty ? pathSegments.last : '';
    String folderPath = pathSegments.length > 1
        ? pathSegments.sublist(0, pathSegments.length - 1).join('/')
        : '';

    return {'folder': folderPath, 'filename': filename};
  }

  /// files 컬렉션을 한 번의 루프로 순회하며 존재 여부 검사와 폴더 매칭 검사를 동시에 수행합니다.
  Future<void> processFiles() async {
    setState(() {
      logMessages.clear();
      deletionCandidates.clear();
      mismatchCandidates.clear();
      isProcessing = true;
      progress = 0.0;
    });

    // 먼저 Items 컬렉션의 매핑 정보를 미리 가져옵니다.
    addLog('아이템 데이터를 확인 중입니다.');
    Map<String, List<String>> itemsMapping = await _fetchItemsMapping();
    addLog('아이템 데이터를 확인 완료');
    try {
      QuerySnapshot snapshot = await firestore.collection('files').get();
      int totalFiles = snapshot.docs.length;
      int checkedFiles = 0;
      String disLog;
      for (var doc in snapshot.docs) {
        disLog = '';
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String folder = data['folder'] ?? '';
        String downloadUrl = data['downloadUrl'] ?? '';
        Map<String, String> extracted = extractFirebasePath(downloadUrl);

        // [1] 파일 존재 여부 검사: downloadUrl을 통해 스토리지 파일 존재 확인
        bool fileExists = true;
        try {
          Reference fileRef = storage.refFromURL(downloadUrl);
          await fileRef.getMetadata();
        } catch (e) {
          fileExists = false;
        }

        if (!fileExists) {
          disLog = '$disLog\n❌ 파일 없음 (삭제 후보): $folder';
          deletionCandidates.add({'docId': doc.id, 'filePath': folder});
        } else {
          disLog =
              '$disLog\n✅ ${extracted['filename']} \n 파일 존재 : ${extracted['folder']}';
          // [2] 파일이 존재하는 경우에 폴더 매칭 검사 수행
          if (folder.startsWith('uploads/')) {
            String relativePath = folder.substring('uploads/'.length);
            List<String> parts = relativePath.split('/');
            if (parts.isEmpty) {
              disLog = '$disLog\n❌ 폴더 형식 오류: $folder';
              mismatchCandidates
                  .add({'docId': doc.id, 'currentFolder': folder});
            } else {
              // 가능한 모든 분할을 고려하여 itemName과 subItemCandidate 추출
              bool foundMatch = false;
              String? matchedItemName;
              // ignore: unused_local_variable
              String? matchedSubItem;
              // i: itemName에 해당하는 부분의 길이 (parts의 처음 i개를 itemName 후보로 사용)
              // 가능한 i값을 parts.length부터 1까지 내림차순으로 검사 (긴 itemName 후보 우선)
              for (int i = parts.length; i >= 1; i--) {
                String candidateItemName = parts.sublist(0, i).join('/');
                String candidateSubItem =
                    parts.length > i ? parts.sublist(i).join('/') : '';
                // candidateItemName이 Items 매핑에 존재하는지 확인
                if (itemsMapping.containsKey(candidateItemName)) {
                  // subItem이 비어있거나 'default'인 경우는 매칭 성공으로 간주,
                  // 또는 candidateSubItem이 itemsMapping에 등록된 하위 목록에 포함되어 있으면 성공
                  matchedItemName = candidateItemName;
                  if (candidateSubItem.isEmpty ||
                      candidateSubItem.toLowerCase() == 'default' ||
                      candidateSubItem.toLowerCase() == 'files' ||
                      (itemsMapping[candidateItemName] ?? [])
                          .contains(candidateSubItem)) {
                    matchedSubItem = candidateSubItem;
                    foundMatch = true;
                    break;
                  }
                }
              }
              if (!foundMatch) {
                disLog = '$disLog\n❌ 매칭 실패 (ItemName 또는 SubItem 불일치): $folder';
                mismatchCandidates
                    .add({'docId': doc.id, 'currentFolder': folder});
                if (matchedItemName == null) {
                  mismatchList.add([]);
                } else {
                  mismatchList.add(itemsMapping[matchedItemName]!);
                }
              } else {
                // addLog(
                //     '✅ 매칭 성공: itemName: $matchedItemName, subItem: $matchedSubItem, folder: $folder');
                disLog =
                    '$disLog\n 매칭 성공 : $folder ${extracted['folder'] == folder ? "" : "(변경됨)"}';
              }
            }
          } else {
            // folder가 uploads/로 시작하지 않는 경우
            disLog = '$disLog\n❌ 폴더 경로 오류 (uploads/ 미포함): $folder';
            mismatchCandidates.add({
              'docId': doc.id,
              'currentFolder': folder,
              'fileName': data['fileName'] ?? ''
            });
          }
        }
        addLog(disLog);
        checkedFiles++;
        setState(() {
          progress = checkedFiles / totalFiles;
        });
      }
      addLog('🎉 파일 검사 완료');
    } catch (e) {
      addLog('❌ 검사 오류: $e');
    } finally {
      setState(() {
        isProcessing = false;
      });
      // [1] 삭제 후보 처리: 사용자에게 삭제 확인 후 진행
      if (deletionCandidates.isNotEmpty) {
        await _confirmAndDeleteCandidates();
      }
      // [2] 폴더 매칭 오류 후보 처리: 사용자에게 올바른 folder 입력을 받아 업데이트
      if (mismatchCandidates.isNotEmpty) {
        await _confirmAndUpdateFolder();
      }
      // [3] 스토리지 미등록 파일 검색 및 복구 처리
      await findUntrackedFiles();
    }
  }

  /// Items 컬렉션에서 ItemName과 하위 Sub_Items의 SubItem 목록을 매핑으로 생성합니다.
  Future<Map<String, List<String>>> _fetchItemsMapping() async {
    Map<String, List<String>> mapping = {};
    QuerySnapshot itemsSnapshot = await firestore.collection('Items').get();
    print('데이터 읽기 ');
    for (var itemDoc in itemsSnapshot.docs) {
      Map<String, dynamic> itemData = itemDoc.data() as Map<String, dynamic>;
      String itemName = itemData['ItemName'] ?? '';
      QuerySnapshot subSnapshot = await firestore
          .collection('Items')
          .doc(itemDoc.id)
          .collection('Sub_Items')
          .get();
          print('데이터 읽기 ');
      List<String> subItems = [];
      for (var subDoc in subSnapshot.docs) {
        Map<String, dynamic> subData = subDoc.data() as Map<String, dynamic>;
        String subItem = subData['SubName'] ?? '';
        subItems.add(subItem);
      }
      mapping[itemName] = subItems;
    }
    return mapping;
  }

  /// 삭제 후보 목록을 사용자에게 보여주고, 확인 후 삭제를 진행합니다.
  Future<void> _confirmAndDeleteCandidates() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('삭제 예정 파일 확인'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: deletionCandidates.length,
              itemBuilder: (context, index) {
                var candidate = deletionCandidates[index];
                return ListTile(
                  title: Text(candidate['filePath'] ?? ''),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('삭제'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      for (var candidate in deletionCandidates) {
        try {
          String docId = candidate['docId'] ?? '';
          await firestore.collection('files').doc(docId).delete();
          addLog('🗑 삭제됨: ${candidate['filePath']}');
        } catch (e) {
          addLog('❌ 삭제 실패: ${candidate['filePath']} - $e');
        }
      }
      addLog('✅ 삭제 작업 완료');
    } else {
      addLog('🛑 삭제 작업 취소됨');
    }
  }

  /// 폴더 매칭 오류 후보에 대해, 사용자에게 올바른 folder 값을 입력받아 Firestore 문서를 업데이트합니다.
  Future<void> _confirmAndUpdateFolder() async {
    int i = 0;
    for (var candidate in mismatchCandidates) {
      String currentFolder = candidate['currentFolder'] ?? '';
      String docId = candidate['docId'] ?? '';
      String fileName = candidate['fileName'] ?? '';
      List<String> subList = mismatchList[i];
      TextEditingController controller =
          TextEditingController(text: currentFolder);
      TextEditingController _controller =
          TextEditingController(text: subList.join("\n"));
      String? newFolder = await showDialog<String>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              subList.length == 0 ? '폴더 수정 - 아이템명' : '폴더 수정 - 서브 아이템명',
              style: AppTheme.appbarTitleTextStyle,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SelectableText(fileName),
                SizedBox(height: 10),
                SelectableText('현재 폴더: $currentFolder'),
                SizedBox(height: 20),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: '수정할 folder명',
                  ),
                ),
                if (subList.length > 0) ...[
                  SizedBox(height: 20),
                  TextField(
                    controller: _controller,
                    readOnly: true, // 읽기 전용 설정
                    maxLines: 5, // 최대 5줄
                    decoration: InputDecoration(
                      labelText: "Fruits",
                      border: OutlineInputBorder(),
                    ),
                    style: TextStyle(fontSize: 13.0), // 가독성을 위한 스타일
                    scrollPhysics:
                        AlwaysScrollableScrollPhysics(), // 스크롤 가능하게 설정
                  )
                ]
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: Text('변경'),
              ),
            ],
          );
        },
      );
      if (newFolder != null && newFolder.isNotEmpty) {
        try {
          await firestore
              .collection('files')
              .doc(docId)
              .update({'folder': newFolder});
          addLog('✅ 폴더 업데이트됨: $currentFolder -> $newFolder');
        } catch (e) {
          addLog('❌ 폴더 업데이트 실패: $currentFolder - $e');
        }
      } else {
        addLog('ℹ️ 폴더 수정 취소됨: $currentFolder');
      }
      i++;
    }
  }

  /// 스토리지의 'uploads' 폴더 내 모든 파일 경로를 재귀적으로 수집하고, files 컬렉션에 없는 파일들을 산출합니다.
  Future<void> findUntrackedFiles() async {
    setState(() {
      isFindingUntracked = true;
      untrackedFiles.clear();
      addLog('🔍 스토리지 미등록 파일 검색 시작...');
    });

    try {
      Reference uploadsRef = storage.ref().child('uploads');
      List<String> storageFilePaths =
          await _listAllFilesRecursively(uploadsRef);

      QuerySnapshot snapshot = await firestore.collection('files').get();
      print('데이터 읽기 ');

      // Firestore에 등록된 각 파일의 downloadUrl에서 실제 스토리지 경로(uploads/ 포함)를 추출하여 비교합니다.
      Set<String> firestoreFilePaths = snapshot.docs.map<String>((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String downloadUrl = data['downloadUrl'] ?? '';
        if (downloadUrl.isNotEmpty) {
          Map<String, String> extracted = extractFirebasePath(downloadUrl);
          // downloadUrl에서 추출한 folder와 filename을 합쳐서 전체 경로와 비교합니다.
          return '${extracted['folder']}/${extracted['filename']}';
        }
        return '';
      }).toSet();

      List<String> notTracked = [];
      for (var path in storageFilePaths) {
        if (!firestoreFilePaths.contains(path)) {
          notTracked.add(path);
        }
      }

      setState(() {
        untrackedFiles = notTracked;
      });

      if (notTracked.isEmpty) {
        addLog('✅ 모든 스토리지 파일은 Firestore에 등록되어 있습니다.');
      } else {
        addLog('🗂 미등록 스토리지 파일 ${notTracked.length}개 발견.');
      }
    } catch (e) {
      addLog('❌ 스토리지 검색 오류: $e');
    } finally {
      setState(() {
        isFindingUntracked = false;
      });
    }
  }

  Future<List<String>> _listAllFilesRecursively(Reference ref) async {
    List<String> filePaths = [];
    ListResult result = await ref.listAll();
    for (var item in result.items) {
      filePaths.add(item.fullPath);
    }
    for (var prefix in result.prefixes) {
      List<String> subFiles = await _listAllFilesRecursively(prefix);
      filePaths.addAll(subFiles);
    }
    return filePaths;
  }

  /// 미등록 파일 복구 전에 사용자에게 복구 여부를 묻습니다.
  Future<void> _confirmAndRecoverUntrackedFiles() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('복구 예정 파일 확인'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: untrackedFiles.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(untrackedFiles[index]),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('복구'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await recoverUntrackedFiles();
    } else {
      addLog('🛑 복구 작업 취소됨');
    }
  }

  /// 미등록 파일들을 Firestore의 files 컬렉션에 복구합니다.
  Future<void> recoverUntrackedFiles() async {
    setState(() {
      isRecovering = true;
      recoverProgress = 0.0;
    });

    int total = untrackedFiles.length;
    int count = 0;
    for (var filePath in untrackedFiles) {
      try {
        Reference ref = storage.ref().child(filePath);
        String downloadUrl = await ref.getDownloadURL();
        String fileName = p.basename(filePath);
        await firestore.collection('files').add({
          'folder': filePath,
          'fileName': fileName,
          'downloadUrl': downloadUrl,
          'uploadedAt': FieldValue.serverTimestamp(),
        });
        addLog('✅ 복구됨: $filePath');
      } catch (e) {
        addLog('❌ 복구 실패: $filePath - $e');
      }
      count++;
      setState(() {
        recoverProgress = count / total;
      });
    }

    setState(() {
      isRecovering = false;
    });
    addLog('🎉 복구 작업 완료');
  }

  void cancelProcessing() {
    setState(() {
      isProcessing = false;
      addLog('🛑 검사 취소됨');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('파일 검사 및 수정 도구'),
      ),
      body: Column(
        children: [
          if (isProcessing) LinearProgressIndicator(value: progress),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: isProcessing ? null : processFiles,
                  child: Text('검사 시작'),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: isProcessing ? cancelProcessing : null,
                  child: Text('취소'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                // 진행 로그 출력
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '진행 로그:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                for (var log in logMessages)
                  ListTile(
                    title: Text(
                      log,
                      style: AppTheme.textHintTextStyle,
                    ),
                  ),
                Divider(),
                // 미등록 파일 목록 및 복구 버튼
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Firestore 미등록 스토리지 파일:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (isFindingUntracked)
                  Center(child: CircularProgressIndicator()),
                if (!isFindingUntracked && untrackedFiles.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('미등록 파일이 없습니다.'),
                  ),
                for (var path in untrackedFiles)
                  ListTile(
                    title: Text(path),
                  ),
                if (untrackedFiles.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: isRecovering
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  '복구 진행: ${(recoverProgress * 100).toStringAsFixed(0)}%'),
                              LinearProgressIndicator(value: recoverProgress),
                            ],
                          )
                        : ElevatedButton(
                            onPressed: _confirmAndRecoverUntrackedFiles,
                            child: Text('복구 실행'),
                          ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
