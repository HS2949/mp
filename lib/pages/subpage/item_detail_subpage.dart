// ignore_for_file: public_member_api_docs, sort_constructors_first
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
  final TextEditingController _controller = TextEditingController();
  late final ItemProvider provider;
  final firestoreService = FirestoreService();

  /// Firebase의 subItems 데이터를 그룹화한 결과를 저장하는 상태 변수
  List<Map<String, dynamic>> _computedGroups = [];
  bool _allGroupsExpanded = true;

  // subItems 내용 변경 감지를 위한 해시값 저장
  String _lastSubItemsHash = '';

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
      _lastSubItemsHash = '';
    }
  }

  @override
  void dispose() {
    Provider.of<ItemDetailProvider>(context, listen: false)
        .cancelSubscription(widget.itemId);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------
  // 그룹 계산 로직 (변경 없음)
  List<Map<String, dynamic>> _computeGroupsFromItem(Item item) {
    final Map<String, List<Map<String, dynamic>>> groupedData = {};
    for (var subItem in item.subItems) {
      // 그룹 키 계산
      final groupKey = subItem.fields['SubItem'] ?? '(미분류)';
      // subItem.fields에 id 추가 (subItem이 DocumentSnapshot과 유사한 구조라고 가정)
      final fieldsWithId = Map<String, dynamic>.from(subItem.fields)
        ..['id'] = subItem.id; // subItem.id가 존재해야 함
      // ..['id'] = subItem.o; // subItem.id가 존재해야 함
      // 그룹핑 진행
      groupedData.putIfAbsent(groupKey, () => []).add(fieldsWithId);
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
          ..remove('SubOrder')
          ..remove('id'); // id는 별도로 저장해둡니다.
        final itemProvider = context.read<ItemProvider>();
        // 각 attribute를 별도의 맵으로 분리
        final List<Map<String, dynamic>> attributes =
            attributesMap.entries.map((e) {
          return {
            "FieldKey": e.key,
            "FieldName":
                itemProvider.fieldMappings[e.key]?['FieldName'] ?? e.key,
            "FieldValue": e.value,
            "FieldOrder":
                itemProvider.fieldMappings[e.key]?['FieldOrder'] ?? 9999,
          };
        }).toList();
        return {
          "id": subItem['id'], // subItem의 id를 여기서 저장
          "subOrder": subItem['SubOrder'],
          "subItem": subItem['SubItem'],
          "title": title,
          "isExpanded": true,
          "attributes": attributes,
        };
      }).toList();
      return {
        "groupTitle": groupTitle,
        "isExpanded": true,
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
      _allGroupsExpanded = !_allGroupsExpanded; // 현재 상태를 반전

      for (int groupIndex = 0;
          groupIndex < _computedGroups.length;
          groupIndex++) {
        _computedGroups[groupIndex]["isExpanded"] =
            _allGroupsExpanded; // 모든 그룹 확장/축소

        for (int itemIndex = 0;
            itemIndex < _computedGroups[groupIndex]["items"].length;
            itemIndex++) {
          _computedGroups[groupIndex]["items"][itemIndex]["isExpanded"] =
              _allGroupsExpanded; // 모든 아이템 확장/축소
        }
      }
    });
  }

  void _toggleGroupExpansion(int groupIndex) {
    setState(() {
      _computedGroups[groupIndex]["isExpanded"] =
          !_computedGroups[groupIndex]["isExpanded"];
      _allGroupsExpanded = false;
    });
  }

  void _toggleAllItemsInGroup(int groupIndex) {
    setState(() {
      bool newState = !_computedGroups[groupIndex]["items"][0]["isExpanded"];
      for (var item in _computedGroups[groupIndex]["items"]) {
        item["isExpanded"] = true; //newState;
      }
    });
  }

  void _toggleItemExpansion(int groupIndex, int itemIndex) {
    setState(() {
      _computedGroups[groupIndex]["items"][itemIndex]["isExpanded"] =
          !_computedGroups[groupIndex]["items"][itemIndex]["isExpanded"];
      _allGroupsExpanded = false;
    });
  }

  // -------------------------------------------------------------------

  /// Firestore의 값을 수정한 후 실시간 반영을 위해 EditDialogContent에서 값이 변경되면
  /// Firestore 업데이트 후 Overlay 메시지를 띄워줍니다.
  Future<void> _showEditDialog(
    BuildContext context,
    String key,
    String name,
    String value,
    String itemId,
    String subItemId,
  ) async {
    final newValue = await showDialog<String>(
      context: context,
      builder: (context) => EditDialogContent(
        keyField: key,
        fieldName: name,
        fieldValue: value,
        itemId: itemId,
        subItemId: subItemId,
      ),
    );

    if (newValue != null && newValue != value) {
      try {
        if (subItemId == '') {
          await FirebaseFirestore.instance
              .collection('Items')
              .doc(itemId)
              .update({key: newValue});
        } else {
          await FirebaseFirestore.instance
              .collection('Items') // 부모 컬렉션
              .doc(itemId) // 부모 문서 (itemId 기준)
              .collection('Sub_Items') // 하위 컬렉션
              .doc(subItemId) // 하위 문서 ID
              .update({key: newValue}); // 특정 필드값 변경
        }
        showOverlayMessage(context, '수정되었습니다.');
      } catch (error) {
        showOverlayMessage(context, '업데이트 중 오류가 발생했습니다.');
      }
    }
  }

  /// subItems의 필드값 변경까지 감지하기 위해 모든 내용을 문자열로 만들어 해시값을 계산합니다.
  String _computeSubItemsHash(Item item) {
    return item.subItems.map((subItem) {
      // 필드들의 key를 정렬하여 안정적인 문자열을 생성합니다.
      final sortedEntries = subItem.fields.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      final fieldsString =
          sortedEntries.map((e) => '${e.key}:${e.value}').join(',');
      return '${subItem.id}-$fieldsString';
    }).join('|');
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
      Flexible(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: '기본 정보 추가',
              onPressed: () async {
                await _showAddDialogItem(context, provider, widget.itemId);
              },
            ),
            // IconButton(icon: const Icon(Icons.attach_file), onPressed: () {}),
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
          ],
        ),
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
            surfaceTintColor: const Color.fromARGB(255, 234, 193, 255),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 50),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                        child: copyTextWidget(context,
                            text: '${matchedCategory['Name']}',
                            widgetType: TextWidgetType.plain,
                            style: AppTheme.textHintTextStyle
                                .copyWith(fontSize: 10))),
                    Flexible(
                      child: copyTextWidget(
                        context,
                        text: itemData.itemName,
                        widgetType: TextWidgetType.plain,
                        style: AppTheme.titleLargeTextStyle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // leading: const BackButton(),
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
                          itemData.itemTag, itemData.id, '');
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
                                                  itemData.id,
                                                  '');
                                            },
                                          ),
                                        )
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    copyTextWidget(context,
                                        text: formatNumber(entry.value),
                                        widgetType: TextWidgetType.textField,
                                        controller: TextEditingController(
                                            text: formatNumber(entry.value)),
                                        style: AppTheme.bodySmallTextStyle,
                                        maxLines: 0)
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
    // 기존의 subItems 개수 비교 대신 subItems의 해시값을 계산하여 내용 변경까지 감지합니다.
    final newHash = _computeSubItemsHash(item);
    if (newHash != _lastSubItemsHash) {
      _lastSubItemsHash = newHash;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _updateComputedGroups(item);
        }
      });
    }

    Widget content = Stack(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(0.0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '추가 정보',
                        style: AppTheme.textCGreyStyle.copyWith(
                          fontSize: 16,
                          color: AppTheme.text5Color.withOpacity(0.3),
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size(0, 0),
                        ),
                        onPressed: _toggleAllGroups,
                        child: Text(
                          _allGroupsExpanded ? "모두 닫기" : "모두 열기",
                          style:
                              AppTheme.textHintTextStyle.copyWith(fontSize: 11),
                        ),
                      ),
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
                      elevation: 0,
                      child: Column(
                        children: [
                          ListTile(
                            dense: true,
                            minVerticalPadding: 0,
                            visualDensity: VisualDensity(vertical: -4),
                            title: Padding(
                              padding:
                                  const EdgeInsets.only(left: 20, right: 50),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    group["groupTitle"],
                                    style:
                                        AppTheme.fieldLabelTextStyle.copyWith(
                                      color:
                                          AppTheme.text9Color.withOpacity(0.3),
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  const Expanded(
                                    child: Divider(
                                      color: AppTheme.text9Color,
                                      thickness: 0.2,
                                    ),
                                  )
                                ],
                              ),
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
                                            tileColor: AppTheme.text5Color
                                                .withOpacity(0.03),
                                            contentPadding:
                                                const EdgeInsets.fromLTRB(
                                                    0, 0, 55, 0),
                                            dense: true,
                                            minVerticalPadding: 0,
                                            visualDensity: const VisualDensity(
                                                vertical: -4),
                                            title: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                MenuAnchor(
                                                  builder: (context, controller,
                                                      child) {
                                                    return TextButton.icon(
                                                      style:
                                                          TextButton.styleFrom(
                                                        padding:
                                                            EdgeInsets.zero,
                                                        minimumSize:
                                                            const Size(50, 30),
                                                      ),
                                                      label: Text(
                                                        itemData['subOrder'] ??
                                                            '-',
                                                        style: AppTheme
                                                            .tagTextStyle
                                                            .copyWith(
                                                          fontSize: 8,
                                                        ),
                                                      ),
                                                      icon: const Icon(
                                                        Icons
                                                            .label_important_sharp,
                                                        color:
                                                            AppTheme.text5Color,
                                                        size: 10,
                                                      ),
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
                                                      leadingIcon: const Icon(Icons
                                                          .edit_note_outlined),
                                                      child: const Text(
                                                        'Edit',
                                                        style: AppTheme
                                                            .textLabelStyle,
                                                      ),
                                                      onPressed: () async {
                                                        await _showAddDialogSubItem(
                                                            context,
                                                            provider,
                                                            widget.itemId,
                                                            itemData);
                                                      },
                                                    ),
                                                    MenuItemButton(
                                                      leadingIcon: const Icon(Icons
                                                          .delete_forever_outlined),
                                                      child: const Text(
                                                        'Delete',
                                                        style: AppTheme
                                                            .textLabelStyle,
                                                      ),
                                                      onPressed: () async {
                                                        FiDeleteDialog(
                                                          context: context,
                                                          deleteFunction:
                                                              () async {
                                                            FirebaseFirestore
                                                                .instance
                                                                .collection(
                                                                    'Items')
                                                                .doc(widget
                                                                    .itemId)
                                                                .collection(
                                                                    'Sub_Items')
                                                                .doc(itemData[
                                                                    'id'])
                                                                .delete();
                                                          },
                                                          shouldCloseScreen:
                                                              false,
                                                        );
                                                      },
                                                    ),
                                                    MenuItemButton(
                                                      leadingIcon: const Icon(Icons
                                                          .add_to_photos_outlined),
                                                      child: const Text(
                                                        '속성 추가',
                                                        style: AppTheme
                                                            .textLabelStyle,
                                                      ),
                                                      onPressed: () async {
                                                        await _showAddAttributeDialog(
                                                            context,
                                                            provider,
                                                            widget.itemId,
                                                            itemData);
                                                        _toggleAllItemsInGroup(
                                                            groupIndex);
                                                      },
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  '${itemData["title"]}',
                                                  style: AppTheme
                                                      .fieldLabelTextStyle
                                                      .copyWith(
                                                    color:
                                                        AppTheme.primaryColor,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            onTap: () => _toggleItemExpansion(
                                                groupIndex, itemIndex),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                // 필요에 따라 trailing 버튼 추가
                                              ],
                                            ),
                                          ),
                                          AnimatedSize(
                                            duration: const Duration(
                                                milliseconds: 300),
                                            curve: Curves.fastOutSlowIn,
                                            child: itemData["isExpanded"]
                                                ? SingleChildScrollView(
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 40),
                                                      child: Wrap(
                                                        spacing: 50.0,
                                                        runSpacing: 10.0,
                                                        children: (List.from(
                                                                itemData[
                                                                    "attributes"])
                                                              ..sort((a, b) {
                                                                final aOrder =
                                                                    (a['FieldOrder']
                                                                            ?.toString() ??
                                                                        '9999');
                                                                final bOrder =
                                                                    (b['FieldOrder']
                                                                            ?.toString() ??
                                                                        '9999');
                                                                return int.parse(
                                                                        aOrder)
                                                                    .compareTo(
                                                                        int.parse(
                                                                            bOrder));
                                                              }))
                                                            .map<Widget>(
                                                                (attribute) {
                                                          return LayoutBuilder(
                                                            builder: (context,
                                                                constraints) {
                                                              return Card(
                                                                elevation: 0,
                                                                margin:
                                                                    const EdgeInsets
                                                                        .all(0),
                                                                child:
                                                                    IntrinsicWidth(
                                                                  child:
                                                                      Container(
                                                                    child: Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .start,
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .min,
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .center,
                                                                      children: [
                                                                        // 필드 이름 표시

                                                                        copyTextWidget(
                                                                          context,
                                                                          text:
                                                                              "${attribute['FieldName']}",
                                                                          widgetType:
                                                                              TextWidgetType.plain,
                                                                          style: AppTheme
                                                                              .bodySmallTextStyle
                                                                              .copyWith(
                                                                            fontSize:
                                                                                13,
                                                                            fontWeight:
                                                                                FontWeight.w600,
                                                                            color:
                                                                                AppTheme.text4Color,
                                                                          ),
                                                                        ),

                                                                        const SizedBox(
                                                                            width:
                                                                                5),
                                                                        IconButton(
                                                                          padding:
                                                                              EdgeInsets.zero,
                                                                          visualDensity: const VisualDensity(
                                                                              horizontal: -4,
                                                                              vertical: -4),
                                                                          constraints:
                                                                              const BoxConstraints(
                                                                            minWidth:
                                                                                10,
                                                                            minHeight:
                                                                                10,
                                                                          ),
                                                                          tooltip:
                                                                              "Edit",
                                                                          icon:
                                                                              Icon(
                                                                            Icons.edit,
                                                                            size:
                                                                                10,
                                                                            color:
                                                                                AppTheme.toolColor,
                                                                          ),
                                                                          onPressed:
                                                                              () {
                                                                            _showEditDialog(
                                                                              context,
                                                                              attribute['FieldKey'],
                                                                              attribute['FieldName'],
                                                                              attribute['FieldValue'],
                                                                              widget.itemId,
                                                                              itemData['id'],
                                                                            );
                                                                          },
                                                                        ),
                                                                        const SizedBox(
                                                                            width:
                                                                                15),
                                                                        // 필드 값 표시 (읽기 전용 TextField)
                                                                        Flexible(
                                                                          child: copyTextWidget(
                                                                              context,
                                                                              text: formatNumber(attribute['FieldValue']),
                                                                              widgetType: TextWidgetType.textField,
                                                                              controller: TextEditingController(text: formatNumber(attribute['FieldValue'])),
                                                                              style: AppTheme.bodySmallTextStyle.copyWith(fontSize: 13),
                                                                              maxLines: 0),
                                                                        ),
                                                                        const SizedBox(
                                                                            width:
                                                                                5),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                          );
                                                        }).toList(),
                                                      ),
                                                    ),
                                                  )
                                                : const SizedBox.shrink(),
                                          ),
                                          const SizedBox(height: 10),
                                        ],
                                      );
                                    }).toList(),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 5),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        // 플로팅 버튼 (Stack 내 Positioned로 배치)
        Positioned(
          bottom: 16,
          right: 16,
          width: 40,
          height: 40,
          child: FloatingActionButton(
            elevation: 2,
            backgroundColor: AppTheme.text5Color.withOpacity(0.4),
            hoverColor: AppTheme.text5Color.withOpacity(0.8),
            tooltip: '추가 정보 입력',
            onPressed: () async {
              await _showAddDialogSubItem(
                  context, provider, widget.itemId, null);
            },
            child: const Icon(
              Icons.add,
              color: AppTheme.buttonlightbackgroundColor,
            ),
          ),
        ),
      ],
    );

    return widget.viewSelect < 2
        ? content
        : SingleChildScrollView(child: content);
  }
}

// ============================================================================
// 1. 기본 정보(항목) 추가 다이얼로그
// ============================================================================
class AddDialogItemField extends StatefulWidget {
  final ItemProvider itemProvider;
  final String itemId;
  final Item? item;

  const AddDialogItemField({
    Key? key,
    required this.itemProvider,
    required this.itemId,
    required this.item,
  }) : super(key: key);

  @override
  _AddDialogItemFieldState createState() => _AddDialogItemFieldState();
}

class _AddDialogItemFieldState extends State<AddDialogItemField> {
  String? selectedKey;
  String? labelKo;
  late TextEditingController value1Controller;
  late ScrollController defaultScrollController;

  @override
  void initState() {
    super.initState();
    value1Controller = TextEditingController();
    defaultScrollController = ScrollController();
  }

  @override
  void dispose() {
    value1Controller.dispose();
    defaultScrollController.dispose();
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
            DropdownMenu<String>(
              initialSelection: selectedKey,
              requestFocusOnTap: false,
              expandedInsets: const EdgeInsets.all(15),
              label: const Text('항목 선택'),
              dropdownMenuEntries: () {
                final sortedKeys = widget.itemProvider.fieldMappings.keys
                    .where((key) =>
                        widget.itemProvider.fieldMappings[key]?['IsDefault'] ==
                        true)
                    .toList();
                sortedKeys.sort((a, b) {
                  final orderA =
                      widget.itemProvider.fieldMappings[a]?['FieldOrder'] ?? 0;
                  final orderB =
                      widget.itemProvider.fieldMappings[b]?['FieldOrder'] ?? 0;
                  return orderA.compareTo(orderB);
                });
                return sortedKeys
                    .map(
                      (key) => DropdownMenuEntry<String>(
                        labelWidget: Text(
                          widget.itemProvider.fieldMappings[key]
                                  ?['FieldName'] ??
                              key,
                          style: AppTheme.textLabelStyle,
                        ),
                        value: key,
                        label: widget.itemProvider.fieldMappings[key]
                                ?['FieldName'] ??
                            key,
                      ),
                    )
                    .toList();
              }(),
              onSelected: (String? newValue) {
                setState(() {
                  selectedKey = newValue;
                  labelKo = widget.itemProvider.fieldMappings[selectedKey]
                          ?['FieldName'] ??
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
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: TextField(
                      controller: value1Controller,
                      decoration: InputDecoration(
                        suffixIcon: ClearButton(controller: value1Controller),
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
            const SizedBox(height: 20),
            // 버튼 영역
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
                    if (selectedKey == null) {
                      showOverlayMessage(context, "항목을 선택해주세요.");
                      return;
                    }
                    final String defaultValue = value1Controller.text.trim();
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
                        showOverlayMessage(context, "'$labelKo' 항목이 이미 존재합니다.");
                        return;
                      }
                    }
                    await docRef.set(
                        {selectedKey!: defaultValue}, SetOptions(merge: true));
                    Navigator.of(context).pop();
                    showOverlayMessage(context, '항목을 추가하였습니다.');
                  },
                  child: const Text("Add"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 2. 추가 정보(서브 아이템) 추가 다이얼로그
// ============================================================================
class AddDialogSubItemField extends StatefulWidget {
  final String itemId;
  final Item? item;
  final dynamic itemData;

  const AddDialogSubItemField({
    Key? key,
    required this.itemId,
    required this.item,
    required this.itemData,
  }) : super(key: key);

  @override
  _AddDialogSubItemFieldState createState() => _AddDialogSubItemFieldState();
}

class _AddDialogSubItemFieldState extends State<AddDialogSubItemField> {
  List<Map<String, dynamic>> computedGroups = [];
  String? selectedGroup;
  late TextEditingController groupController;
  late TextEditingController value2Controller;
  late TextEditingController orderController;
  late ScrollController addScrollController;
  bool isAddmode = true;

  @override
  void initState() {
    super.initState();
    groupController = TextEditingController();
    value2Controller = TextEditingController();
    orderController = TextEditingController();

    addScrollController = ScrollController();
    if (widget.item != null) {
      computedGroups = _computeGroupsFromItem(widget.item!);
      if (computedGroups.isNotEmpty) {
        selectedGroup = computedGroups[0]["groupTitle"];
      }
    }

    if (widget.itemData != null) isAddmode = false;
    if (!isAddmode) {
      selectedGroup = widget.itemData['subItem'] ?? '';
      value2Controller.text = widget.itemData['title'] ?? '';
      orderController.text = widget.itemData['subOrder'] ?? '';
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
    groupController.dispose();
    value2Controller.dispose();
    orderController.dispose();
    addScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 그룹 선택에 따라 다이얼로그 내 높이를 조절할 수 있음
    return SingleChildScrollView(
      padding: const EdgeInsets.all(15.0),
      child: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                '${widget.item?.itemName ?? ""} - ${isAddmode ? '추가 정보' : '편집'}',
                style: AppTheme.appbarTitleTextStyle),
            const SizedBox(height: 20),
            DropdownMenu<String>(
              requestFocusOnTap: false,
              expandedInsets: const EdgeInsets.all(15),
              label: const Text('그룹'),
              initialSelection: selectedGroup,
              dropdownMenuEntries: [
                DropdownMenuEntry<String>(
                  labelWidget: Text('새 그룹 생성',
                      style: AppTheme.textLabelStyle
                          .copyWith(color: AppTheme.text4Color)),
                  value: '신규',
                  label: '새 그룹 생성',
                ),
                ...computedGroups.map(
                  (group) => DropdownMenuEntry<String>(
                    value: group["groupTitle"],
                    label: group["groupTitle"],
                    labelWidget: Text(group["groupTitle"],
                        style: AppTheme.textLabelStyle),
                  ),
                ),
              ],
              onSelected: (String? newValue) {
                setState(() {
                  selectedGroup = newValue;
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
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: TextField(
                        controller: groupController,
                        decoration: InputDecoration(
                          suffixIcon: ClearButton(controller: groupController),
                          contentPadding: const EdgeInsets.all(15),
                          labelText: '새 그룹명',
                          hintText: "예) 음식메뉴, 객실, 이용권, 기타..",
                          border: const OutlineInputBorder(),
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                children: [
                  TextField(
                    controller: value2Controller,
                    decoration: InputDecoration(
                      suffixIcon: ClearButton(controller: value2Controller),
                      contentPadding: const EdgeInsets.all(15),
                      labelText: '서브 아이템명',
                      hintText: "예) 메뉴명, 객실명, 서비스명",
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 1,
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: orderController,
                    decoration: InputDecoration(
                      suffixIcon: ClearButton(controller: orderController),
                      contentPadding: const EdgeInsets.all(15),
                      labelText: '순서',
                      hintText: '예) 1, 2, 3 ...',
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // 버튼 영역
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
                    final String subItemName = value2Controller.text.trim();
                    final String subItemOrder = orderController.text.trim();

                    // 1️⃣ 필수 입력 값 체크
                    if (subItemName.isEmpty) {
                      showOverlayMessage(context, "서브 아이템명을 입력해주세요.");
                      return;
                    }
                    if (selectedGroup == null) {
                      showOverlayMessage(context, "그룹을 선택해주세요.");
                      return;
                    }

                    // 2️⃣ 신규 그룹 생성 시 이름 체크
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

                    // 3️⃣ Firestore 경로 설정
                    final String subCollectionPath =
                        'Items/${widget.itemId}/Sub_Items';
                    String documentId = widget.itemData?['id'] ??
                        FirebaseFirestore.instance
                            .collection(subCollectionPath)
                            .doc()
                            .id;
                    final docRef = FirebaseFirestore.instance
                        .collection(subCollectionPath)
                        .doc(documentId);

                    // 4️⃣ 기존 데이터 가져오기 (수정 모드일 경우)
                    Map<String, dynamic>? existingData;
                    if (!isAddmode) {
                      final docSnapshot = await docRef.get();
                      if (docSnapshot.exists) {
                        existingData = docSnapshot.data();
                      }
                    }

                    // 5️⃣ 변경된 값만 저장하기 위해 기존 데이터와 비교
                    final Map<String, dynamic> newSubItemData = {
                      'SubName': subItemName,
                      'SubOrder': subItemOrder,
                      'SubItem': finalGroup,
                    };

                    if (isAddmode) {
                      // 6️⃣ 추가 모드: 새로운 문서 생성
                      await docRef.set(newSubItemData);
                    } else {
                      // 7️⃣ 수정 모드: 변경된 필드만 업데이트
                      final Map<String, dynamic> updatedFields = {};
                      newSubItemData.forEach((key, value) {
                        if (existingData == null ||
                            existingData[key] != value) {
                          updatedFields[key] = value;
                        }
                      });

                      if (updatedFields.isNotEmpty) {
                        await docRef.update(updatedFields);
                      }
                    }

                    // 8️⃣ 완료 후 UI 업데이트 및 메시지 표시
                    Navigator.of(context).pop();
                    showOverlayMessage(
                        context, '서브 아이템을 ${isAddmode ? '추가' : '수정'}하였습니다.');
                  },
                  child: Text(isAddmode ? 'Add' : 'Edit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 3. 다이얼로그 호출 함수
// ============================================================================

Future<void> _showAddDialogItem(
    BuildContext context, ItemProvider itemProvider, String itemId) async {
  final item = context.read<ItemDetailProvider>().getItemData(itemId);
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        child: AddDialogItemField(
            itemProvider: itemProvider, itemId: itemId, item: item),
      );
    },
  );
}

Future<void> _showAddDialogSubItem(BuildContext context,
    ItemProvider itemProvider, String itemId, var itemData) async {
  final item = context.read<ItemDetailProvider>().getItemData(itemId);
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        child: AddDialogSubItemField(
            itemId: itemId, item: item, itemData: itemData),
      );
    },
  );
}

Future<void> _showAddAttributeDialog(BuildContext context,
    ItemProvider itemProvider, String itemId, var itemData) async {
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        child: AddAttributeDialog(
          itemProvider: itemProvider,
          itemId: itemId,
          itemData: itemData,
        ),
      );
    },
  );
}

class EditDialogContent extends StatefulWidget {
  final String keyField; // 예: 'keyword'
  final String fieldName;
  final String fieldValue;
  final String itemId;
  final String subItemId;

  const EditDialogContent({
    Key? key,
    required this.keyField,
    required this.fieldName,
    required this.fieldValue,
    required this.itemId,
    required this.subItemId,
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
                  onPressed: () {
                    FiDeleteDialog(
                      context: context,
                      deleteFunction: () async {
                        if (widget.subItemId == '') {
                          await FirebaseFirestore.instance
                              .collection('Items')
                              .doc(widget.itemId)
                              .update({widget.keyField: FieldValue.delete()});
                        } else {
                          await FirebaseFirestore.instance
                              .collection('Items') // 부모 컬렉션
                              .doc(widget.itemId) // 부모 문서 (itemId 기준)
                              .collection('Sub_Items') // 하위 컬렉션
                              .doc(widget.subItemId) // 하위 문서 ID
                              .update({widget.keyField: FieldValue.delete()});
                        }
                      },
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
                      decoration: InputDecoration(
                        suffixIcon: ClearButton(controller: textController),
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
                        Navigator.pop(context); // 취소 시 null 반환
                      },
                      child: const Text("취소"),
                    ),
                    TextButton(
                      onPressed: () {
                        // 저장 시 입력한 값을 반환합니다.
                        Navigator.pop(context, textController.text);
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

class AddAttributeDialog extends StatefulWidget {
  final ItemProvider itemProvider;
  final String itemId;
  final Map<String, dynamic> itemData;

  const AddAttributeDialog({
    Key? key,
    required this.itemProvider,
    required this.itemId,
    required this.itemData,
  }) : super(key: key);

  @override
  _AddAttributeDialogState createState() => _AddAttributeDialogState();
}

class _AddAttributeDialogState extends State<AddAttributeDialog> {
  // _keyController는 사용하지 않으므로 제거했습니다.
  late TextEditingController _valueController;
  late ScrollController defaultScrollController;
  String? selectedKey;
  String? labelKo;

  @override
  void initState() {
    super.initState();
    _valueController = TextEditingController();
    defaultScrollController = ScrollController();
  }

  @override
  void dispose() {
    _valueController.dispose();
    defaultScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('속성 추가', style: AppTheme.appbarTitleTextStyle),
              const SizedBox(height: 20),
              DropdownMenu<String>(
                initialSelection: selectedKey,
                requestFocusOnTap: false,
                expandedInsets: const EdgeInsets.all(15),
                label: const Text('항목 선택'),
                dropdownMenuEntries: () {
                  final sortedKeys = widget.itemProvider.fieldMappings.keys
                      .where((key) =>
                          widget.itemProvider.fieldMappings[key]
                                  ?['IsDefault'] ==
                              false &&
                          key != 'SubItem' &&
                          key != 'SubName' &&
                          key != 'SubOrder') // 특정 키 제외
                      .toList();

                  sortedKeys.sort((a, b) {
                    final orderA = int.tryParse(widget
                                .itemProvider.fieldMappings[a]?['FieldOrder']
                                ?.toString() ??
                            "0") ??
                        0;
                    final orderB = int.tryParse(widget
                                .itemProvider.fieldMappings[b]?['FieldOrder']
                                ?.toString() ??
                            "0") ??
                        0;
                    return orderA.compareTo(orderB);
                  });

                  return sortedKeys
                      .map(
                        (key) => DropdownMenuEntry<String>(
                          labelWidget: Text(
                            widget.itemProvider.fieldMappings[key]
                                    ?['FieldName'] ??
                                key,
                            style: AppTheme.textLabelStyle,
                          ),
                          value: key,
                          label: widget.itemProvider.fieldMappings[key]
                                  ?['FieldName'] ??
                              key,
                        ),
                      )
                      .toList();
                }(),
                onSelected: (String? newValue) {
                  setState(() {
                    selectedKey = newValue;
                    labelKo = widget.itemProvider.fieldMappings[selectedKey]
                            ?['FieldName'] ??
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
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: TextField(
                        controller: _valueController,
                        decoration: InputDecoration(
                          suffixIcon: ClearButton(controller: _valueController),
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
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('취소'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (selectedKey == null) {
                        showOverlayMessage(context, "항목을 선택해주세요.");
                        return;
                      }
                      final value = _valueController.text.trim();
                      if (value.isEmpty) {
                        showOverlayMessage(context, "값을 입력해주세요.");
                        return;
                      }

                      final docRef = FirebaseFirestore.instance
                          .collection('Items')
                          .doc(widget.itemId)
                          .collection('Sub_Items')
                          .doc(widget.itemData["id"]);
                      final docSnapshot = await docRef.get();
                      if (docSnapshot.exists) {
                        final existingData = docSnapshot.data() ?? {};
                        if (existingData.containsKey(selectedKey)) {
                          showOverlayMessage(
                              context, "'$labelKo' 항목이 이미 존재합니다.");
                          return;
                        }
                      }
                      try {
                        await FirebaseFirestore.instance
                            .collection('Items')
                            .doc(widget.itemId)
                            .collection('Sub_Items')
                            .doc(widget.itemData["id"])
                            .update({selectedKey!: value});
                        showOverlayMessage(context, '속성이 추가되었습니다.');
                        Navigator.of(context).pop();
                      } catch (e) {
                        showOverlayMessage(context, "업데이트 실패: $e");
                      }
                    },
                    child: const Text('추가'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
