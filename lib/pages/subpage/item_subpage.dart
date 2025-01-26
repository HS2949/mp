import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mp_db/Functions/firestore.dart';
import 'package:mp_db/constants/styles.dart';
import 'package:mp_db/providers/Item_provider.dart';
import 'package:mp_db/utils/two_line.dart';
import 'package:mp_db/utils/widget_help.dart';
import 'package:provider/provider.dart';

class Item_page extends StatefulWidget {
  const Item_page({super.key});

  @override
  _Item_pageState createState() => _Item_pageState();
}

class _Item_pageState extends State<Item_page> {
  final firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> categories = [];

  IconData? selectedIcon;
  Color? selectedColor;
  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    // _searchController.addListener(_filterData);
    _searchController.addListener(() {
      final provider = context.read<ItemProvider>();
      provider.filterItems(_searchController.text);
    });

    _initializeData();
  }

  Future<void> _initializeData() async {
    final provider = context.read<ItemProvider>();
    await provider.loadItems();
    await provider.loadCategories();

    setState(() {
      categories = provider.categories;
    });
  }

  // void _filterData() {
  //   final query = _searchController.text.toLowerCase();

  //   setState(() {
  //     // selectedCategory에 해당하는 ID를 찾음
  //     final selectedCategoryID = categories.firstWhere(
  //       (category) => category['Name'] == selectedCategory,
  //       orElse: () => {'itemID': null},
  //     )['itemID'];
  //   });
  // }

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

      // 필터링 로직 호출
      final provider = context.read<ItemProvider>();
      provider.filterItems(
        _searchController.text, // 검색어와
        selectedCategory: selectedCategory, // 선택된 카테고리를 기준으로 필터링
      );
    });
  }

  Widget _CategoryButton(BuildContext context) {
    final provider = context.watch<ItemProvider>();
    final categories = provider.categories;

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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CategoryButton(context),
              const SizedBox(width: 10),
              Flexible(
                child: SizedBox(
                  width: 350,
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
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class First_Item_Page extends StatelessWidget {
  const First_Item_Page({
    super.key,
    required this.showNavBottomBar,
    required this.scaffoldKey,
    required this.showSecondList,
  });

  final bool showNavBottomBar;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final bool showSecondList;

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      //위젯 입력

      if (!showSecondList) ...[
        ItemList(filterType: 0)
      ] else ...[
        ItemList(filterType: 1)
      ]
    ];
    List<double?> heights = List.filled(children.length, null);

    // Fully traverse this list before moving on.
    return FocusTraversalGroup(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: showSecondList
                ? const EdgeInsetsDirectional.only(end: smallSpacing)
                : EdgeInsets.zero,
            sliver: SliverList(
              delegate: BuildSlivers(
                heights: heights,
                builder: (context, index) {
                  return CacheHeight(
                    heights: heights,
                    index: index,
                    child: children[index],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Second_Item_Page extends StatelessWidget {
  const Second_Item_Page({
    super.key,
    required this.scaffoldKey,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [ItemList(filterType: 2)];
    List<double?> heights = List.filled(children.length, null);

    // Fully traverse this list before moving on.
    return FocusTraversalGroup(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsetsDirectional.only(end: smallSpacing),
            sliver: SliverList(
              delegate: BuildSlivers(
                heights: heights,
                builder: (context, index) {
                  return CacheHeight(
                    heights: heights,
                    index: index,
                    child: children[index],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ItemList extends StatefulWidget {
  final int filterType; // 필터 타입 인수 추가

  const ItemList({super.key, required this.filterType});

  @override
  _ItemListState createState() => _ItemListState();
}

class _ItemListState extends State<ItemList> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ItemProvider>();
    final filteredItems = provider.filteredItem;
    final categories = provider.categories;
    final isLoading = provider.isLoading;

    // 필터에 따라 표시할 아이템 리스트 계산
    List filteredDisplayItems;
    if (widget.filterType == 0) {
      filteredDisplayItems = filteredItems;
    } else if (widget.filterType == 1) {
      filteredDisplayItems =
          filteredItems.sublist(0, (filteredItems.length / 2).ceil());
    } else {
      filteredDisplayItems =
          filteredItems.sublist((filteredItems.length / 2).ceil());
    }

    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 20),
              child: ListView.builder(
                shrinkWrap: true, // ListView 크기를 자식 위젯에 맞춤
                physics: const NeverScrollableScrollPhysics(), // 스크롤 비활성화
                itemCount: filteredDisplayItems.length,
                itemBuilder: (context, index) {
                  final item = filteredDisplayItems[index];
                  final itemData = item.data() as Map<String, dynamic>;
                  final matchedCategory = categories.firstWhere(
                    (cat) => int.parse(cat['itemID']) == itemData['CategoryID'],
                    orElse: () => {'Color': 'Silver', 'Icon': 'List'},
                  );

                  final color = ColorLabel.values
                      .firstWhere((e) => e.label == matchedCategory['Color'],
                          orElse: () => ColorLabel.silver)
                      .color;
                  final icon = IconLabel.values
                      .firstWhere((e) => e.label == matchedCategory['Icon'],
                          orElse: () => IconLabel.smile)
                      .icon;

                  return Card(
                    child: ListTile(
                      leading: Icon(icon, color: color),
                      title: Text(itemData['ItemName'] ?? 'No Name'),
                    ),
                  );
                },
              ),
            ),
          );
  }
}
