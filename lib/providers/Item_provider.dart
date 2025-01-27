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

  Future<void> loadSnapshot() async {
    _isLoading = true;
    notifyListeners();

    // 병렬로 데이터 가져오기
    final itemsSnapshot = FirebaseFirestore.instance.collection('Items').get();
    final categoriesSnapshot =
        FirebaseFirestore.instance.collection('Categories').get();
    final fieldsSnapshot =
        FirebaseFirestore.instance.collection('Fields').get();

    final results =
        await Future.wait([itemsSnapshot, categoriesSnapshot, fieldsSnapshot]);

    // Process Items
    _items = results[0].docs;
    _filteredItem = List.from(_items);

    // Process Categories
    _categories = [
      {'itemID': '0', 'Name': '전체', 'Color': 'Silver', 'Icon': 'List'},
      ...results[1].docs.map((doc) {
        final data = doc.data();
        return {
          'itemID': doc.id,
          'Name': data['CategoryName'],
          'Color': data['Color'],
          'Icon': data['Icon'],
        };
      }).toList(),
    ];

    // Process Fields
    _fields = results[2].docs;

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
}
