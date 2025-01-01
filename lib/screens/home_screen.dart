import 'package:flutter/cupertino.dart'; // Cupertino 위젯 사용을 위한 라이브러리
import 'package:cloud_firestore/cloud_firestore.dart'; // Firebase Firestore 데이터베이스 라이브러리
import 'item_detail_screen.dart'; // 아이템 상세 화면을 정의한 파일 임포트

// HomeScreen 클래스는 StatefulWidget으로 정의, 앱의 홈 화면을 나타냄
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState(); // 상태 생성
}

// HomeScreen의 상태 클래스
class HomeScreenState extends State<HomeScreen> {
  String? selectedCategory; // 선택된 카테고리를 저장하는 변수
  final Map<String, String> categories = {}; // 카테고리 ID와 이름을 저장하는 맵
  final TextEditingController _nameController = TextEditingController(); // 이름 입력 필드 컨트롤러
  final TextEditingController _locationController = TextEditingController(); // 위치 입력 필드 컨트롤러

  @override
  void initState() {
    super.initState(); // 부모 클래스의 초기화 메서드 호출
    fetchCategories(); // Firestore에서 카테고리 가져오기 호출
  }

  @override
  void dispose() {
    _nameController.dispose(); // 이름 입력 필드 컨트롤러 해제
    _locationController.dispose(); // 위치 입력 필드 컨트롤러 해제
    super.dispose();
  }

  // Firestore에서 카테고리를 가져오는 메서드
  void fetchCategories() async {
    final query = await FirebaseFirestore.instance
        .collection('Categories')
        .get(); // 'Categories' 컬렉션 데이터 가져오기
    final data = query.docs.asMap().map((_, doc) {
      // 각 문서를 맵으로 변환
      final id = doc.id; // 문서 ID 가져오기
      final categoryName = doc['CategoryName'] as String; // 카테고리 이름 가져오기
      
      return MapEntry(id, categoryName); // MapEntry로 ID와 이름 반환
    });
    setState(() {
      categories.addAll(data); // 상태를 갱신하여 UI 업데이트
    });
  }

  // Firestore에 새 아이템 추가 메서드
  Future<void> addItem(
      String categoryId, String itemName, String location) async {
    await FirebaseFirestore.instance.collection('Items').add({
      'CategoryID': int.parse(categoryId), // 카테고리 ID를 정수로 저장
      'ItemName': itemName, // 아이템 이름 저장
      'Location': location, // 위치 저장
    });
  }

  // 새 아이템 추가 팝업 표시
  void showAddItemPopup() {
    _nameController.clear(); // 이전 입력값 초기화
    _locationController.clear(); // 이전 입력값 초기화

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Add New Item'), // 팝업 제목
        message: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16, // 키보드 높이 반영
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, // 입력창을 가로로 확장
              children: [
                CupertinoTextField(
                  controller: _nameController, // 이름 입력 컨트롤러 연결
                  autofocus: true, // 팝업 열릴 때 자동으로 포커스 설정
                  placeholder: 'Item Name', // 입력 필드에 플레이스홀더 표시
                  padding: const EdgeInsets.all(16), // 클릭 가능한 여백 추가
                ),
                const SizedBox(height: 10), // 간격 추가
                CupertinoTextField(
                  controller: _locationController, // 위치 입력 컨트롤러 연결
                  placeholder: 'Location', // 위치 입력 필드
                  padding: const EdgeInsets.all(16), // 클릭 가능한 여백 추가
                ),
              ],
            ),
          ),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              if (_nameController.text.isNotEmpty &&
                  _locationController.text.isNotEmpty &&
                  selectedCategory != null) {
                addItem(selectedCategory!, _nameController.text,
                    _locationController.text); // 새 아이템 추가
                Navigator.pop(context); // 팝업 닫기
              }
            },
            child: const Text('Add Item'), // 액션 버튼 텍스트
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context), // 팝업 닫기
          child: const Text('Cancel'), // 취소 버튼
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 화면 레이아웃 정의
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text("MICE PLAN 마이스플랜"), // 네비게이션 바 제목
      ),
      child: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                CupertinoButton(
                  child: Text(selectedCategory == null
                      ? 'Select Category' // 선택된 카테고리가 없으면 기본 텍스트
                      : categories[selectedCategory!]!), // 선택된 카테고리 이름 표시
                  onPressed: () => showCupertinoModalPopup(
                    context: context,
                    builder: (context) => CupertinoActionSheet(
                      title: const Text('Select a Category'), // 팝업 제목
                      actions: categories.entries
                          .map((entry) => CupertinoActionSheetAction(
                                onPressed: () {
                                  setState(() {
                                    selectedCategory =
                                        entry.key; // 선택된 카테고리 업데이트
                                  });
                                  Navigator.pop(context); // 팝업 닫기
                                },
                                child: Text(entry.value), // 카테고리 이름 표시
                              ))
                          .toList(),
                      cancelButton: CupertinoActionSheetAction(
                        onPressed: () => Navigator.pop(context), // 팝업 닫기
                        child: const Text('Cancel'), // 취소 버튼
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: selectedCategory == null
                      ? const Center(
                          child: Text('Please select a category')) // 선택되지 않은 경우
                      : StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('Items')
                              .where('CategoryID',
                                  isEqualTo: int.parse(selectedCategory!))
                              .snapshots(), // Firestore 실시간 데이터 스트림
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                child:
                                    CupertinoActivityIndicator(), // 로딩 인디케이터 표시
                              );
                            }
                            final items = snapshot.data!.docs; // 아이템 리스트 가져오기
                            return ListView.builder(
                              itemCount: items.length, // 아이템 개수
                              itemBuilder: (context, index) {
                                final data = items[index].data()
                                    as Map<String, dynamic>; // 아이템 데이터
                                return CupertinoListTile(
                                  title: Text(data['ItemName']), // 아이템 이름
                                  subtitle: Text(data['Location']), // 아이템 위치
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      CupertinoPageRoute(
                                        builder: (context) => ItemDetailScreen(
                                            itemId:
                                                items[index].id), // 상세 화면으로 이동
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Center(
              child: ClipOval(
                child: CupertinoButton(
                  padding: const EdgeInsets.all(16), // 버튼의 크기를 조정
                  color: const Color.fromARGB(88, 255, 142, 180), // 버튼 배경색
                  onPressed: showAddItemPopup, // 새 아이템 추가 팝업 호출
                  child: const Icon(
                    CupertinoIcons.add, // 버튼의 아이콘
                    color: CupertinoColors.white, // 아이콘 색상
                    size: 20, // 아이콘 크기
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}