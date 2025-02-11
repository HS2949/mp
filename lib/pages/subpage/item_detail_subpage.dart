import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mp_db/Functions/firestore.dart';
import 'package:mp_db/constants/styles.dart';
import 'package:mp_db/pages/subpage/item_subpage.dart';
import 'package:mp_db/providers/Item_provider.dart';
import 'package:mp_db/utils/widget_help.dart';
import 'package:provider/provider.dart';

import '../../providers/Item_detail/Item_detail_provider.dart';
import '../../providers/Item_detail/Item_detail_state.dart';
import '../../models/item_model.dart';

class ItemDetailSubpage extends StatefulWidget {
  const ItemDetailSubpage(
      {Key? key, required this.itemId, required this.viewSelect})
      : super(key: key);

  final String itemId;
  final int viewSelect; // 0,1: fields 표시 / 2: sub_items 표시

  @override
  State<ItemDetailSubpage> createState() => _ItemDetailSubpageState();
}

class _ItemDetailSubpageState extends State<ItemDetailSubpage> {
  final FocusNode _focusNode = FocusNode();
  late final ItemProvider provider;
  final firestoreService = FirestoreService();

  /// state 변수로 firebase의 subItems 데이터를 그룹화한 결과를 저장
  List<Map<String, dynamic>> _computedGroups = [];
  bool _allGroupsExpanded = false;

  @override
  void initState() {
    super.initState();
    provider = Provider.of<ItemProvider>(context, listen: false);
    // Firestore 조회 (itemId 변경 시 다시 실행)
    Future.microtask(() {
      Provider.of<ItemDetailProvider>(context, listen: false)
          .listenToItemDetail(itemId: widget.itemId);
    });
  }

  @override
  void didUpdateWidget(covariant ItemDetailSubpage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemId != widget.itemId) {
      // itemId가 바뀌면 그룹 데이터를 초기화 (초기 상태로)
      _computedGroups = [];
    }
  }

  @override
  void dispose() {
    Provider.of<ItemDetailProvider>(context, listen: false)
        .cancelSubscription(widget.itemId);
    _focusNode.dispose();
    super.dispose();
  }

  /// Firebase의 최신 item.subItems 데이터를 기반으로 그룹 데이터를 재계산합니다.
  /// 기존 _computedGroups와 병합하여 동일 그룹/아이템의 확장 상태는 유지합니다.
  void _updateComputedGroups(Item item) {
    final Map<String, List<Map<String, dynamic>>> groupedData = {};
    for (var subItem in item.subItems) {
      final groupKey = subItem.fields['SubItem'] ?? '(미분류)'; // null이면 "기타"로 설정
      groupedData.putIfAbsent(groupKey, () => []).add(subItem.fields);
    }
    // 각 그룹 내에서 'SubOrder' 순으로 정렬
    groupedData.forEach((groupKey, subItems) {
      subItems.sort((a, b) {
        int orderA = int.tryParse(a['SubOrder']?.toString() ?? "") ?? 9999;
        int orderB = int.tryParse(b['SubOrder']?.toString() ?? "") ?? 9999;
        return orderA.compareTo(orderB);
      });
    });
    // 그룹들을 아이템 개수가 많은 순(내림차순)으로 정렬
    final sortedGroups = groupedData.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    List<Map<String, dynamic>> newGroups = sortedGroups.map((entry) {
      final groupTitle = entry.key;
      final subItems = entry.value;
      final items = subItems.map<Map<String, dynamic>>((subItem) {
        final title = subItem['SubName']?.toString() ?? "(미지정)";
        final attributesMap = Map<String, dynamic>.from(subItem)
          ..remove('SubItem')
          ..remove('SubName')
          ..remove('SubOrder');

        final itemProvider = context.read<ItemProvider>();
        final List<String> attributes = attributesMap.entries
            .map((e) =>
                "${itemProvider.fieldMappings[e.key]?['FieldName'] ?? e.key}: ${e.value}")
            .toList();
        return {
          "title": title,
          "isExpanded": false,
          "attributes": attributes,
        };
      }).toList();
      return {
        "groupTitle": groupTitle,
        "isExpanded": false,
        "items": items,
      };
    }).toList();

    // 기존 _computedGroups와 병합: 같은 그룹/아이템이면 기존 확장 상태를 유지
    if (_computedGroups.isNotEmpty) {
      for (var newGroup in newGroups) {
        final index = _computedGroups
            .indexWhere((g) => g["groupTitle"] == newGroup["groupTitle"]);
        if (index != -1) {
          newGroup["isExpanded"] = _computedGroups[index]["isExpanded"];
          List newItems = newGroup["items"];
          List oldItems = _computedGroups[index]["items"];
          for (int i = 0; i < newItems.length; i++) {
            int oldIndex = oldItems
                .indexWhere((item) => item["title"] == newItems[i]["title"]);
            if (oldIndex != -1) {
              newItems[i]["isExpanded"] = oldItems[oldIndex]["isExpanded"];
            }
          }
        }
      }
    }
    // 업데이트된 그룹 데이터를 state에 반영 (빌드 완료 후 업데이트)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _computedGroups = newGroups;
        });
      }
    });
  }

  // ----- 토글 및 업데이트 함수 (state 변수 _computedGroups 사용) -----
  void _toggleAllGroups() {
    setState(() {
      _allGroupsExpanded = !_allGroupsExpanded;
      for (var group in _computedGroups) {
        group["isExpanded"] = _allGroupsExpanded;
      }
    });
  }

  void _toggleGroupExpansion(int groupIndex) {
    setState(() {
      _computedGroups[groupIndex]["isExpanded"] =
          !_computedGroups[groupIndex]["isExpanded"];
    });
  }

  void _toggleAllItemsInGroup(int groupIndex) {
    setState(() {
      bool newState = !_computedGroups[groupIndex]["items"][0]["isExpanded"];
      for (var item in _computedGroups[groupIndex]["items"]) {
        item["isExpanded"] = newState;
      }
    });
  }

  void _toggleItemExpansion(int groupIndex, int itemIndex) {
    setState(() {
      _computedGroups[groupIndex]["items"][itemIndex]["isExpanded"] =
          !_computedGroups[groupIndex]["items"][itemIndex]["isExpanded"];
    });
  }

  void _addItem(BuildContext context) {
    TextEditingController itemController = TextEditingController();
    String? selectedGroup =
        _computedGroups.isNotEmpty ? _computedGroups[0]["groupTitle"] : null;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text("새 아이템 추가"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: "그룹 선택"),
                value: selectedGroup,
                items: [
                  ..._computedGroups.map((group) => DropdownMenuItem(
                        value: group["groupTitle"],
                        child: Text(group["groupTitle"]),
                      )),
                  DropdownMenuItem(
                    value: "새 그룹",
                    child: Text("새 그룹 생성"),
                  ),
                ],
                onChanged: (value) {
                  selectedGroup = value;
                },
              ),
              TextField(
                controller: itemController,
                decoration: InputDecoration(labelText: "아이템명"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text("취소"),
            ),
            TextButton(
              onPressed: () {
                if (selectedGroup != null &&
                    itemController.text.trim().isNotEmpty) {
                  setState(() {
                    String itemName = itemController.text.trim();
                    if (selectedGroup == "새 그룹") {
                      String newGroupName =
                          "그룹 ${String.fromCharCode(65 + _computedGroups.length)}";
                      _computedGroups.add({
                        "groupTitle": newGroupName,
                        "isExpanded": false,
                        "items": [
                          {
                            "title": itemName,
                            "isExpanded": false,
                            "attributes": []
                          }
                        ],
                      });
                    } else {
                      int groupIndex = _computedGroups.indexWhere(
                          (group) => group["groupTitle"] == selectedGroup);
                      if (groupIndex != -1) {
                        _computedGroups[groupIndex]["items"].add({
                          "title": itemName,
                          "isExpanded": false,
                          "attributes": [],
                        });
                      }
                    }
                  });
                  Navigator.pop(dialogContext);
                }
              },
              child: Text("추가"),
            ),
          ],
        );
      },
    );
  }

  void _addAttribute(int groupIndex, int itemIndex) {
    setState(() {
      _computedGroups[groupIndex]["items"][itemIndex]["attributes"].add(
        "속성 ${_computedGroups[groupIndex]["items"][itemIndex]["title"]}-${_computedGroups[groupIndex]["items"][itemIndex]["attributes"].length + 1}",
      );
    });
  }

  void _removeItem(int groupIndex, int itemIndex) {
    setState(() {
      _computedGroups[groupIndex]["items"].removeAt(itemIndex);
      if (_computedGroups[groupIndex]["items"].isEmpty) {
        _computedGroups.removeAt(groupIndex);
      }
    });
  }
  // ----- // 토글 및 업데이트 함수 -----

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
            ? _buildFirstView(itemData)
            : _buildSecondView(itemData);
  }

  /// 첫 번째 뷰 (fields 표시)
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
          await _showAddDialog(context, provider, widget.itemId);
        },
      ),
      IconButton(icon: const Icon(Icons.attach_file), onPressed: () {}),
      MenuAnchor(
        builder: (context, controller, child) {
          return IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
          );
        },
        menuChildren: [
          MenuItemButton(
              leadingIcon: const Icon(Icons.edit_note_outlined),
              child: const Text('Edit', style: AppTheme.textLabelStyle),
              onPressed: () async {
                showAddItem(context, widget.itemId);
              }),
          MenuItemButton(
            leadingIcon: const Icon(Icons.delete_forever_outlined),
            child: const Text('Delete', style: AppTheme.textLabelStyle),
            onPressed: () async {
              FiDeleteDialog(
                  context: context,
                  deleteFunction: () async => firestoreService.deleteItem(
                      collectionName: 'Items', documentId: widget.itemId),
                  shouldCloseScreen: false);
              provider.removeTab(provider.selectedIndex);
            },
          ),
        ],
      ),
    ];

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
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
                const SizedBox(width: 15),
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
                    : SizedBox.shrink(),
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
                        (itemData.itemTag).isEmpty ? '#Tag' : itemData.itemTag,
                        style: AppTheme.tagTextStyle,
                        textAlign: TextAlign.start,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
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
          const SizedBox(height: 15),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Wrap(
                spacing: 2.0,
                runSpacing: 0.0,
                children: [
                  for (var entry in sortedItemFields.entries)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final itemProvider = context.read<ItemProvider>();
                        final String label = itemProvider
                                .fieldMappings[entry.key]?['FieldName'] ??
                            entry.key;
                        final int maxLineLength = entry.value
                            .split(';')
                            .map((e) => e.trim().length)
                            .reduce((a, b) => a > b ? a : b);
                        final dynamicWidth = (maxLineLength * 14.0)
                            .clamp(150.0, constraints.maxWidth * 1.0);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 15.0),
                          child: Card(
                            elevation: 0,
                            child: Container(
                              width: dynamicWidth,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      SelectableText(label,
                                          style: AppTheme.fieldLabelTextStyle),
                                      const SizedBox(
                                        width: 20,
                                        height: 20,
                                      ),
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                              minWidth: 16, minHeight: 16),
                                          tooltip: "Edit",
                                          icon: Icon(
                                            Icons.edit,
                                            size: 10,
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
                                  const SizedBox(height: 5),
                                  TextField(
                                    controller: TextEditingController(
                                        text: entry.value),
                                    style: entry.value.length > 20
                                        ? AppTheme.bodySmallTextStyle
                                        : AppTheme.bodySmallTextStyle,
                                    readOnly: true,
                                    maxLines: null,
                                    decoration: const InputDecoration(
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

  /// 두 번째 뷰 (sub_items 표시)
  Widget _buildSecondView(Item item) {
    // Firebase의 최신 데이터가 반영되도록 매 빌드 시 _updateComputedGroups() 호출
    _updateComputedGroups(item);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            // 상단 컨트롤바: 타이틀, 새 아이템 추가, 전체 그룹 확장/접기 버튼
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: AppTheme.buttonlightbackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text("Sub Items",
                          style: AppTheme.appbarTitleTextStyle),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: () => _addItem(context),
                    ),
                    IconButton(
                      icon: Icon(
                        _allGroupsExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: Colors.white,
                      ),
                      onPressed: _toggleAllGroups,
                    ),
                  ],
                ),
              ),
            ),
            // 그룹별 ListView (각 그룹은 카드 형태)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _computedGroups.length,
              itemBuilder: (context, groupIndex) {
                final group = _computedGroups[groupIndex];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      // 그룹 타이틀 및 전체 아이템 토글 버튼
                      ListTile(
                        title: Text(
                          group["groupTitle"],
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            group["items"].isNotEmpty &&
                                    group["items"][0]["isExpanded"]
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Colors.grey,
                          ),
                          onPressed: () => _toggleAllItemsInGroup(groupIndex),
                        ),
                        onTap: () => _toggleGroupExpansion(groupIndex),
                      ),
                      // 그룹 확장 상태이면 내부 아이템 목록 표시
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.fastOutSlowIn,
                        child: group["isExpanded"]
                            ? Column(
                                children: group["items"]
                                    .asMap()
                                    .entries
                                    .map<Widget>((entry) {
                                  int itemIndex = entry.key;
                                  var itemData = entry.value;
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      ListTile(
                                        title: Text(itemData["title"]),
                                        onTap: () => _toggleItemExpansion(
                                            groupIndex, itemIndex),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                itemData["isExpanded"]
                                                    ? Icons.keyboard_arrow_up
                                                    : Icons.keyboard_arrow_down,
                                                color: Colors.grey,
                                              ),
                                              onPressed: () =>
                                                  _toggleItemExpansion(
                                                      groupIndex, itemIndex),
                                            ),
                                            PopupMenuButton<String>(
                                              icon: const Icon(Icons.more_vert,
                                                  color: Colors.grey),
                                              onSelected: (value) {
                                                if (value == "addAttribute") {
                                                  _addAttribute(
                                                      groupIndex, itemIndex);
                                                } else if (value ==
                                                    "removeItem") {
                                                  _removeItem(
                                                      groupIndex, itemIndex);
                                                }
                                              },
                                              itemBuilder:
                                                  (BuildContext context) => [
                                                const PopupMenuItem(
                                                  value: "addAttribute",
                                                  child: Text("속성 추가"),
                                                ),
                                                const PopupMenuItem(
                                                  value: "removeItem",
                                                  child: Text("아이템 삭제"),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      AnimatedSize(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        curve: Curves.fastOutSlowIn,
                                        child: itemData["isExpanded"]
                                            ? Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: itemData["attributes"]
                                                    .map<Widget>((attribute) {
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 16.0,
                                                            right: 16.0,
                                                            bottom: 4.0),
                                                    child: Text(
                                                      attribute,
                                                      style: const TextStyle(
                                                          color:
                                                              Colors.black54),
                                                    ),
                                                  );
                                                }).toList(),
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, String key, String name,
      String value, String itemId) {
    TextEditingController textController = TextEditingController(text: value);
    final firestoreService = FirestoreService();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
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
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () async {
                        FiDeleteDialog(
                            context: context,
                            deleteFunction: () async => firestoreService
                                .deleteKeywordValue(itemId, key),
                            shouldCloseScreen: true);
                      },
                      icon: const Icon(Icons.delete_forever_outlined),
                      tooltip: "삭제",
                    ),
                  ),
                  TextField(
                    controller: TextEditingController(text: name),
                    decoration: InputDecoration(
                      labelText: 'Edit Field',
                      labelStyle: AppTheme.textLabelStyle,
                      filled: false,
                      enabled: false,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: AppTheme.buttonlightbackgroundColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    style: AppTheme.fieldLabelTextStyle,
                    readOnly: true,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    constraints: const BoxConstraints(
                      maxHeight: 200,
                    ),
                    child: Scrollbar(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(0),
                        child: TextField(
                          controller: textController,
                          decoration: const InputDecoration(
                            labelText: 'Field Value',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          maxLines: null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
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
                              child: const Text("취소"),
                            ),
                            TextButton(
                              onPressed: () async {
                                await firestoreService.addKeywordValue(
                                    itemId, key, textController.text, true);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('수정하였습니다.')));
                              },
                              child: const Text("저장"),
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
    String? selectedKey;
    String? selectedID;
    String inputValue = "";
    final item = context.read<ItemDetailProvider>().getItemData(widget.itemId);
    bool isDefault = true;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0)),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(15.0),
                child: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '항목 추가',
                        style: AppTheme.appbarTitleTextStyle,
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(width: 10),
                            Flexible(
                              child: FilterChip(
                                checkmarkColor: AppTheme.secondaryColor,
                                selectedColor: Colors.yellow[100],
                                backgroundColor: Colors.blue[50],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide.none,
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
                                    isDefault = selected;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          isDefault
                              ? const SizedBox.shrink()
                              : DropdownMenu<String>(
                                  enableFilter: true,
                                  requestFocusOnTap: true,
                                  expandedInsets: const EdgeInsets.all(15),
                                  label: const Text('Select SubItem'),
                                  dropdownMenuEntries: [
                                    DropdownMenuEntry<String>(
                                      labelWidget: Text('신규',
                                          style: AppTheme.textLabelStyle),
                                      value: '신규',
                                      label: '신규',
                                    ),
                                    ...(item?.subItems ?? []).map(
                                      (subItem) => DropdownMenuEntry<String>(
                                        labelWidget: Text(
                                          subItem.fields.containsKey('SubName')
                                              ? subItem.fields['SubName']
                                                  .toString()
                                              : subItem.id,
                                          style: AppTheme.textLabelStyle,
                                        ),
                                        value: subItem.id,
                                        label: subItem.fields
                                                .containsKey('SubName')
                                            ? subItem.fields['SubName']
                                                .toString()
                                            : subItem.id,
                                      ),
                                    ),
                                  ],
                                  onSelected: (String? newValue) {
                                    setState(() {
                                      selectedID = newValue;
                                    });
                                  },
                                ),
                          DropdownMenu<String>(
                            initialSelection: selectedKey,
                            enableFilter: true,
                            requestFocusOnTap: true,
                            expandedInsets: const EdgeInsets.all(15),
                            label: const Text('Select Field'),
                            dropdownMenuEntries: itemProvider.fieldMappings.keys
                                .where((key) =>
                                    itemProvider.fieldMappings[key]
                                        ?['IsDefault'] ==
                                    isDefault)
                                .map(
                                  (key) => DropdownMenuEntry<String>(
                                    labelWidget: Text(
                                      itemProvider.fieldMappings[key]
                                              ?['FieldName'] ??
                                          key,
                                      style: AppTheme.textLabelStyle,
                                    ),
                                    value: key,
                                    label: itemProvider.fieldMappings[key]
                                            ?['FieldName'] ??
                                        key,
                                  ),
                                )
                                .toList(),
                            onSelected: (String? newValue) {
                              setState(() {
                                selectedKey = newValue;
                              });
                            },
                          ),
                          Flexible(
                            child: Container(
                              constraints: const BoxConstraints(
                                maxHeight: 200,
                              ),
                              child: Scrollbar(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.only(
                                      left: 15, right: 15),
                                  child: TextField(
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.all(15),
                                      labelText: selectedKey ?? 'keyword',
                                      hintText: "값을 입력하세요",
                                      border: const OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.multiline,
                                    textInputAction: TextInputAction.newline,
                                    maxLines: null,
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
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text("Cancel"),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              if (!isDefault && selectedID == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("항목을 선택해주세요.")),
                                );
                                return;
                              }
                              if (selectedKey == null || inputValue.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("값을 입력해주세요.")),
                                );
                                return;
                              }
                              String collectionPath;
                              String documentId;
                              if (isDefault) {
                                collectionPath = 'Items';
                                documentId = itemId;
                              } else {
                                collectionPath = 'Items/$itemId/Sub_Items';
                                if (selectedID == '신규') {
                                  documentId = FirebaseFirestore.instance
                                      .collection(collectionPath)
                                      .doc()
                                      .id;
                                } else {
                                  documentId = selectedID!;
                                }
                              }
                              final docRef = FirebaseFirestore.instance
                                  .collection(collectionPath)
                                  .doc(documentId);
                              final docSnapshot = await docRef.get();
                              if (docSnapshot.exists) {
                                final existingData = docSnapshot.data() ?? {};
                                if (existingData.containsKey(selectedKey)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            "'${selectedKey}' 항목이 이미 존재합니다.")),
                                  );
                                  return;
                                }
                              }
                              await docRef.set({
                                selectedKey!: inputValue,
                              }, SetOptions(merge: true));
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('항목을 추가하였습니다.')),
                              );
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
