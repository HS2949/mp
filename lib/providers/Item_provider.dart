// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ItemProvider extends ChangeNotifier {
  List<DocumentSnapshot> _items = [];
  List<DocumentSnapshot> get items => _items;

  List<DocumentSnapshot> _filteredItem = [];
  List<DocumentSnapshot> get filteredItem => _filteredItem;

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> get categories => _categories;

  List<DocumentSnapshot> _fields = [];
  List<DocumentSnapshot> get fields => _fields;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // StreamSubscriptions for real-time listeners
  StreamSubscription? _itemSubscription;
  StreamSubscription? _categorySubscription;
  StreamSubscription? _fieldSubscription;

  void loadSnapshot() {
    _isLoading = true;
    notifyListeners();

    // Real-time Items updates
    _itemSubscription = FirebaseFirestore.instance
        .collection('Items')
        .snapshots()
        .listen((snapshot) {
      _items = snapshot.docs;
      _filteredItem = List.from(_items); // Update filtered items
      notifyListeners();
    });

    // Real-time Categories updates
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
      notifyListeners();
    });

    // Real-time Fields updates
    _fieldSubscription = FirebaseFirestore.instance
        .collection('Fields')
        .snapshots()
        .listen((snapshot) {
      _fields = snapshot.docs;
      notifyListeners();
    });

    _isLoading = false;
    notifyListeners();
  }

  void filterItems(String query, {String? selectedCategory}) {
    query = query.toLowerCase();
    final selectedCategoryID = _categories.firstWhere(
      (category) => category['Name'] == selectedCategory,
      orElse: () => {'itemID': null},
    )['itemID'];

    _filteredItem = _items.where((item) {
      final itemData = item.data() as Map<String, dynamic>;
      final itemName = itemData['ItemName']?.toLowerCase() ?? '';
      final itemCategory = itemData['CategoryID'] ?? -1;

      final matchesSearch = itemName.contains(query);
      final matchesCategory = selectedCategory == null ||
          selectedCategory == '전체' ||
          itemCategory == int.tryParse(selectedCategoryID?.toString() ?? '');

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

  // 🔹 Snackbar를 띄우기 위한 콜백 (외부에서 설정 가능)
  void Function(BuildContext, String)? showSnackbar;
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
    if (showSnackbar != null) {
      showSnackbar!(context, '최대 탭 수 ($_maxTabs개)에 도달했습니다.');
    }
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

  // searchController 설정정

  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  // 검색어가 변경될 때 알림
  void setSearchText(String text) {
    searchController.text = text;
    notifyListeners();
  }

  // 포커스를 강제로 부여
  void focusSearchField() {
    searchFocusNode.requestFocus();
  }

  // 포커스 해제
  void unfocusSearchField() {
    searchFocusNode.unfocus();
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
