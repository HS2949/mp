// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mp_db/Functions/firestore.dart';
import 'package:mp_db/constants/styles.dart';
import 'package:mp_db/pages/subpage/item_subpage.dart';
import 'package:mp_db/providers/Item_provider.dart';
import 'package:mp_db/utils/widget_help.dart';

import '../../models/item_model.dart';
import '../../providers/Item_detail/Item_detail_provider.dart';
import '../../providers/Item_detail/Item_detail_state.dart';

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

  /// Firebase의 subItems 데이터를 그룹화한 결과를 저장하는 상태 변수
  List<Map<String, dynamic>> _computedGroups = [];
  bool _allGroupsExpanded = false;

  // 이전 subItems 개수를 저장하여 변경 시에만 그룹 업데이트를 실행함
  int _lastSubItemsCount = -1;

  @override
  void initState() {
    super.initState();
    provider = Provider.of<ItemProvider>(context, listen: false);
    // itemId 변경 시 Firestore 조회
    Future.microtask(() {
      Provider.of<ItemDetailProvider>(context, listen: false)
          .listenToItemDetail(itemId: widget.itemId);
    });
  }

  @override
  void didUpdateWidget(covariant ItemDetailSubpage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemId != widget.itemId) {
      _computedGroups = [];
      _lastSubItemsCount = -1;
    }
  }

  @override
  void dispose() {
    Provider.of<ItemDetailProvider>(context, listen: false)
        .cancelSubscription(widget.itemId);
    _focusNode.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------
  // 그룹 계산 로직 (변경 없음)
  List<Map<String, dynamic>> _computeGroupsFromItem(Item item) {
    final Map<String, List<Map<String, dynamic>>> groupedData = {};
    for (var subItem in item.subItems) {
      final groupKey = subItem.fields['SubItem'] ?? '(미분류)';
      groupedData.putIfAbsent(groupKey, () => []).add(subItem.fields);
    }
    groupedData.forEach((groupKey, subItems) {
      subItems.sort((a, b) {
        int orderA = int.tryParse(a['SubOrder']?.toString() ?? "") ?? 9999;
        int orderB = int.tryParse(b['SubOrder']?.toString() ?? "") ?? 9999;
        return orderA.compareTo(orderB);
      });
    });
    final sortedGroups = groupedData.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    List<Map<String, dynamic>> groups = sortedGroups.map((entry) {
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
    return groups;
  }

  void _updateComputedGroups(Item item) {
    List<Map<String, dynamic>> newGroups = _computeGroupsFromItem(item);
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
    setState(() {
      _computedGroups = newGroups;
    });
  }

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
  // -------------------------------------------------------------------

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
                  child: CircularProgressIndicator(strokeWidth: 4.0),
                ),
              ),
            )
          : const SizedBox.shrink();
    }

    if (state.itemDetailStatus == ItemDetailStatus.error) {
      return widget.viewSelect < 2
          ? Padding(
              padding: const EdgeInsets.all(50.0),
              child: Text('에러 발생: ${state.error.message}',
                  style: const TextStyle(color: Colors.red)),
            )
          : const SizedBox.shrink();
    }

    return itemData == null
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(50.0),
              child: SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(strokeWidth: 4.0),
              ),
            ),
          )
        : widget.viewSelect < 2
            ? _buildFirstView(itemData)
            : _buildSecondView(itemData);
  }

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
            surfaceTintColor: AppTheme.textStrongColor,
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
                    : const SizedBox.shrink(),
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
      child: Padding(
        padding: const EdgeInsets.all(8.0),
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
                          (itemData.itemTag).isEmpty
                              ? '#Tag'
                              : itemData.itemTag,
                          style: AppTheme.tagTextStyle,
                          textAlign: TextAlign.start,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    icon: Icon(Icons.edit, size: 10, color: AppTheme.toolColor),
                    onPressed: () {
                      _showEditDialog(context, 'keyword', '태그',
                          itemData.itemTag, itemData.id);
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
                  spacing: 40.0,
                  runSpacing: 50.0,
                  children: [
                    for (var entry in sortedItemFields.entries)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final itemProvider = context.read<ItemProvider>();
                          final String label = itemProvider
                                  .fieldMappings[entry.key]?['FieldName'] ??
                              entry.key;
                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                            child: IntrinsicWidth(
                              child: Container(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        SelectableText(label,
                                            style:
                                                AppTheme.fieldLabelTextStyle),
                                        const SizedBox(width: 5),
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(
                                                minWidth: 16, minHeight: 16),
                                            tooltip: "Edit",
                                            icon: Icon(Icons.edit,
                                                size: 10,
                                                color: AppTheme.toolColor),
                                            onPressed: () {
                                              _showEditDialog(
                                                  context,
                                                  entry.key,
                                                  itemProvider.fieldMappings[
                                                              entry.key]
                                                          ?['FieldName'] ??
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
                                      style: AppTheme.bodySmallTextStyle,
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
      ),
    );
  }

  Widget _buildSecondView(Item item) {
    if (item.subItems.length != _lastSubItemsCount) {
      _lastSubItemsCount = item.subItems.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _updateComputedGroups(item);
        }
      });
    }

    Widget content = Card(
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('추가 정보', style: AppTheme.textCGreyStyle),
                  TextButton(
                      onPressed: _toggleAllGroups,
                      child: Text(_allGroupsExpanded ? "모두 닫기" : "모두 열기",
                          style: AppTheme.textHintTextStyle
                              .copyWith(fontSize: 13))),
                ],
              ),
            ),
            Divider(color: AppTheme.buttonlightbackgroundColor),
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
                      ListTile(
                        minVerticalPadding: 0,
                        title: Text(
                          group["groupTitle"],
                          style: AppTheme.fieldLabelTextStyle.copyWith(
                              color: AppTheme.text9Color.withOpacity(0.3)),
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
                                                    child: Text("속성 추가")),
                                                const PopupMenuItem(
                                                    value: "removeItem",
                                                    child: Text("아이템 삭제")),
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
                                                    child: Text(attribute,
                                                        style: const TextStyle(
                                                            color: Colors
                                                                .black54)),
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

    return widget.viewSelect < 2
        ? content
        : SingleChildScrollView(child: content);
  }

  Future<void> _showEditDialog(BuildContext context, String key, String name,
      String value, String itemId) async {
    await showDialog(
      context: context,
      builder: (context) => EditDialogContent(
        keyField: key, // 필드의 실제 키 값 (여기서는 key가 예약어이므로 다른 이름 사용)
        fieldName: name,
        fieldValue: value,
        itemId: itemId,
      ),
    );
  }

  Future<void> _showAddDialog(
      BuildContext context, ItemProvider itemProvider, String itemId) async {
    final item = context.read<ItemDetailProvider>().getItemData(itemId);
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          child: AddDialogContent(
              itemProvider: itemProvider, itemId: itemId, item: item),
        );
      },
    );
  }
}

// -------------------------------------------------------------------
// AddDialogContent: 다이얼로그 내용을 별도의 StatefulWidget으로 분리하여
// 컨트롤러를 안전하게 생성 및 dispose 합니다.
class AddDialogContent extends StatefulWidget {
  final ItemProvider itemProvider;
  final String itemId;
  final Item? item;

  const AddDialogContent({
    Key? key,
    required this.itemProvider,
    required this.itemId,
    required this.item,
  }) : super(key: key);

  @override
  _AddDialogContentState createState() => _AddDialogContentState();
}

class _AddDialogContentState extends State<AddDialogContent>
    with SingleTickerProviderStateMixin {
  String? selectedKey;
  String? selectedGroup;
  String? labelKo;
  double _containerHeight = 130; // 기본 높이

  late TextEditingController value1Controller;
  late TextEditingController value2Controller;
  late TextEditingController groupController;
  late ScrollController defaultScrollController;
  late ScrollController addScrollController;
  late TabController tabController;

  List<Map<String, dynamic>> computedGroups = [];

  @override
  void initState() {
    super.initState();
    value1Controller = TextEditingController();
    value2Controller = TextEditingController();
    groupController = TextEditingController();
    defaultScrollController = ScrollController();
    addScrollController = ScrollController();
    tabController = TabController(length: 2, vsync: this);
    // 탭 전환 시 setState()를 호출하여 AnimatedContainer가 업데이트되도록 리스너 추가
    tabController.addListener(() {
      setState(() {});
    });
    if (widget.item != null) {
      computedGroups = _computeGroupsFromItem(widget.item!);
      if (computedGroups.isNotEmpty) {
        selectedGroup = computedGroups[0]["groupTitle"];
      }
    }
  }

  List<Map<String, dynamic>> _computeGroupsFromItem(Item item) {
    final Map<String, List<Map<String, dynamic>>> groupedData = {};
    for (var subItem in item.subItems) {
      final groupKey = subItem.fields['SubItem'] ?? '(미분류)';
      groupedData.putIfAbsent(groupKey, () => []).add(subItem.fields);
    }
    groupedData.forEach((groupKey, subItems) {
      subItems.sort((a, b) {
        int orderA = int.tryParse(a['SubOrder']?.toString() ?? "") ?? 9999;
        int orderB = int.tryParse(b['SubOrder']?.toString() ?? "") ?? 9999;
        return orderA.compareTo(orderB);
      });
    });
    final sortedGroups = groupedData.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    List<Map<String, dynamic>> groups = sortedGroups.map((entry) {
      return {
        "groupTitle": entry.key,
        "isExpanded": false,
        "items": entry.value.map((subItem) {
          return {
            "title": subItem['SubName']?.toString() ?? "(미지정)",
          };
        }).toList(),
      };
    }).toList();
    return groups;
  }

  @override
  void dispose() {
    value1Controller.dispose();
    value2Controller.dispose();
    groupController.dispose();
    defaultScrollController.dispose();
    addScrollController.dispose();
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(15.0),
      child: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${widget.item?.itemName ?? ""} - 정보 추가',
                style: AppTheme.appbarTitleTextStyle),
            const SizedBox(height: 20),
            TabBar(
              controller: tabController,
              indicatorColor: AppTheme.text9Color,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.grey[300],
              indicatorWeight: 4.0,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: '기본 정보'),
                Tab(text: '추가 정보'),
              ],
            ),
            const SizedBox(height: 10),
            // AnimatedContainer로 탭 전환 시 높이 변경 (탭1: 180, 탭2: 210)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: tabController.index == 0 ? 180 : _containerHeight,
              child: TabBarView(
                controller: tabController,
                children: [
                  // 기본 정보 탭
                  Column(
                    children: [
                      const SizedBox(height: 10),
                      DropdownMenu<String>(
                        initialSelection: selectedKey,
                        requestFocusOnTap: false,
                        expandedInsets: const EdgeInsets.all(15),
                        label: const Text('항목 선택'),
                        dropdownMenuEntries: () {
                          final sortedKeys =
                              widget.itemProvider.fieldMappings.keys
                                  .where(
                                    (key) =>
                                        widget.itemProvider.fieldMappings[key]
                                            ?['IsDefault'] ==
                                        true,
                                  )
                                  .toList();
                          sortedKeys.sort((a, b) {
                            final orderA = widget.itemProvider.fieldMappings[a]
                                    ?['FieldOrder'] ??
                                0;
                            final orderB = widget.itemProvider.fieldMappings[b]
                                    ?['FieldOrder'] ??
                                0;
                            return orderA.compareTo(orderB);
                          });
                          return sortedKeys
                              .map((key) => DropdownMenuEntry<String>(
                                    labelWidget: Text(
                                      widget.itemProvider.fieldMappings[key]
                                              ?['FieldName'] ??
                                          key,
                                      style: AppTheme.textLabelStyle,
                                    ),
                                    value: key,
                                    label: widget.itemProvider
                                            .fieldMappings[key]?['FieldName'] ??
                                        key,
                                  ))
                              .toList();
                        }(),
                        onSelected: (String? newValue) {
                          setState(() {
                            selectedKey = newValue;
                            labelKo = widget.itemProvider
                                    .fieldMappings[selectedKey]?['FieldName'] ??
                                selectedKey;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      Flexible(
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: Scrollbar(
                            controller: defaultScrollController,
                            child: SingleChildScrollView(
                              controller: defaultScrollController,
                              padding:
                                  const EdgeInsets.only(left: 15, right: 15),
                              child: TextField(
                                controller: value1Controller,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.all(15),
                                  labelText: selectedKey ?? 'Value',
                                  hintText: labelKo == null
                                      ? "Field를 먼저 선택하세요"
                                      : "[$labelKo] - 입력해 주세요",
                                  border: const OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.multiline,
                                textInputAction: TextInputAction.newline,
                                maxLines: null,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // 추가 정보 탭
                  Column(
                    children: [
                      const SizedBox(height: 10),
                      DropdownMenu<String>(
                        requestFocusOnTap: false,
                        expandedInsets: const EdgeInsets.all(15),
                        label: const Text('그룹'),
                        dropdownMenuEntries: [
                          DropdownMenuEntry<String>(
                            labelWidget: Text('새 그룹 생성',
                                style: AppTheme.textLabelStyle
                                    .copyWith(color: AppTheme.text4Color)),
                            value: '신규',
                            label: '새 그룹 생성',
                          ),
                          ...computedGroups
                              .map((group) => DropdownMenuEntry<String>(
                                    value: group["groupTitle"],
                                    label: group["groupTitle"],
                                    labelWidget: Text(group["groupTitle"],
                                        style: AppTheme.textLabelStyle),
                                  )),
                        ],
                        onSelected: (String? newValue) {
                          setState(() {
                            selectedGroup = newValue;
                            if (selectedGroup == '신규') _containerHeight = 180;
                            else  _containerHeight = 130; 
                          });
                        },
                      ),
                      if (selectedGroup == '신규')
                        Padding(
                          padding: const EdgeInsets.only(top: 10, left: 50),
                          child: Container(
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: Scrollbar(
                              controller: addScrollController,
                              child: SingleChildScrollView(
                                controller: addScrollController,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 15),
                                child: TextField(
                                  controller: groupController,
                                  decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.all(15),
                                    labelText: '새 그룹명',
                                    hintText: "예) 음식메뉴, 객실, 이용권, 기타..",
                                    border: OutlineInputBorder(),
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
                          child: TextField(
                            controller: value2Controller,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.all(15),
                              labelText: '서브 아이템명',
                              hintText: "예) 메뉴명, 객실명, 서비스명",
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(left: 15, right: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      Navigator.of(context).pop();
                    },
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final int currentTabIndex = tabController.index;
                      if (currentTabIndex == 0) {
                        if (selectedKey == null) {
                          showOverlayMessage(context, "항목을 선택해주세요.");
                          return;
                        }
                        final String defaultValue =
                            value1Controller.text.trim();
                        if (defaultValue.isEmpty) {
                          showOverlayMessage(context, "값을 입력해주세요.");
                          return;
                        }
                        final String collectionPath = 'Items';
                        final String documentId = widget.itemId;
                        final docRef = FirebaseFirestore.instance
                            .collection(collectionPath)
                            .doc(documentId);
                        final docSnapshot = await docRef.get();
                        if (docSnapshot.exists) {
                          final existingData = docSnapshot.data() ?? {};
                          if (existingData.containsKey(selectedKey)) {
                            showOverlayMessage(
                                context, "'$labelKo' 항목이 이미 존재합니다.");
                            return;
                          }
                        }
                        await docRef.set({selectedKey!: defaultValue},
                            SetOptions(merge: true));
                        FocusScope.of(context).unfocus();
                        Navigator.of(context).pop();
                        showOverlayMessage(context, '항목을 추가하였습니다.');
                      } else if (currentTabIndex == 1) {
                        final String subItemName = value2Controller.text.trim();
                        if (subItemName.isEmpty) {
                          showOverlayMessage(context, "서브 아이템명을 입력해주세요.");
                          return;
                        }
                        if (selectedGroup == null) {
                          showOverlayMessage(context, "그룹을 선택해주세요.");
                          return;
                        }
                        String finalGroup;
                        if (selectedGroup == '신규') {
                          final String groupName = groupController.text.trim();
                          if (groupName.isEmpty) {
                            showOverlayMessage(context, "새 그룹명을 입력해주세요.");
                            return;
                          }
                          finalGroup = groupName;
                        } else {
                          finalGroup = selectedGroup!;
                        }
                        final String subCollectionPath =
                            'Items/${widget.itemId}/Sub_Items';
                        final String documentId = FirebaseFirestore.instance
                            .collection(subCollectionPath)
                            .doc()
                            .id;
                        final docRef = FirebaseFirestore.instance
                            .collection(subCollectionPath)
                            .doc(documentId);
                        final Map<String, dynamic> subItemData = {
                          'SubName': subItemName,
                          'SubItem': finalGroup,
                        };
                        await docRef.set(subItemData);
                        FocusScope.of(context).unfocus();
                        Navigator.of(context).pop();
                        showOverlayMessage(context, '서브 아이템을 추가하였습니다.');
                      }
                    },
                    child: const Text("Add"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EditDialogContent extends StatefulWidget {
  final String keyField; // 예: 'keyword'
  final String fieldName;
  final String fieldValue;
  final String itemId;

  const EditDialogContent({
    Key? key,
    required this.keyField,
    required this.fieldName,
    required this.fieldValue,
    required this.itemId,
  }) : super(key: key);

  @override
  _EditDialogContentState createState() => _EditDialogContentState();
}

class _EditDialogContentState extends State<EditDialogContent> {
  late TextEditingController textController;
  final firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    textController = TextEditingController(text: widget.fieldValue);
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: SizedBox(
        width: 400,
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('항목 편집', style: AppTheme.appbarTitleTextStyle),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () async {
                    // 포커스 해제 후 삭제 다이얼로그 호출
                    FocusScope.of(context).unfocus();
                    FiDeleteDialog(
                      context: context,
                      deleteFunction: () async => firestoreService
                          .deleteKeywordValue(widget.itemId, widget.keyField),
                      shouldCloseScreen: true,
                    );
                  },
                  icon: const Icon(Icons.delete_forever_outlined),
                  tooltip: "삭제",
                ),
              ),
              TextFormField(
                initialValue: widget.fieldName,
                decoration: InputDecoration(
                  labelText: 'Edit Field',
                  labelStyle: AppTheme.textLabelStyle,
                  enabledBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: AppTheme.buttonlightbackgroundColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                style: AppTheme.fieldLabelTextStyle,
                readOnly: true,
              ),
              const SizedBox(height: 10),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
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
                    TextButton(
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        Navigator.pop(context);
                      },
                      child: const Text("취소"),
                    ),
                    TextButton(
                      onPressed: () async {
                        FocusScope.of(context).unfocus();
                        await firestoreService.addKeywordValue(widget.itemId,
                            widget.keyField, textController.text, true);
                        Navigator.pop(context);
                        showOverlayMessage(context, '수정하였습니다.');
                      },
                      child: const Text("저장"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
