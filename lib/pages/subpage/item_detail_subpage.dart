import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mp_db/Functions/firestore.dart';
import 'package:mp_db/constants/styles.dart';
import 'package:mp_db/providers/Item_provider.dart';
import 'package:mp_db/utils/widget_help.dart';
import 'package:provider/provider.dart';

import '../../providers/Item_detail/Item_detail_provider.dart';
import '../../providers/Item_detail/Item_detail_state.dart';
import '../../models/item_model.dart';

class ItemDetailSubpage extends StatefulWidget {
  const ItemDetailSubpage(
      {super.key, required this.itemId, required this.viewSelect});

  final String itemId;
  final int viewSelect; // 🔹 true: fields 표시 / false: sub_items 표시

  @override
  State<ItemDetailSubpage> createState() => _ItemDetailSubpageState();
}

class _ItemDetailSubpageState extends State<ItemDetailSubpage> {
  final FocusNode _focusNode = FocusNode();
  late final ItemProvider provider;
  final firestoreService = FirestoreService(); // Firestore 클래스 인스턴스 생성

  @override
  void initState() {
    super.initState();
    provider = Provider.of<ItemProvider>(context, listen: false);

    // 🔹 Firestore 조회를 한 번만 수행 (ID 변경 시만 다시 실행)
    Future.microtask(() {
      Provider.of<ItemDetailProvider>(context, listen: false)
          .listenToItemDetail(itemId: widget.itemId);
    });

    // // 🔹 initState에서 포커스 요청
    // Future.delayed(Duration(milliseconds: 100), () {
    //   FocusScope.of(context).requestFocus(_focusNode);
    // });
  }

  @override
  void dispose() {
    Provider.of<ItemDetailProvider>(context, listen: false)
        .cancelSubscription(widget.itemId);
    _focusNode.dispose();
    super.dispose();
  }

  /// ESC 키와 모바일 뒤로가기 버튼 클릭 시 동일한 동작 수행bool _isClosing = false; // 중복 호출 방지 플래그
  void _handleCloseTab() {
    if (provider.selectedIndex > 0) {
      provider.removeTab(provider.selectedIndex);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // // 🔹 키보드 입력을 항상 받을 수 있도록 설정
    // if (provider.selectedIndex > 0) {
    //   Future.microtask(() => FocusScope.of(context).requestFocus(_focusNode));
    // }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ItemDetailProvider>().getState(widget.itemId);
    final itemData =
        context.watch<ItemDetailProvider>().getItemData(widget.itemId);

    if (state.itemDetailStatus == ItemDetailStatus.loading) {
      return widget.viewSelect < 2
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(50.0),
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    strokeWidth: 4.0,
                  ),
                ),
              ),
            )
          : SizedBox.shrink();
    }

    if (state.itemDetailStatus == ItemDetailStatus.error) {
      return widget.viewSelect < 2
          ? Padding(
              padding: const EdgeInsets.all(50.0),
              child: Text('에러 발생: ${state.error.message}',
                  style: const TextStyle(color: Colors.red)),
            )
          : SizedBox.shrink();
    }

    return itemData == null
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
        : widget.viewSelect < 2
            ? _buildFirstView(itemData) // 0, 1
            : _buildSecondView(itemData); //2
  }

  /// 🔹 `first` UI - fields 표시
  Widget _buildFirstView(Item itemData) {
    final matchedCategory = provider.categories.firstWhere(
      (cat) => cat['itemID'] == itemData.categoryID,
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

    final actions = [
      IconButton(
        icon: const Icon(Icons.add),
        onPressed: () async {
          // 다이얼로그를 열고 값 입력 및 선택
          await _showAddDialog(context, provider, widget.itemId);
        },
      ),
      IconButton(icon: const Icon(Icons.attach_file), onPressed: () {}),
      IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
    ];

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          // _handleCloseTab(); //  ESC 키와 동일한 동작 수행
          provider.selectTab(0);
        }
      },
      child: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 50),
                SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText('${matchedCategory['Name']}',
                        style: AppTheme.textHintTextStyle),
                    SelectableText(itemData.itemName,
                        style: AppTheme.titleLargeTextStyle),
                  ],
                ),
              ],
            ),
            leading: const BackButton(),
            actions: actions,
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _fieldDefault(itemData),
                widget.viewSelect == 0
                    ? _buildSecondView(itemData)
                    : SizedBox.shrink()
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldDefault(Item itemData) {
    final Map<String, Map<String, dynamic>> fields =
        context.read<ItemProvider>().fieldMappings;
    final itemFieldEntries = itemData.fields.entries.toList();

    itemFieldEntries.sort((entryA, entryB) {
      final orderA =
          int.tryParse(fields[entryA.key]?['FieldOrder']?.toString() ?? '0') ??
              0;
      final orderB =
          int.tryParse(fields[entryB.key]?['FieldOrder']?.toString() ?? '0') ??
              0;
      return orderA.compareTo(orderB);
    });

    final sortedItemFields = Map<String, dynamic>.fromEntries(itemFieldEntries);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(5, 5, 5, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Flexible(
                  child: Wrap(
                    children: [
                      SelectableText(
                        itemData.itemTag,
                        style: AppTheme.tagTextStyle,
                        // maxLines: item.itemTag.length > 20 ? 2 : 1,
                        textAlign: TextAlign.start,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  constraints: BoxConstraints(
                    minWidth: 16, // 최소 너비 설정
                    minHeight: 16, // 최소 높이 설정
                  ),
                  icon: Icon(
                    Icons.edit,
                    size: 10,
                    color: AppTheme.toolColor,
                  ),
                  onPressed: () {
                    _showEditDialog(context, 'keyword', '태그', itemData.itemTag,
                        itemData.id);
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 15),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Wrap(
                spacing: 2.0, // 가로 간격
                runSpacing: 0.0, // 세로 간격
                children: [
                  for (var entry in sortedItemFields.entries)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final itemProvider = context.read<ItemProvider>();

                        // 🔹 영어 Key → 한글 Key 변환
                        final String label = itemProvider
                                .fieldMappings[entry.key]?['FieldName'] ??
                            entry.key;
                        final int maxLineLength = entry.value
                            .split(';') // ";"로 나눔
                            .map((e) => e.trim().length) // 각 줄의 길이를 계산
                            .reduce((a, b) => a > b ? a : b); // 가장 긴 줄의 길이를 계산

                        final dynamicWidth = (maxLineLength * 14.0)
                            .clamp(150.0, constraints.maxWidth * 1.0);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 15.0),
                          child: Card(
                            elevation: 0,
                            // shape: RoundedRectangleBorder(
                            //   borderRadius: BorderRadius.circular(12.0),
                            // ),
                            child: Container(
                              width: dynamicWidth,
                              // padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      SelectableText(label,
                                          style: AppTheme.fieldLabelTextStyle),
                                      SizedBox(
                                        width: 20, // 원하는 너비
                                        height: 20, // 원하는 높이
                                        child: IconButton(
                                          padding: EdgeInsets.zero, // 기본 패딩 제거
                                          constraints: BoxConstraints(
                                            minWidth: 16, // 최소 너비 설정
                                            minHeight: 16, // 최소 높이 설정
                                          ),
                                          tooltip: "Edit",
                                          icon: Icon(
                                            Icons.edit,
                                            size: 10, // 아이콘 크기 조절
                                            color: AppTheme.toolColor,
                                          ),
                                          onPressed: () {
                                            _showEditDialog(
                                                context,
                                                entry.key,
                                                itemProvider.fieldMappings[entry
                                                        .key]?['FieldName'] ??
                                                    entry.key,
                                                entry.value,
                                                itemData.id);
                                          },
                                        ),
                                      )
                                    ],
                                  ),
                                  SizedBox(height: 5),
                                  TextField(
                                    controller: TextEditingController(
                                        text: entry.value),
                                    style: entry.value.length > 20
                                        ? AppTheme.bodySmallTextStyle // 많은 글자
                                        : AppTheme.bodySmallTextStyle, // 적은 글자
                                    readOnly: true,
                                    maxLines: null,
                                    decoration: InputDecoration(
                                      filled: false,
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                      isDense: true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  ///==============================================================================================
  /// 🔹 `second` UI - sub_items 표시
  Widget _buildSecondView(Item item) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🔹 하위 아이템 목록',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            for (var subItem in item.subItems)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🔹 ${subItem.id}'),
                  for (var entry in subItem.fields.entries)
                    Text('  • ${entry.key}: ${entry.value}'),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, String key, String name,
      String value, String itemId) {
    TextEditingController textController = TextEditingController(text: value);
    final firestoreService = FirestoreService(); // Firestore 클래스 인스턴스 생성

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: SizedBox(
            width: 400,
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '항목 편집',
                    style: AppTheme.appbarTitleTextStyle,
                  ),
                  SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () async {
                        FiDeleteDialog(
                            context: context,
                            deleteFunction: () async =>
                                firestoreService.deleteKeywordValue(
                                  itemId,
                                  key,
                                ),
                            shouldCloseScreen: true);
                      },
                      icon: Icon(Icons.delete_forever_outlined), // 🔹 삭제 아이콘 적용
                      tooltip: "삭제", // 🔹 접근성을 위한 툴팁 추가
                    ),
                  ),
                  TextField(
                    controller: TextEditingController(text: name), // 🔹 초기 값 설정
                    decoration: InputDecoration(
                      labelText: 'Edit Field',
                      labelStyle: AppTheme.textLabelStyle, // 🔹 기존 스타일 적용
                      filled: false,
                      enabled: false,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: AppTheme.buttonlightbackgroundColor),
                        borderRadius: BorderRadius.circular(8),
                      ), // 기본 테두리 스타일 추가
                    ),
                    style: AppTheme.fieldLabelTextStyle, // 🔹 텍스트 스타일 유지
                    readOnly: true, // 🔹 편집 불가능하게 설정
                  ),
                  SizedBox(height: 10),
                  Container(
                    constraints: BoxConstraints(
                      maxHeight: 200, // 최대 높이, 이후 스크롤롤
                    ),
                    child: Scrollbar(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(0),
                        child: TextField(
                          controller: textController,
                          decoration: InputDecoration(
                            labelText: key,
                            border: OutlineInputBorder(),
                          ),
                          keyboardType:
                              TextInputType.multiline, // 🔹 키보드 유형을 멀티라인으로 변경
                          textInputAction:
                              TextInputAction.newline, // 🔹 엔터 키를 누르면 새 줄 입력
                          maxLines: null, // 🔹 여러 줄 입력 가능
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Wrap(
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text("취소"),
                            ),
                            TextButton(
                              onPressed: () async {
                                // 🔹 FirestoreService를 사용하여 값 업데이트
                                await firestoreService.updateKeywordValue(
                                    itemId, key, textController.text);
                                Navigator.pop(context);
                              },
                              child: Text("저장"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAddDialog(
      BuildContext context, ItemProvider itemProvider, String itemId) async {
    String? selectedKey; // 선택한 키
    String inputValue = ""; // 입력한 값
    Map<String, dynamic> existingFields = {}; // Firestore에서 기존 필드 가져오기

    // 🔹 Firestore에서 기존 필드 가져오기
    try {
      final doc = await firestoreService.getItemById(
          collectionName: 'Items', documentId: itemId);
      if (doc.exists) {
        existingFields = doc.data() ?? {};
      }
    } catch (e) {
      print("🔥 Firestore 데이터 가져오기 오류: $e");
    }

    bool isDefault = true; // Local state for the dialog

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: SizedBox(
                width: 400,
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '항목 추가',
                        style: AppTheme.appbarTitleTextStyle,
                      ),
                      SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(width: 10),
                            Flexible(
                              child: FilterChip(
                                checkmarkColor: AppTheme.secondaryColor,
                                selectedColor: Colors.yellow[100],
                                backgroundColor: Colors.blue[50],
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(8), // 둥근 모서리 설정
                                  side: BorderSide.none, // 테두리 없애기
                                ),
                                label: SizedBox(
                                    width: 100,
                                    height: 20,
                                    child: Center(
                                        child: Text(isDefault
                                            ? 'Default Field'
                                            : 'Resources'))),
                                selected: isDefault,
                                onSelected: (selected) {
                                  setState(() {
                                    isDefault = selected; // Update local state
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      Wrap(
                        alignment: WrapAlignment.center, // 중앙 정렬
                        spacing: 10, // 위젯 간 간격
                        runSpacing: 10, // 줄 바뀔 때 간격
                        children: [
                          DropdownMenu<String>(
                            initialSelection: selectedKey,
                            enableFilter: true,
                            // enableSearch: false,
                            requestFocusOnTap: true,
                            expandedInsets: EdgeInsets.all(15),
                            label: const Text('Select Field'),
                            dropdownMenuEntries: itemProvider.fieldMappings.keys
                                .where((key) =>
                                    itemProvider.fieldMappings[key]
                                        ?['IsDefault'] ==
                                    isDefault) // 🔹 isDefault가 true인 항목만 필터링
                                .map(
                                  (key) => DropdownMenuEntry<String>(
                                    labelWidget: Text(
                                      itemProvider.fieldMappings[key]
                                              ?['FieldName'] ??
                                          key,
                                      style: AppTheme
                                          .textLabelStyle, // 🔹 한글 필드명 사용
                                    ),
                                    value: key,
                                    label: itemProvider.fieldMappings[key]
                                            ?['FieldName'] ??
                                        key, // 🔹 한글 필드명 사용
                                  ),
                                )
                                .toList(),
                            onSelected: (String? newValue) {
                              setState(() {
                                selectedKey = newValue;
                              });
                            },
                          ),

                          // SizedBox(width: 10),

                          // 🔹 값 입력 필드
                          Flexible(
                            child: Container(
                              constraints: BoxConstraints(
                                maxHeight: 200,
                                // maxWidth: 200,
                              ),
                              child: Scrollbar(
                                child: SingleChildScrollView(
                                  padding: EdgeInsets.only(left: 15, right: 15),
                                  child: TextField(
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.all(15),
                                      labelText: selectedKey ?? 'keyword',
                                      hintText: "값을 입력하세요",
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType
                                        .multiline, // 🔹 키보드 유형을 멀티라인으로 변경
                                    textInputAction: TextInputAction
                                        .newline, // 🔹 엔터 키를 누르면 새 줄 입력
                                    maxLines: null, // 🔹 여러 줄 입력 가능
                                    onChanged: (value) {
                                      inputValue = value;
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text("Cancel"),
                          ),

                          // 🔹 추가 버튼
                          ElevatedButton(
                            onPressed: () async {
                              if (selectedKey != null &&
                                  inputValue.isNotEmpty) {
                                // 🔹 키가 이미 존재하는지 확인
                                if (existingFields.containsKey(selectedKey)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "'${itemProvider.fieldMappings[selectedKey]?['FieldName'] ?? selectedKey}'  항목이 이미 존재하고 있습니다",
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                // 🔹 새로운 키워드 추가
                                await firestoreService.addKeywordValue(
                                    itemId, selectedKey!, inputValue);
                                Navigator.of(context).pop();
                              } else {
                                // 입력 값이 없거나 키가 선택되지 않음
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("값을 입력해주세요."),
                                  ),
                                );
                              }
                            },
                            child: const Text("Add"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
