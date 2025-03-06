// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mp_db/utils/widget_help.dart';

class ItemProvider extends ChangeNotifier {
  List<DocumentSnapshot> _items = [];
  List<DocumentSnapshot> get items => _items;

  List<DocumentSnapshot> _filteredItem = [];
  List<DocumentSnapshot> get filteredItem => _filteredItem;

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> get categories => _categories;

  List<DocumentSnapshot> _fields = [];
  List<DocumentSnapshot> get fields => _fields;

  Map<String, Map<String, dynamic>> _fieldMappings =
      {}; // 🔹 영어 → {한글, IsDefault} 매핑 저장
  Map<String, Map<String, dynamic>> get fieldMappings =>
      _fieldMappings; // Getter 추가

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // StreamSubscriptions for real-time listeners
  StreamSubscription? _itemSubscription;
  StreamSubscription? _categorySubscription;
  StreamSubscription? _fieldSubscription;

  void loadSnapshot() {
    _isLoading = true;
    notifyListeners();

    // 각 컬렉션의 첫 로딩 완료 여부를 추적할 변수
    bool itemsLoaded = false;
    bool categoriesLoaded = false;
    bool fieldsLoaded = false;

    _itemSubscription = FirebaseFirestore.instance
        .collection('Items')
        .snapshots()
        .listen((snapshot) {
      _items = snapshot.docs;
      _filteredItem = List.from(_items);

      // 첫 번째 스냅샷일 때만 플래그 설정
      if (!itemsLoaded) {
        itemsLoaded = true;
        // 모든 데이터가 최초 로딩 완료되면 로딩 상태 해제
        if (itemsLoaded && categoriesLoaded && fieldsLoaded) {
          _isLoading = false;
          notifyListeners();
        }
      }

      notifyListeners();
    });

    _categorySubscription = FirebaseFirestore.instance
        .collection('Categories')
        .snapshots()
        .listen((snapshot) {
      _categories = [
        {'itemID': '0', 'Name': '전체', 'Color': 'Silver', 'Icon': 'List'},
        ...snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'itemID': doc.id,
            'Name': data['CategoryName'],
            'Color': data['Color'],
            'Icon': data['Icon'],
          };
        }).toList(),
      ];

      if (!categoriesLoaded) {
        categoriesLoaded = true;
        if (itemsLoaded && categoriesLoaded && fieldsLoaded) {
          _isLoading = false;
          notifyListeners();
        }
      }

      notifyListeners();
    });

    _fieldSubscription = FirebaseFirestore.instance
        .collection('Fields')
        .snapshots()
        .listen((snapshot) {
      _fields = snapshot.docs;

      // 영어 필드 Key → 한글 매핑 생성
      _fieldMappings = {
        for (var doc in snapshot.docs)
          (doc.data())['FieldKey']: {
            'FieldName': (doc.data())['FieldName'],
            'FieldOrder': (doc.data())['FieldOrder'],
            'IsDefault': (doc.data())['IsDefault'] ?? false,
          }
      };

      if (!fieldsLoaded) {
        fieldsLoaded = true;
        if (itemsLoaded && categoriesLoaded && fieldsLoaded) {
          _isLoading = false;
          notifyListeners();
        }
      }

      notifyListeners();
    });
  }

  /// 🔹 Key 변환 메서드 (한글 Key 매칭)
  Map<String, dynamic> convertKeysToKorean(Map<String, dynamic> data) {
    return data.map((key, value) {
      // 🔹 한글 Key 매칭 (isDefault 값은 사용하지 않음)
      String newKey = _fieldMappings[key]?['FieldName'] ?? key;

      return MapEntry(newKey, value);
    });
  }

  // 한글 음절을 기본 자모로 분해하는 함수
  String decomposeHangul(String text) {
    const List<String> initials = [
      'ㄱ',
      'ㄲ',
      'ㄴ',
      'ㄷ',
      'ㄸ',
      'ㄹ',
      'ㅁ',
      'ㅂ',
      'ㅃ',
      'ㅅ',
      'ㅆ',
      'ㅇ',
      'ㅈ',
      'ㅉ',
      'ㅊ',
      'ㅋ',
      'ㅌ',
      'ㅍ',
      'ㅎ'
    ];
    const List<String> medials = [
      'ㅏ',
      'ㅐ',
      'ㅑ',
      'ㅒ',
      'ㅓ',
      'ㅔ',
      'ㅕ',
      'ㅖ',
      'ㅗ',
      'ㅘ',
      'ㅙ',
      'ㅚ',
      'ㅛ',
      'ㅜ',
      'ㅝ',
      'ㅞ',
      'ㅟ',
      'ㅠ',
      'ㅡ',
      'ㅢ',
      'ㅣ'
    ];
    const List<String> finals = [
      '',
      'ㄱ',
      'ㄲ',
      'ㄳ',
      'ㄴ',
      'ㄵ',
      'ㄶ',
      'ㄷ',
      'ㄹ',
      'ㄺ',
      'ㄻ',
      'ㄼ',
      'ㄽ',
      'ㄾ',
      'ㄿ',
      'ㅀ',
      'ㅁ',
      'ㅂ',
      'ㅄ',
      'ㅅ',
      'ㅆ',
      'ㅇ',
      'ㅈ',
      'ㅊ',
      'ㅋ',
      'ㅌ',
      'ㅍ',
      'ㅎ'
    ];

    // 합성 모음이 있을 경우 분해 (예: ㅘ -> ㅗ, ㅏ)
    const Map<String, List<String>> compoundMedials = {
      'ㅘ': ['ㅗ', 'ㅏ'],
      'ㅙ': ['ㅗ', 'ㅐ'],
      'ㅚ': ['ㅗ', 'ㅣ'],
      'ㅝ': ['ㅜ', 'ㅓ'],
      'ㅞ': ['ㅜ', 'ㅔ'],
      'ㅟ': ['ㅜ', 'ㅣ'],
      'ㅢ': ['ㅡ', 'ㅣ'],
    };

    StringBuffer buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      int code = text.codeUnitAt(i);
      // 한글 음절인지 체크
      if (code >= 0xAC00 && code <= 0xD7A3) {
        int syllableIndex = code - 0xAC00;
        int jong = syllableIndex % 28;
        int jung = ((syllableIndex - jong) ~/ 28) % 21;
        int cho = ((syllableIndex - jong) ~/ 28) ~/ 21;

        String initial = initials[cho];
        String medial = medials[jung];
        String finalConsonant = (jong > 0) ? finals[jong] : '';

        buffer.write(initial);
        // 분해된 중성이 합성 모음이면 기본 자모로 다시 분해
        if (compoundMedials.containsKey(medial)) {
          buffer.writeAll(compoundMedials[medial]!);
        } else {
          buffer.write(medial);
        }
        if (finalConsonant.isNotEmpty) {
          buffer.write(finalConsonant);
        }
      } else {
        // 한글이 아닐 경우 그대로 추가 (공백 등)
        buffer.write(text[i]);
      }
    }
    return buffer.toString();
  }

  void filterItems(String query, {String? selectedCategory}) {
    // 검색어의 공백 제거 및 소문자 변환
    query = query.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');

    // 선택된 카테고리에 해당하는 itemID 가져오기
    final selectedCategoryID = _categories.firstWhere(
      (category) => category['Name'] == selectedCategory,
      orElse: () => {'itemID': null},
    )['itemID'];

    // 검색어가 '#'로 시작할 경우와 아닌 경우를 분기하여 처리
    _filteredItem = _items.where((item) {
      final itemData = item.data() as Map<String, dynamic>;
      final itemCategory = itemData['CategoryID'] ?? -1;

      bool matchesSearch;
      if (query.startsWith('#')) {
        // '#' 제거 후 검색어 분해
        final searchQuery = query.substring(1);
        final decomposedSearchQuery = decomposeHangul(searchQuery);

        // 키워드 필드에 대해서 소문자, 공백 제거 후 한글 분해
        final itemKeyword = (itemData['keyword']?.toLowerCase() ?? '')
            .replaceAll(RegExp(r'\s+'), '');
        final decomposedItemKeyword = decomposeHangul(itemKeyword);

        matchesSearch = decomposedItemKeyword.contains(decomposedSearchQuery);
      } else {
        // ItemName의 경우 소문자, 공백 제거 후 한글 분해
        final itemName = (itemData['ItemName']?.toLowerCase() ?? '')
            .replaceAll(RegExp(r'\s+'), '');
        final decomposedName = decomposeHangul(itemName);

        // 검색어 역시 한글 분해하여 순차 검색 적용
        final decomposedQuery = decomposeHangul(query);

        matchesSearch = decomposedName.contains(decomposedQuery);
      }

      final matchesCategory = selectedCategory == null ||
          selectedCategory == '전체' ||
          itemCategory == selectedCategoryID;

      return matchesSearch && matchesCategory;
    }).toList();

    notifyListeners();
  }

  //================ Item 탭바 속성

  int _selectedIndex = 0;
  int get selectedIndex => _selectedIndex;
  int _activeTabCount = 1; // 실제 활성 탭 개수
  int get activeTabCount => _activeTabCount;
  static const int _maxTabs = 10;
  int get maxTabs => _maxTabs;

  TabController? _controller;
  TabController? get controller => _controller;

  List<tabTitleSet> _tabTitles =
      List.generate(_maxTabs, (index) => tabTitleSet(text: ''));
  List<tabTitleSet> get tabTitles => _tabTitles; // Getter 추가
  List<tabViewSet> _tabViews =
      List.generate(_maxTabs, (index) => tabViewSet(first: Container()));
  List<tabViewSet> get tabViews => _tabViews;

  // / 기존의 controller가 있다면 dispose 후 재생성 (여기서 Firestore 구독에는 영향이 없음)
  void initController(TickerProvider vsync) {
    _controller = TabController(length: maxTabs, vsync: vsync);
  }

  void addTab(BuildContext context, String title, Widget first,
      {Widget? all, Widget? second}) {
    // 1️ 이미 동일한 제목의 탭이 존재하는지 확인
    final existingIndex = _tabTitles.indexWhere((tab) => tab.text == title);

    if (existingIndex != -1) {
      // 2️ 존재하면 해당 탭으로 이동
      _controller?.animateTo(existingIndex);
      _selectedIndex = existingIndex;
      notifyListeners();
      return;
    }

    // 3️ 탭 최대 개수 초과 방지
    if (_activeTabCount >= _maxTabs) {
      showOverlayMessage(context, '최대 탭 수 ($_maxTabs개)에 도달했습니다.');
      return;
    }

    // 4️ 새 탭 추가
    _tabTitles[_activeTabCount] = tabTitleSet(text: title);
    _tabViews[_activeTabCount] =
        tabViewSet(first: first, all: all, second: second);
    _activeTabCount++;

    // 5️ 새로 추가한 탭으로 이동
    _controller?.animateTo(_activeTabCount - 1);
    _selectedIndex = _activeTabCount - 1;
    notifyListeners();
  }

  int hoverIndex = -1; // 현재 마우스가 올라간 X 버튼의 인덱스

  void setHoverIndex(int index) {
    hoverIndex = index;
    notifyListeners(); // UI 업데이트
  }

  void removeTab(int index) {
    if (index < 0 || index >= _activeTabCount) return;

    for (int i = index; i < _activeTabCount - 1; i++) {
      _tabTitles[i] = _tabTitles[i + 1];
      _tabViews[i] = _tabViews[i + 1];
    }

    _tabTitles[_activeTabCount - 1] = tabTitleSet(text: '');
    _tabViews[_activeTabCount - 1] = tabViewSet(first: Container());
    _activeTabCount--;

    // 삭제 후 현재 선택된 탭이 유효한 범위 내에 있도록 조정
    int newIndex = _controller?.index ?? 0;
    if (newIndex >= _activeTabCount) newIndex = _activeTabCount - 1;

    _controller?.animateTo(newIndex);
    _selectedIndex = newIndex;
    notifyListeners(); // UI 업데이트를 위해 notifyListeners 호출
  }

  void removeAllTabs() {
    if (_activeTabCount <= 1) return; // 1개 이하라면 실행할 필요 없음

    // 1번(0번 인덱스) 탭을 제외하고 나머지 탭 제거
    _tabTitles = [_tabTitles[0]] + List.filled(9, tabTitleSet(text: ''));
    _tabViews = [_tabViews[0]] + List.filled(9, tabViewSet(first: Container()));

    _activeTabCount = 1; // 1번 탭만 남기므로 활성 탭 수를 1로 설정

    _controller?.animateTo(0); // 1번 탭으로 이동
    notifyListeners(); // UI 업데이트
  }

  /// 탭 선택
  void selectTab(int index) {
    if (_controller == null) return;
    _selectedIndex = index;
    _controller!.animateTo(index);
    notifyListeners();
  }

  void updateTabName(String oldName, String newName) {
    for (var tab in _tabTitles) {
      if (tab.text == oldName) {
        tab.text = newName;
      }
    }
    notifyListeners();
  }

  // searchController 설정정

  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  // 검색어가 변경될 때 알림
  void setSearchText(String text) {
    searchController.text = text.trim();
    notifyListeners();
  }

  // 포커스를 강제로 부여
  void focusSearchField() {
    searchController.clear();
    searchFocusNode.requestFocus();
  }

  // 포커스 해제
  void unfocusSearchField() {
    searchFocusNode.unfocus();
  }

  // 키보드 이벤트 감지를 위한 FocusNode 생성
  final FocusNode keyboardFocusNode = FocusNode();
  // 포커스를 강제로 부여
  void focusKeyboard() {
    keyboardFocusNode.requestFocus();
  }

  // 포커스 해제
  void unfocusKeyboard() {
    keyboardFocusNode.unfocus();
  }

  @override
  void dispose() {
    // Provider 인스턴스가 최종적으로 dispose될 때,
    // Firestore 구독도 함께 취소합니다.
    _itemSubscription?.cancel();
    _categorySubscription?.cancel();
    _fieldSubscription?.cancel();
    // TabController도 함께 정리합니다.
    _controller?.dispose();

    //    searchController
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }
}

class tabTitleSet {
  Icon? icon;
  String text;

  tabTitleSet({this.icon, required this.text});
}

class tabViewSet {
  Widget? all;
  Widget first;
  Widget? second;

  tabViewSet({this.all, required this.first, this.second});
}
