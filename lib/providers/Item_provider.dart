import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mp_db/pages/home.dart';

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
  List<Tab> _tabs = [Tab(text: 'Item List')];
  List<Widget> _tabViews = [Text('Default View')];
  TabController? _controller;
  int _selectedIndex = 0;

  TabController? get controller => _controller;
  List<Tab> get tabs => _tabs;
  List<Widget> get tabViews => _tabViews;
  int get selectedIndex => _selectedIndex;
  int _tabCounter = 0;

  /// vsync가 필요하므로, 각 탭 관련 메서드 호출 시 TickerProvider를 전달해야 합니다.
  void initTabConfiguration(TickerProvider vsync, String title, Widget view) {
    _tabs = [Tab(text: title)];
    _tabViews = [view];
    _selectedIndex = 0;
    _initController(vsync);
    notifyListeners();
  }

  /// 기존의 controller가 있다면 dispose 후 재생성 (여기서 Firestore 구독에는 영향이 없음)
  void _initController(TickerProvider vsync) {
    _controller?.dispose(); // 기존 TabController만 dispose
    _controller = TabController(
      length: _tabs.length,
      vsync: vsync,
      initialIndex: _selectedIndex,
    );
  }

  /// 탭 추가 시 vsync를 받아 새 컨트롤러 생성
  void addTab(String title, Widget view, TickerProvider vsync) {
    final int existingIndex = _tabs.indexWhere((tab) => tab.text == title);
    if (existingIndex != -1) {
      _selectedIndex = existingIndex;
      _controller?.animateTo(existingIndex);
      notifyListeners();
      return;
    }

    _tabs.add(Tab(text: title));
    _tabViews.add(
      KeepAlivePage(
        key: PageStorageKey('$title-$_tabCounter'),
        child: view,
      ),
    );
    _tabCounter++;

    int newIndex = _tabs.length - 1;

    _controller?.dispose();
    // 바로 새 탭 인덱스로 초기화
    _controller = TabController(
      length: _tabs.length,
      vsync: vsync,
      initialIndex: newIndex,
    );
    _selectedIndex = newIndex;
    notifyListeners();
  }

  /// 특정 탭 제거 (인덱스가 유효할 때만)
  void removeTab(int index, TickerProvider vsync) {
    if (index >= 0 && index < _tabs.length) {
      _tabs.removeAt(index);
      _tabViews.removeAt(index);
      // 선택 인덱스가 탭 범위 밖이 되지 않도록 조정
      if (_selectedIndex >= _tabs.length) {
        _selectedIndex = _tabs.length - 1;
      }
      _initController(vsync);
      notifyListeners();
    }
  }

  /// 모든 탭을 초기화할 경우
  void resetTabs(TickerProvider vsync) {
    if (_tabs.isNotEmpty) {
      _tabs = [_tabs.first]; // 0번 탭만 유지
      _tabViews = [_tabViews.first]; // 0번 탭의 View만 유지
    }

    _selectedIndex = 0;
    _initController(vsync);
    notifyListeners();
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
