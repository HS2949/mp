// ignore_for_file: public_member_api_docs, sort_constructors_first, library_private_types_in_public_api, use_super_parameters, non_constant_identifier_names, camel_case_types
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      if (_provider.selectedIndex != 0) {
        _provider.selectTab(0); // 현재 탭이 0번이 아니면 0번 탭 선택
      }
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
    // if (!_hasInitializedDependencies) {
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     if (_provider.searchController.text.isEmpty) {
    //       _provider.filterItems('', selectedCategory: '전체');
    //     }
    //   });
    //   _hasInitializedDependencies = true;
    // }
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

  // 클립보드에서 텍스트 가져오기
  Future<void> _pasteFromClipboard() async {
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      setState(() {
        _provider.selectTab(0);
        _provider.searchController.text = data.text!;
      });
    }
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
            Flexible(
                flex: 1,
                child: GestureDetector(
                    onDoubleTap: _pasteFromClipboard,
                    onSecondaryTap: _pasteFromClipboard,
                    child: _CategoryButton(context))),
            const SizedBox(width: 10),
            Flexible(
              fit: FlexFit.tight,
              flex: 3,
              child: Tooltip(
                message: '# 입력 시 : 태그 검색\n오른쪽 버튼 : 클립보드 붙여넣기',
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onDoubleTap: () {
                    setState(() {
                      _provider.selectTab(0);
                      _provider.searchController.text = "";
                    });
                  },
                  child: TextField(
                    controller: _provider.searchController,
                    focusNode: _provider.searchFocusNode,
                    decoration: InputDecoration(
                      labelText: labelText,
                      border: const OutlineInputBorder(),
                      prefixIcon:
                          // const Icon(Icons.search),
                          IconButton(
                        icon: Icon(Icons.search,
                            color: AppTheme.textLabelColor, size: 15),
                        focusNode: FocusNode(skipTraversal: true),
                        // padding: EdgeInsets.zero, // 내부 여백 제거
                        constraints: BoxConstraints(), // 최소 크기 제한 제거
                        onPressed: _pasteFromClipboard,
                      ),
                      suffixIcon:
                          ClearButton(controller: _provider.searchController),
                    ),
                    onChanged: (text) {
                      setState(() {
                        labelText = text.startsWith('#') ? 'Tag' : 'Search';
                      });
                    },
                    onTap: () {
                      _provider.selectTab(0);
                    },
                  ),
                ),
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
                        // 첫 번째 카테고리를 자동으로 선택
                        if (_provider.categories.isNotEmpty) {
                          final firstCategory = _provider.categories.first;
                          final name = firstCategory['Name'] ?? '전체';
                          _selectCategory(name);
                        }
                        _provider.searchController.clear();
                        // 검색창에 포커스를 줌
                        FocusScope.of(context)
                            .requestFocus(_provider.searchFocusNode);
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
        final aName = (a.data() as Map<String, dynamic>)['ItemName'] ?? '';
        final bName = (b.data() as Map<String, dynamic>)['ItemName'] ?? '';
        return koreanCompare(aName, bName);
      });

    return provider.isLoading
        ? (widget.filterType == 1
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(50.0),
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: Image.asset(
                      'assets/images/loading.gif',
                      width: 50,
                      height: 50,
                      fit: BoxFit.contain, // 이미지 비율 유지
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink())
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
                            ? AppTheme.textLabelColor
                            : Colors.black,
                        fontSize: provider.searchController.text.startsWith('#')
                            ? 16
                            : 16,
                      ),
                    ),
                    subtitle: RichText(
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        children: _buildKeywordSpans(
                          itemData['keyword'] ?? '-'.replaceAll(' ', '   '),
                          provider.searchController.text.replaceAll('#',''),
                        ),
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
                      provider.focusKeyboard();
                    },
                  ),
                );
              },
            ),
          );
  }
}

// 텍스트 색상 변경 (태그 검색 시)
List<TextSpan> _buildKeywordSpans(String fullText, String searchText) {
  // 검색어가 비어있거나 전체 텍스트에 포함되지 않는 경우
  if (searchText.isEmpty || !fullText.contains(searchText)) {
    return [
      TextSpan(
        text: fullText,
        style: TextStyle(color: AppTheme.textHintColor, fontSize: 13),
      ),
    ];
  }

  List<TextSpan> spans = [];
  int startIndex = fullText.indexOf(searchText);

  // 검색어 앞의 텍스트 (기본 색상)
  if (startIndex > 0) {
    spans.add(TextSpan(
      text: fullText.substring(0, startIndex),
      style: TextStyle(color: AppTheme.textHintColor, fontSize: 13),
    ));
  }

  // 검색어와 일치하는 부분 (강조 색상)
  spans.add(TextSpan(
    text: searchText,
    style: TextStyle(color: AppTheme.text6Color, fontSize: 13),
  ));

  // 검색어 이후의 텍스트 (기본 색상)
  final endIndex = startIndex + searchText.length;
  if (endIndex < fullText.length) {
    spans.add(TextSpan(
      text: fullText.substring(endIndex),
      style: TextStyle(color: AppTheme.textHintColor, fontSize: 13),
    ));
  }

  return spans;
}

/// 한글 정렬을 위한 koreanCompare 함수
int koreanCompare(String a, String b) {
  final String aFirst = a.isNotEmpty ? a[0] : '';
  final String bFirst = b.isNotEmpty ? b[0] : '';
  return aFirst.compareTo(bFirst);
}

Future<String?> showAddItem(BuildContext context, String? itemId) async {
  final itemProvider = context.read<ItemProvider>();
  // 1. nameController의 초기값을 프로바이더의 searchController 값으로 설정하고 커서를 텍스트 끝으로 위치시킴
  final initialText = itemProvider.searchController.text;
  final TextEditingController nameController =
      TextEditingController(text: initialText);
  nameController.selection = TextSelection.fromPosition(
    TextPosition(offset: nameController.text.length),
  );

  final FocusNode nameFocusNode = FocusNode();
  IconLabel selectedIcon = IconLabel.smile;
  ColorLabel selectedColor = ColorLabel.grey;
  final firestoreService = FirestoreService();
  final categories = itemProvider.categories.skip(1).toList(); // '전체' 제외
  Map<String, dynamic>? selectedCategory; // 선택되지 않았을 경우 null 가능
  late final itemData;

  // 편집 모드일 경우 기존 데이터 불러오기
  if (itemId != null && itemId.isNotEmpty) {
    itemData = await firestoreService.getItemById(
        collectionName: 'Items', documentId: itemId);
    nameController.text = itemData['ItemName'] ?? '';
    // 기존 데이터를 불러온 후에도 커서를 텍스트 끝으로 위치시킴
    nameController.selection = TextSelection.fromPosition(
      TextPosition(offset: nameController.text.length),
    );

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

  return await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          // 2. 자동 포커스 코드를 제거 (초기 텍스트와 커서 위치가 이미 설정되었으므로)
          return Padding(
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
                    focusNode: nameFocusNode,
                    autofocus: true, // 자동 포커스 속성 추가
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

                          final String oldName = itemData['ItemName'];
                          final String newName = nameController.text.trim();

                          if (oldName != newName) {
                            // 변경된 이름을 탭에도 반영
                            context
                                .read<ItemProvider>()
                                .updateTabName(oldName, newName);

                            //그룹(폴더명)이 변경되었으면 Files 컬렉션 업데이트
                            QuerySnapshot filesSnapshot =
                                await FirebaseFirestore.instance
                                    .collection('files')
                                    .where('folder',
                                        isGreaterThanOrEqualTo:
                                            "uploads/${oldName}")
                                    .where('folder',
                                        isLessThan: "uploads/${oldName}\uf8ff")
                                    .get();

                            WriteBatch batch =
                                FirebaseFirestore.instance.batch();

                            for (var doc in filesSnapshot.docs) {
                              String oldFolderPath = doc['folder'];
                              String newFolderPath = oldFolderPath.replaceFirst(
                                  "uploads/${oldName}", "uploads/${newName}");

                              // print(
                              //     "변경 전: $oldFolderPath → 변경 후: $newFolderPath"); // ✅ 확인용

                              if (oldFolderPath != newFolderPath) {
                                // ✅ 변경된 경우만 업데이트
                                batch.update(
                                    doc.reference, {'folder': newFolderPath});
                              } else {
                                print("❌ 변경되지 않음: $oldFolderPath");
                              }
                            }

                            try {
                              await batch.commit();
                              // print("✅ 폴더명 변경 성공!");
                            } catch (e) {
                              print("❌ batch commit 에러: $e");
                            }
                          }

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

                          // 검색창에 입력값을 설정
                          itemProvider.searchController.text =
                              nameController.text;
                        }

                        Navigator.of(context)
                            .pop(nameController.text.trim()); // ✅ 입력값 반환
                      },
                      child: Text(
                          itemId == null || itemId.isEmpty ? "Add" : "Edit"),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
