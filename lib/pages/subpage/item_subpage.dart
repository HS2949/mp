// ignore_for_file: public_member_api_docs, sort_constructors_first, library_private_types_in_public_api, use_super_parameters, non_constant_identifier_names, camel_case_types
import 'package:flutter/material.dart';
import 'package:mp_db/pages/subpage/item_detail_subpage.dart';
import 'package:provider/provider.dart';

import 'package:mp_db/Functions/firestore.dart';
import 'package:mp_db/constants/styles.dart';
import 'package:mp_db/providers/Item_provider.dart';
import 'package:mp_db/utils/widget_help.dart';

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

  late final VoidCallback _searchListener;

  @override
  void initState() {
    super.initState();
    _provider = context.read<ItemProvider>();

    // searchController의 리스너를 별도 변수로 저장
    _searchListener = () {
      _provider.filterItems(
        _provider.searchController.text,
        selectedCategory: selectedCategory,
      );
    };

    _provider.searchController.addListener(_searchListener);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // build가 완료된 후에 상태를 변경하도록 post frame callback 사용
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider.searchController.text = '';
      _provider.filterItems('', selectedCategory: '전체');
    });
  }

  @override
  void dispose() {
    _provider.searchController.removeListener(_searchListener);
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

  bool isHovered = false; // 마우스 오버 상태 변수
  String labelText = 'Search';
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
                  labelText: labelText,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon:
                      ClearButton(controller: _provider.searchController),
                ),
                onChanged: (text) {
                  setState(() {
                    // 검색어가 #으로 시작하면 라벨 변경
                    labelText = text.startsWith('#') ? 'Tag' : 'Search';
                  });
                },
                onTap: () {
                  _provider.selectTab(0); // 포커스될 때 탭을 0번으로 변경
                },
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              flex: 1,
              fit: FlexFit.loose,
              child: Tooltip(
                message: '탭 모두 닫기',
                child: MouseRegion(
                  onEnter: (_) => setState(() => isHovered = true), // 마우스 진입 시
                  onExit: (_) => setState(() => isHovered = false), // 마우스 나갈 시
                  child: ElevatedButton(
                      onPressed: () {
                        _provider.removeAllTabs();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isHovered
                            ? AppTheme.buttonbackgroundColor
                            : AppTheme.buttonlightbackgroundColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Close')),
                ),
              ),
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

    // 빌드 시점에 리스트 정렬 처리 (빌드 도중에 리스트 변경하지 않도록)
    final sortedItems = List.from(filteredDisplayItems)
      ..sort((a, b) {
        final aName =
            (a.data() as Map<String, dynamic>)['ItemName'] ?? '';
        final bName =
            (b.data() as Map<String, dynamic>)['ItemName'] ?? '';
        return koreanCompare(aName, bName);
      });

    return provider.isLoading
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(50.0),
              child: SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  strokeWidth: 4.0,
                ),
              ),
            ),
          )
        : Padding(
            padding: const EdgeInsets.fromLTRB(20, 15, 20, 20),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedItems.length,
              itemBuilder: (context, index) {
                final item = sortedItems[index];
                final itemData = item.data() as Map<String, dynamic>;
                final matchedCategory = provider.categories.firstWhere(
                  (cat) => cat['itemID'] == itemData['CategoryID'],
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
                    title: Text(
                      itemData['ItemName'] ?? 'No Name',
                      style: TextStyle(
                        color: provider.searchController.text.startsWith('#')
                            ? AppTheme.textHintColor
                            : Colors.black,
                        fontSize:
                            provider.searchController.text.startsWith('#')
                                ? 15
                                : 16,
                      ),
                    ),
                    subtitle: Text(
                      itemData['keyword'] ?? '-'.replaceAll(' ', '   '),
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: provider.searchController.text.startsWith('#')
                            ? AppTheme.text6Color
                            : AppTheme.textHintColor,
                        fontSize:
                            provider.searchController.text.startsWith('#')
                                ? 16
                                : 13,
                      ),
                    ),
                    onTap: () {
                      provider.addTab(
                        context,
                        itemData['ItemName'] ?? 'No Name',
                        ItemDetailSubpage(
                          itemId: sortedItems[index].id,
                          viewSelect: 1,
                        ),
                        second: ItemDetailSubpage(
                          itemId: sortedItems[index].id,
                          viewSelect: 2,
                        ),
                        all: ItemDetailSubpage(
                          itemId: sortedItems[index].id,
                          viewSelect: 0,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
  }
}

/// 한글 정렬을 위한 koreanCompare 함수
int koreanCompare(String a, String b) {
  final String aFirst = a.isNotEmpty ? a[0] : '';
  final String bFirst = b.isNotEmpty ? b[0] : '';
  return aFirst.compareTo(bFirst);
}

void showAddItem(BuildContext context, String? itemId) async {
  final TextEditingController nameController = TextEditingController();
  IconLabel selectedIcon = IconLabel.smile;
  ColorLabel selectedColor = ColorLabel.grey;
  final firestoreService = FirestoreService();
  final categories =
      context.read<ItemProvider>().categories.skip(1).toList(); // '전체' 제외
  Map<String, dynamic>? selectedCategory; // 선택되지 않았을 경우 null 가능

  // 편집 모드일 경우 기존 데이터 불러오기
  if (itemId != null && itemId.isNotEmpty) {
    final itemData = await firestoreService.getItemById(
        collectionName: 'Items', documentId: itemId);
    nameController.text = itemData['ItemName'] ?? '';
    selectedCategory = categories.firstWhere(
        (category) => category['itemID'] == itemData['CategoryID'],
        orElse: () => {});
    if (selectedCategory.isNotEmpty) {
      selectedIcon = IconLabel.values.firstWhere(
          (e) => e.label == selectedCategory!['Icon'],
          orElse: () => IconLabel.smile);
      selectedColor = ColorLabel.values.firstWhere(
          (e) => e.label == selectedCategory!['Color'],
          orElse: () => ColorLabel.silver);
    }
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 250),
                child: TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(13),
                    suffixIcon: ClearButton(controller: nameController),
                    labelText: '등록할 상호명',
                    hintText: '예) OO관광지, OO식당, OO호텔, OO차량 ...',
                    filled: true,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    selectedIcon.icon,
                    color: selectedColor.color,
                    size: 40,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: SizedBox(
                      width: 200,
                      child: DropdownMenu<String>(
                        requestFocusOnTap: false,
                        expandedInsets: EdgeInsets.zero,
                        label: const Text('카테고리 선택'),
                        initialSelection: selectedCategory?['Name'],
                        dropdownMenuEntries: categories
                            .map(
                              (category) => DropdownMenuEntry<String>(
                                labelWidget: Text(
                                  category['Name'] ?? '-',
                                  style: AppTheme.textLabelStyle,
                                ),
                                value: category['Name'],
                                leadingIcon: Icon(
                                  IconLabel.values
                                      .firstWhere(
                                          (e) => e.label == category['Icon'],
                                          orElse: () => IconLabel.smile)
                                      .icon,
                                  color: ColorLabel.values
                                      .firstWhere(
                                          (e) => e.label == category['Color'],
                                          orElse: () => ColorLabel.silver)
                                      .color,
                                  size: 20,
                                ),
                                label: category['Name'] ?? '-',
                              ),
                            )
                            .toList(),
                        onSelected: (value) {
                          setState(() {
                            selectedCategory = categories.firstWhere(
                                (category) => category['Name'] == value);

                            selectedIcon = IconLabel.values.firstWhere(
                                (e) => e.label == selectedCategory!['Icon'],
                                orElse: () => IconLabel.smile);
                            selectedColor = ColorLabel.values.firstWhere(
                                (e) => e.label == selectedCategory!['Color'],
                                orElse: () => ColorLabel.silver);
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("Cancel"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty) {
                        showOverlayMessage(context, '상호명을 입력해주세요!');
                        return;
                      }
                      if (selectedCategory == null) {
                        showOverlayMessage(context, '카테고리를 선택해주세요!');
                        return;
                      }

                      if (itemId != null && itemId.isNotEmpty) {
                        await firestoreService.updateItem(
                          collectionName: 'Items',
                          documentId: itemId,
                          updatedData: {
                            'ItemName': nameController.text.trim(),
                            'CategoryID': selectedCategory!['itemID'],
                            'keyword': ''
                          },
                        );

                        showOverlayMessage(
                            context, '${nameController.text}을 수정하였습니다.');
                      } else {
                        await firestoreService.addItem(
                          collectionName: 'Items',
                          data: {
                            'ItemName': nameController.text.trim(),
                            'CategoryID': selectedCategory!['itemID']
                          },
                        );

                        showOverlayMessage(
                            context, '${nameController.text}을 추가하였습니다.');
                      }

                      Navigator.of(context).pop();
                    },
                    child: Text(itemId == null || itemId.isEmpty ? "Add" : "Edit"),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
