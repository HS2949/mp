import 'package:flutter/cupertino.dart'; // Cupertino 위젯을 사용하기 위한 패키지
import 'package:flutter/services.dart'; // 클립보드 기능을 사용하기 위한 패키지
import 'package:flutter/material.dart'; // Flutter 기본 위젯을 사용하기 위한 패키지
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore 데이터베이스와 상호작용하기 위한 패키지

class ItemDetailScreen extends StatefulWidget { // StatefulWidget으로 상태 관리가 필요한 화면 정의
  final String itemId; // Firestore에서 특정 아이템을 식별하기 위한 ID

  const ItemDetailScreen({super.key, required this.itemId}); // 생성자 정의

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState(); // State 생성
}

class _ItemDetailScreenState extends State<ItemDetailScreen> { // 상태를 관리하는 클래스
  late Future<DocumentSnapshot> _future; // Firestore 데이터 조회 결과를 저장할 Future 변수

  @override
  void initState() { // 위젯이 생성될 때 초기화 작업 수행
    super.initState();
    _future = _fetchItemDetails(); // 데이터를 가져오는 Future 초기화
  }

  Future<DocumentSnapshot> _fetchItemDetails() { // Firestore에서 특정 문서를 가져오는 함수
    return FirebaseFirestore.instance
        .collection('Items') // 'Items' 컬렉션에서
        .doc(widget.itemId) // itemId에 해당하는 문서를
        .get(); // 가져옴
  }

  void _refreshScreen() { // 화면을 새로고침하는 함수
    setState(() {
      _future = _fetchItemDetails(); // Future를 다시 초기화하여 데이터 업데이트
    });
  }

  @override
  Widget build(BuildContext context) { // 화면을 그리는 메인 함수
    return CupertinoPageScaffold( // Cupertino 스타일의 화면 스캐폴드
      navigationBar: const CupertinoNavigationBar( // 상단 네비게이션 바
        middle: Text('Item Details'), // 제목 설정
      ),
      child: FutureBuilder<DocumentSnapshot>( // 비동기 데이터 처리용 FutureBuilder
        future: _future, // Future 변수 연결
        builder: (context, snapshot) { // 데이터를 가져왔을 때의 UI 정의
          if (!snapshot.hasData) { // 데이터가 없을 경우 로딩 상태 표시
            return const Center(
              child: CupertinoActivityIndicator(), // Cupertino 스타일 로딩 아이콘
            );
          }
          final data = snapshot.data!.data() as Map<String, dynamic>; // Firestore 데이터 가져오기

          Widget buildDataItem(String title, String? value) { // 개별 데이터 항목을 빌드하는 함수
            if (value == null || value.isEmpty) { // 값이 비어있으면 빈 위젯 반환
              return const SizedBox.shrink();
            }

            final combinedText = '$title: $value'; // 타이틀과 값을 조합한 텍스트

            return GestureDetector( // 롱프레스 이벤트를 처리하기 위한 위젯
              onLongPress: () { // 롱프레스 시 클립보드 복사 및 팝업 표시
                Clipboard.setData(ClipboardData(text: combinedText));
                showTemporaryPopup(context, combinedText); // 임시 팝업 호출
              },
              child: Row( // 데이터 항목을 가로로 정렬
                crossAxisAlignment: CrossAxisAlignment.start, // 아이템들을 위쪽 정렬
                children: [
                  SelectableText( // 제목 텍스트
                    '$title: ',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold), // 텍스트 스타일
                  ),
                  Expanded( // 값 텍스트 (긴 내용도 처리 가능)
                    child: SelectableText(
                      value,
                      style: const TextStyle(fontSize: 16), // 텍스트 스타일
                    ),
                  ),
                  CupertinoButton( // 클립보드 복사 버튼
                    padding: const EdgeInsets.symmetric(horizontal: 8), // 버튼 패딩
                    child: const Icon(CupertinoIcons.doc_on_doc), // 복사 아이콘
                    onPressed: () { // 클릭 시 클립보드 복사 및 팝업 표시
                      Clipboard.setData(ClipboardData(text: combinedText));
                      showTemporaryPopup(context, combinedText);
                    },
                  ),
                ],
              ),
            );
          }

          return ListView( // 데이터를 표시하는 리스트
            padding: const EdgeInsets.all(16.0), // 리스트 패딩
            children: [
              buildDataItem('상호명', data['ItemName']), // 상호명 표시
              const SizedBox(height: 10), // 간격 추가
              buildDataItem('주소', data['Location']), // 주소 표시
              const SizedBox(height: 10), // 간격 추가
              buildDataItem('전화번호', data['PhoneNumber']), // 전화번호 표시
              const SizedBox(height: 20), // 간격 추가
              ConstrainedBox( // 크기 제한이 있는 버튼
                constraints: const BoxConstraints(maxWidth: 100), // 최대 너비 설정
                child: CupertinoButton(
                  color: CupertinoColors.tertiaryLabel, // 버튼 색상
                  onPressed: () { // 버튼 클릭 시 편집 다이얼로그 호출
                    showEditDialog(context, widget.itemId, data);
                  },
                  child: const Text('Edit'), // 버튼 텍스트
                ),
              ),
              const SizedBox(height: 10), // 간격 추가
              ConstrainedBox( // 삭제 버튼
                constraints: const BoxConstraints(maxWidth: 100), // 최대 너비 설정
                child: CupertinoButton(
                  color: const Color.fromARGB(255, 255, 105, 97), // 버튼 색상
                  onPressed: () { // 삭제 다이얼로그 호출
                    showDeleteConfirmation(context, widget.itemId);
                  },
                  child: const Text('Delete'), // 버튼 텍스트
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void showEditDialog(BuildContext context, String itemId, Map<String, dynamic> data) { // 편집 다이얼로그 표시 함수
    final TextEditingController nameController = // 상호명 텍스트 입력 컨트롤러
        TextEditingController(text: data['ItemName']);
    final TextEditingController locationController = // 주소 텍스트 입력 컨트롤러
        TextEditingController(text: data['Location']);
    final TextEditingController phoneController = // 전화번호 텍스트 입력 컨트롤러
        TextEditingController(text: data['PhoneNumber']);

    showCupertinoDialog( // Cupertino 스타일의 다이얼로그 표시
      context: context,
      builder: (context) {
        return CupertinoAlertDialog( // 편집 다이얼로그
          title: const Text('Edit Item'), // 다이얼로그 제목
          content: Column( // 텍스트 필드 표시
            children: [
              CupertinoTextField( // 이름 입력 필드
                controller: nameController,
                placeholder: 'Name', // 플레이스홀더 텍스트
              ),
              const SizedBox(height: 10), // 간격 추가
              CupertinoTextField( // 위치 입력 필드
                controller: locationController,
                placeholder: 'Location', // 플레이스홀더 텍스트
              ),
              const SizedBox(height: 10), // 간격 추가
              CupertinoTextField( // 전화번호 입력 필드
                controller: phoneController,
                placeholder: 'Phone Number', // 플레이스홀더 텍스트
              ),
            ],
          ),
          actions: [ // 다이얼로그 액션 버튼
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context), // 취소 버튼
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction( // 저장 버튼
              onPressed: () async { // Firestore에 업데이트 후 새로고침
                await FirebaseFirestore.instance
                    .collection('Items')
                    .doc(itemId)
                    .update({
                  'ItemName': nameController.text,
                  'Location': locationController.text,
                  'PhoneNumber': phoneController.text,
                });
                Navigator.pop(context); // 다이얼로그 닫기
                _refreshScreen(); // 화면 새로고침
              },
              child: const Text('Save'), // 버튼 텍스트
            ),
          ],
        );
      },
    );
  }

  void showDeleteConfirmation(BuildContext context, String itemId) { // 삭제 확인 다이얼로그 표시 함수
    showCupertinoDialog( // Cupertino 스타일의 다이얼로그 표시
      context: context,
      builder: (context) {
        return CupertinoAlertDialog( // 삭제 다이얼로그
          title: const Text('Delete Item'), // 다이얼로그 제목
          content: const Text('Are you sure you want to delete this item?'), // 삭제 확인 메시지
          actions: [ // 다이얼로그 액션 버튼
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context), // 취소 버튼
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction( // 삭제 버튼
              onPressed: () async { // Firestore에서 문서 삭제 후 화면 닫기
                await FirebaseFirestore.instance
                    .collection('Items')
                    .doc(itemId)
                    .delete();
                Navigator.pop(context); // 다이얼로그 닫기
                Navigator.pop(context); // 이전 화면으로 돌아가기
              },
              isDestructiveAction: true, // 버튼 스타일을 파괴적으로 설정
              child: const Text('Delete'), // 버튼 텍스트
            ),
          ],
        );
      },
    );
  }

  void showTemporaryPopup(BuildContext context, String message) { // 임시 팝업 표시 함수
    final overlay = Overlay.of(context); // 현재 화면의 Overlay 가져오기
    final overlayEntry = OverlayEntry( // OverlayEntry 생성
      builder: (context) {
        return FadeOutPopup(message: message); // FadeOutPopup 표시
      },
    );

    overlay.insert(overlayEntry); // Overlay에 팝업 추가

    Future.delayed(const Duration(seconds: 1), () { // 1초 후 팝업 제거
      overlayEntry.remove();
    });
  }
}

class FadeOutPopup extends StatefulWidget { // 페이드 아웃 팝업 위젯 정의
  final String message; // 표시할 메시지

  const FadeOutPopup({super.key, required this.message}); // 생성자 정의

  @override
  State<FadeOutPopup> createState() => _FadeOutPopupState(); // State 생성
}

class _FadeOutPopupState extends State<FadeOutPopup> // 페이드 아웃 팝업 상태 관리
    with SingleTickerProviderStateMixin { // 애니메이션을 위한 Mixin 사용
  late AnimationController _controller; // 애니메이션 컨트롤러
  late Animation<double> _fadeAnimation; // 페이드 애니메이션

  @override
  void initState() { // 초기화 작업 수행
    super.initState();
    _controller = AnimationController( // 애니메이션 컨트롤러 설정
      duration: const Duration(milliseconds: 1000), // 애니메이션 지속 시간
      vsync: this, // vsync 설정
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate( // 페이드 아웃 애니메이션 정의
      CurvedAnimation(parent: _controller, curve: Curves.easeOut), // 곡선 설정
    );

    Future.delayed(const Duration(milliseconds: 200), () { // 200ms 후 애니메이션 시작
      _controller.forward();
    });
  }

  @override
  Widget build(BuildContext context) { // 위젯을 빌드하는 함수
    return Positioned.fill( // 화면 전체에 배치
      child: FadeTransition( // 페이드 애니메이션 적용
        opacity: _fadeAnimation, // 페이드 애니메이션 설정
        child: Center(
          child: CupertinoPopupSurface( // 팝업 표면 스타일
            child: Padding(
              padding: const EdgeInsets.all(16.0), // 내부 패딩
              child: Text(
                widget.message, // 표시할 메시지
                style: const TextStyle(
                    fontSize: 16, color: Color.fromARGB(255, 94, 93, 93)), // 텍스트 스타일
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() { // 리소스 정리
    _controller.dispose(); // 애니메이션 컨트롤러 해제
    super.dispose();
  }
}
