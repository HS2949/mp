// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mp_db/pages/home.dart';
import 'package:mp_db/pages/subpage/item_detail_subpage.dart';
import 'package:provider/provider.dart';

import 'package:mp_db/Functions/firestore.dart';
import 'package:mp_db/constants/styles.dart';
import 'package:mp_db/pages/dialog/item_detail_dialog.dart';
import 'package:mp_db/providers/Item_provider.dart';
import 'package:mp_db/utils/widget_help.dart';

import '../../repositories/Item_detail_repository.dart';

class Item_page extends StatefulWidget {
  final EdgeInsets padding; // padding 인수 추가
  const Item_page({
    super.key,
    this.padding = const EdgeInsets.all(0), // 기본값을 EdgeInsets.all(0)으로 설정
  });
  @override
  _Item_pageState createState() => _Item_pageState();
}

class _Item_pageState extends State<Item_page> with TickerProviderStateMixin {
  final firestoreService = FirestoreService();

  IconData? selectedIcon;
  Color? selectedColor;
  String? selectedCategory;
  late ItemProvider _provider;

  @override
  @override
  void initState() {
    super.initState();
    _provider = context.read<ItemProvider>();

    // 검색어 변경 감지 및 필터링 적용
    _provider.searchController.addListener(() {
      _provider.filterItems(
        _provider.searchController.text,
        selectedCategory: selectedCategory,
      );
    });
  }

  void didChangeDependencies() {
    super.didChangeDependencies();

    // 네비게이션에서 돌아올 때마다 필터 초기화
    _provider.searchController.text = '';
    _provider.filterItems('', selectedCategory: '전체');
  }

  @override
  void dispose() {
    _provider.searchController.removeListener(() {});
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
        _provider.searchController.text, // 검색어와
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
                  _provider.selectTab(0); // 카테고리 버튼 클릭 시 0번 탭 선택
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
    return Container(
      color: Colors.grey[50],
      width: 500,
      child: Padding(
        padding: widget.padding,
        child: Row(
          children: [
            Flexible(flex: 1, child: _CategoryButton(context)),
            const SizedBox(width: 10),
            Flexible(
              fit: FlexFit.tight,
              flex: 3,
              child: TextField(
                controller: _provider.searchController,
                focusNode: _provider.searchFocusNode,
                decoration: InputDecoration(
                  labelText: 'Search',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon:
                      ClearButton(controller: _provider.searchController),
                ),
                onTap: () {
                  _provider.selectTab(0); // 포커스될 때 탭을 0번으로 변경
                },
              ),
            ),
            SizedBox(width: 10),
            Flexible(
              flex: 1,
              fit: FlexFit.loose,
              child: ElevatedButton(
                  onPressed: () {
                    _provider.removeAllTabs(); // Close 버튼 클릭 시에도 0번 탭으로 변경 가능
                    // _provider.toggleSecondTab(false); // 두 번째 탭 활성화
                  },
                  child: Text('Close')),
            )
          ],
        ),
      ),
    );
  }
}

class ItemList extends StatefulWidget {
  final int filterType; // 필터 타입 인수 추가

  const ItemList({
    Key? key,
    required this.filterType,
  }) : super(key: key);

  @override
  _ItemListState createState() => _ItemListState();
}

class _ItemListState extends State<ItemList> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ItemProvider>();
    final filteredItems = provider.filteredItem;
    final ItemDetailRepository repository = ItemDetailRepository();

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
                        // addTab 호출 시 this는 TickerProviderStateMixin을 구현하고 있음
                        provider.addTab(
                          context,
                          itemData['ItemName'] ?? 'No Name',
                          ItemDetailFirst(
                            itemId: filteredDisplayItems[index].id,
                            isFirstView: true,
                          ),
                          second: ItemDetailFirst(
                            itemId: filteredDisplayItems[index].id,
                            isFirstView: false,
                          ),
                        );

                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (context) => ItemDetailFirst(
                        //     itemId: filteredDisplayItems[index].id,
                        //   ),
                        //   ),
                        // );
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
