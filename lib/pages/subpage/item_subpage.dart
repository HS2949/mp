import 'package:flutter/material.dart';
import 'package:mp_db/Functions/firestore.dart';
import 'package:mp_db/constants/styles.dart';
import 'package:mp_db/pages/dialog/item_detail_dialog.dart';
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

  IconData? selectedIcon;
  Color? selectedColor;
  String? selectedCategory;
  late ItemProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = context.read<ItemProvider>(); // 한 번만 할당
    // _searchController.addListener(() {
    //   _provider.filterItems(_searchController.text);
    // });

    // 검색어 또는 선택된 카테고리가 변경될 때 필터링
    _searchController.addListener(() {
      _provider.filterItems(
        _searchController.text,
        selectedCategory: selectedCategory ?? '전체',
      );
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(() {}); // 리스너 제거
    _searchController.dispose();
    super.dispose();
  }

  void _selectCategory(String name) {
    final matchedCategory = _provider.categories.firstWhere(
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
      _provider.filterItems(
        _searchController.text, // 검색어와
        selectedCategory: selectedCategory, // 선택된 카테고리를 기준으로 필터링
      );
    });
  }

  Widget _CategoryButton(BuildContext context) {
    return Consumer<ItemProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return SizedBox(
            width: 80,
            height: 40,
            child: Center(child: CircularProgressIndicator()), // 로딩 중 표시
          );
        }

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
                    const EdgeInsets.symmetric(horizontal: 0), // 좌우 여백 설정
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
            menuChildren: provider.categories.map((category) {
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
      },
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
    // final provider = context.watch<ItemProvider>();
    // final filteredItems = provider.filteredItem;
    // final categories = provider.categories;
    // final isLoading = provider.isLoading;

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

    return provider.isLoading
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
                  final matchedCategory = provider.categories.firstWhere(
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ItemDetailScreen(
                              itemId: filteredDisplayItems[index].id,
                              // itemData: itemData,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          );
  }
}

void showAddItem(BuildContext context) {
  // _nameController.clear();
  // _locationController.clear();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            // controller: _nameController,
            decoration: const InputDecoration(labelText: 'Item Name'),
          ),
          const SizedBox(height: 10),
          TextField(
            // controller: _locationController,
            decoration: const InputDecoration(labelText: 'Location'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {},
            // onPressed: () {
            //   if (_nameController.text.isNotEmpty &&
            //       _locationController.text.isNotEmpty &&
            //       selectedCategory != null) {
            //     addItem(selectedCategory!, _nameController.text,
            //             _locationController.text)
            //         .then((_) => Navigator.pop(context))
            //         .catchError((error) {
            //       print('Error adding item: $error');
            //     });
            //   }
            // },
            child: const Text('Add Item'),
          ),
        ],
      ),
    ),
  );
}
