import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mp_db/Functions/firestore.dart';
import 'package:mp_db/constants/styles.dart';
import 'package:mp_db/utils/widget_help.dart';

class Item_page extends StatefulWidget {
  const Item_page({super.key});

  @override
  _Item_pageState createState() => _Item_pageState();
}

class _Item_pageState extends State<Item_page> {
  final firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _filteredItem = [];
  List<DocumentSnapshot> _items = [];
  List<Map<String, dynamic>> categories = [];
  bool _isLoading = true;
  IconData? selectedIcon;
  Color? selectedColor;
  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadCategories();
    _searchController.addListener(_filterData);
  }

  Future<void> _loadData() async {
    final snapshot = await firestoreService.getItemsSnapshot('Items').first;
    setState(() {
      _items = snapshot.docs;
      _filteredItem = List.from(_items);
      _isLoading = false;
    });
  }

  Future<void> _loadCategories() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('Categories').get();
    setState(() {
      categories = [
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
      _isLoading = false;
    });
  }

void _filterData() {
  final query = _searchController.text.toLowerCase();

  setState(() {
    // selectedCategory에 해당하는 ID를 찾음
    final selectedCategoryID = categories.firstWhere(
      (category) => category['Name'] == selectedCategory,
      orElse: () => {'itemID': null},
    )['itemID'];

    _filteredItem = _items.where((item) {
      final itemData = item.data() as Map<String, dynamic>;
      final itemName = itemData['ItemName']?.toLowerCase() ?? '';
      final itemCategory = itemData['CategoryID'] ?? -1; // int로 초기값 설정

      // 필터 조건: 검색어와 선택된 카테고리
      final matchesSearch = itemName.contains(query);
      final matchesCategory = selectedCategory == '전체' ||
          selectedCategory == null ||
          itemCategory == int.tryParse(selectedCategoryID?.toString() ?? '');

      return matchesSearch && matchesCategory;
    }).toList();
  });
}



  void _selectCategory(String name) {
    final matchedCategory = categories.firstWhere(
      (category) => category['Name'] == name,
      orElse: () => {'Name': '전체', 'Color': 'Silver', 'Icon': 'List'},
    );

    setState(() {
      selectedCategory = matchedCategory['Name'];
      selectedColor = ColorLabel.values
          .firstWhere((e) => e.label == matchedCategory['Color'],
              orElse: () => ColorLabel.silver)
          .color;
      selectedIcon = IconLabel.values
          .firstWhere((e) => e.label == matchedCategory['Icon'],
              orElse: () => IconLabel.smile)
          .icon;
      _filterData();
    });
  }

  Widget _buildMenuButton(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 40,
      child: MenuAnchor(
        builder: (context, controller, child) {
          return FilledButton.tonal(
            style: ButtonStyle(
              backgroundColor:
                  WidgetStateProperty.all(Colors.grey[200]), // 기본 배경색
              padding: WidgetStateProperty.all(
                EdgeInsets.symmetric(horizontal: 0), // 좌우 여백 설정
              ),
            ),
            onPressed: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(selectedIcon ?? Icons.list,
                    color: selectedColor ?? Colors.grey, size: 16),
                const SizedBox(width: 4),
                Flexible(child: Text(selectedCategory ?? '전체')),
              ],
            ),
          );
        },
        menuChildren: categories.map((category) {
          final name = category['Name'] ?? '-';
          final icon = IconLabel.values
              .firstWhere((e) => e.label == category['Icon'],
                  orElse: () => IconLabel.smile)
              .icon;
          final color = ColorLabel.values
              .firstWhere((e) => e.label == category['Color'],
                  orElse: () => ColorLabel.silver)
              .color;

          return MenuItemButton(
            leadingIcon: Icon(icon, color: color, size: 16),
            child: Text(name),
            onPressed: () {
              _selectCategory(name);
            },
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildMenuButton(context),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: ClearButton(controller: _searchController),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
                    child: ListView.builder(
                      itemCount: _filteredItem.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItem[index];
                        final itemData = item.data() as Map<String, dynamic>;
                        final matchedCategory = categories.firstWhere(
                          (cat) =>
                              int.parse(cat['itemID']) ==
                              itemData['CategoryID'],
                          orElse: () => {'Color': 'Silver', 'Icon': 'List'},
                        );

                        final color = ColorLabel.values
                            .firstWhere(
                                (e) => e.label == matchedCategory['Color'],
                                orElse: () => ColorLabel.silver)
                            .color;
                        final icon = IconLabel.values
                            .firstWhere(
                                (e) => e.label == matchedCategory['Icon'],
                                orElse: () => IconLabel.smile)
                            .icon;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 5.0),
                          child: ListTile(
                            leading: Icon(icon, color: color),
                            title: Text(
                              itemData['ItemName'] ?? 'No Name',
                              style: AppTheme.titleMedium,
                            ),
                            subtitle: Text('ID: ${item.id}',
                                style: AppTheme.bodySmall),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {},
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    FiDeleteDialog(
                                      context: context,
                                      collectionName: 'Items',
                                      documentId: item.id,
                                      firestoreService: firestoreService,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
