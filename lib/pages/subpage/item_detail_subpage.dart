// ignore_for_file: public_member_api_docs, sort_constructors_first
// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mp_db/pages/dialog/dialog_ImageView.dart';
import 'package:mp_db/pages/dialog/dialog_item_detail.dart';
import 'package:mp_db/utils/formatters.dart';
import 'package:provider/provider.dart';

import 'package:mp_db/Functions/firestore.dart';
import 'package:mp_db/constants/styles.dart';
import 'package:mp_db/pages/subpage/item_subpage.dart';
import 'package:mp_db/providers/Item_provider.dart';
import 'package:mp_db/utils/widget_help.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/item_model.dart';
import '../../providers/Item_detail/Item_detail_provider.dart';
import '../../providers/Item_detail/Item_detail_state.dart';

class ItemDetailSubpage extends StatefulWidget {
  const ItemDetailSubpage(
      {Key? key, required this.itemId, required this.viewSelect})
      : super(key: key);

  final String itemId;
  String get getItemId => itemId;
  final int viewSelect; // 0,1: fields 표시 / 2: sub_items 표시

  @override
  State<ItemDetailSubpage> createState() => _ItemDetailSubpageState();
}

class _ItemDetailSubpageState extends State<ItemDetailSubpage> {
  final TextEditingController _controller = TextEditingController();
  late final ItemProvider provider;
  final firestoreService = FirestoreService();

  /// Firebase의 subItems 데이터를 그룹화한 결과를 저장하는 상태 변수
  List<Map<String, dynamic>> _computedGroups = [];
  bool _allGroupsExpanded = true;
  Map<String, bool> _fileExistsMap = {};

  // subItems 내용 변경 감지를 위한 해시값 저장
  String _lastSubItemsHash = '';

  // Provider의 isToggleAllItem 변경 감지를 위한 이전 값 저장
  bool? _prevToggleState;

  @override
  void initState() {
    super.initState();
    provider = Provider.of<ItemProvider>(context, listen: false);
    // itemId 변경 시 Firestore 조회
    Future.microtask(() {
      Provider.of<ItemDetailProvider>(context, listen: false)
          .listenToItemDetail(itemId: widget.itemId);
    });

    // Provider에서 전달받은 isToggleAllItem 초기값 저장 및 리스너 등록
    final itemDetailProvider =
        Provider.of<ItemDetailProvider>(context, listen: false);
    _prevToggleState = itemDetailProvider.isToggleAllItem;
    itemDetailProvider.addListener(_onProviderToggleChanged);
  }

  Future<void> _checkFileExistence() async {
    for (var group in _computedGroups) {
      for (var item in group["items"]) {
        String folderName =
            'uploads/${provider.items.firstWhere((item) => item.id == widget.itemId)['ItemName']}/${item["title"]}';
        _updateFileExistence(folderName);
      }
    }
  }

  Future<void> _updateFileExistence(String folderName) async {
    bool exists = await _hasFiles(folderName);
    setState(() {
      _fileExistsMap[folderName] = exists;
    });
  }

  // 각 subItem 별 파일 여부를 확인하는는 함수
  Future<bool> _hasFiles(String folderName) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('files')
          .where('folder', isEqualTo: folderName)
          .limit(1) // 성능 최적화를 위해 1개만 가져옴
          .get();

      bool te = querySnapshot.docs.isNotEmpty;
      return te;
    } catch (e) {
      print("Error checking files in $folderName: $e");
      return false;
    }
  }

  bool _isFirstBuild = true;
  @override
  void didUpdateWidget(covariant ItemDetailSubpage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemId != widget.itemId) {
      _computedGroups = [];
      _lastSubItemsHash = '';
    }

    if (_isFirstBuild) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ItemProvider>().focusKeyboard();
      });
      _isFirstBuild = false;
    }
  }

  @override
  void dispose() {
    Provider.of<ItemDetailProvider>(context, listen: false)
        .cancelSubscription(widget.itemId);
    Provider.of<ItemDetailProvider>(context, listen: false)
        .removeListener(_onProviderToggleChanged);
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
        ..['id'] = subItem.id;
      // 그룹핑 진행
      groupedData.putIfAbsent(groupKey, () => []).add(fieldsWithId);
    }
    groupedData.forEach((groupKey, subItems) {
      subItems.sort((a, b) {
        int orderA = int.tryParse(a['SubOrder']?.toString() ?? "9999") ?? 9999;
        int orderB = int.tryParse(b['SubOrder']?.toString() ?? "9999") ?? 9999;
        return orderA.compareTo(orderB);
      });
    });
    // 그룹 정렬 : 그룹명 오름차순 정렬
    final sortedGroups = groupedData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    List<Map<String, dynamic>> groups = sortedGroups.map((entry) {
      final groupTitle = entry.key;
      final subItems = entry.value;
      final items = subItems.map<Map<String, dynamic>>((subItem) {
        final title = subItem['SubName']?.toString() ?? "(미지정)";
        final attributesMap = Map<String, dynamic>.from(subItem)
          ..remove('SubItem')
          ..remove('SubName')
          ..remove('SubOrder')
          ..remove('id');
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
          "id": subItem['id'],
          "subOrder": subItem['SubOrder'],
          "subItem": subItem['SubItem'],
          "title": title,
          //"isExpanded": subItems.length == 1, // 아이템이 1개면 true, 2개 이상이면 false
          "isExpanded": sortedGroups.length == 1 && subItems.length == 1, // 아이템이 1개면 true, 2개 이상이면 false
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
        _computedGroups[groupIndex]["isExpanded"] = _allGroupsExpanded;
        for (int itemIndex = 0;
            itemIndex < _computedGroups[groupIndex]["items"].length;
            itemIndex++) {
          _computedGroups[groupIndex]["items"][itemIndex]["isExpanded"] =
              _allGroupsExpanded;
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

  void _toggleAllItemsInGroup(int groupIndex, bool isToggle) {
    setState(() {
      bool newState = !_computedGroups[groupIndex]["items"][0]["isExpanded"];
      for (var item in _computedGroups[groupIndex]["items"]) {
        item["isExpanded"] = isToggle ? newState : true;
      }
    });
  }

  // Provider의 isToggleAllItem 값 변경 감지 시 호출될 리스너 함수
  void _onProviderToggleChanged() {
    final currentToggle =
        Provider.of<ItemDetailProvider>(context, listen: false).isToggleAllItem;
    if (currentToggle != _prevToggleState) {
      _toggleAllItems();
      _prevToggleState = currentToggle;
    }
  }

  // 전체 그룹의 모든 아이템을 현재 상태에 따라 토글:
  // 만약 하나라도 열려있다면 모두 닫고, 그렇지 않다면 모두 여는 로직 적용
  void _toggleAllItems() {
    bool anyOpen = _computedGroups.any(
        (group) => group["items"].any((item) => item["isExpanded"] == true));
    bool newState = anyOpen ? false : true;
    setState(() {
      for (var group in _computedGroups) {
        for (var item in group["items"]) {
          item["isExpanded"] = newState;
        }
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
    bool isDefault,
  ) async {
    final result = await showDialog(
      context: context,
      builder: (context) => EditDialogContent(
        itemProvider: provider,
        keyField: key,
        itemName:
            provider.items.firstWhere((item) => item.id == itemId)['ItemName'],
        fieldName: name,
        fieldValue: value,
        itemId: itemId,
        subItemId: subItemId,
        isDefault: isDefault,
      ),
    );

    if (result != null) {
      String newKey = result['key']; // 사용자가 입력한 새로운 키
      String newValue = result['value']; // 사용자가 입력한 새로운 값

      try {
        if (subItemId.isEmpty) {
          DocumentReference docRef =
              FirebaseFirestore.instance.collection('Items').doc(itemId);

          if (newKey != key) {
            // 새 키가 기존 키와 다르면 새로운 키로 추가하고 기존 키 삭제
            await docRef.update({
              newKey: newValue,
              key: FieldValue.delete(), // 기존 키 삭제
            });
          } else {
            // 동일 키이면 값만 업데이트
            await docRef.update({key: newValue});
          }
        } else {
          DocumentReference docRef = FirebaseFirestore.instance
              .collection('Items')
              .doc(itemId)
              .collection('Sub_Items')
              .doc(subItemId);

          if (newKey != key) {
            await docRef.update({
              newKey: newValue,
              key: FieldValue.delete(),
            });
          } else {
            await docRef.update({key: newValue});
          }
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
      // 에러 메시지가 "아이템을 찾을 수 없습니다."인 경우 "삭제 완료"로 변경
      bool isItemNotFound = state.error.message == "아이템을 찾을 수 없습니다.";
      String displayMessage =
          isItemNotFound ? "삭제 완료" : "에러 발생: ${state.error.message}";
      Color textColor = isItemNotFound ? AppTheme.text8Color : Colors.red;

      return widget.viewSelect < 2
          ? Padding(
              padding: const EdgeInsets.all(50.0),
              child: Text(
                displayMessage,
                style: TextStyle(color: textColor),
              ),
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
            if (_fileExistsMap['uploads/${itemData.itemName}'] == true) ...[
              IconButton(
                // 기본 정보의 아이콘
                icon: const Icon(
                  Icons.image_outlined,
                  color: AppTheme.text5Color,
                ),
                tooltip: '사진 정보',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ImageGridScreen(
                          folderName: 'uploads/${itemData.itemName}'),
                    ),
                  ).then((_) {
                    // 화면이 닫힐 때 _checkFileExistence 실행
                    _updateFileExistence('uploads/${itemData.itemName}');
                  });
                },
              ),
            ],
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
                    await FiDeleteDialog(
                        context: context,
                        deleteFunction: () async => firestoreService.deleteItem(
                            collectionName: 'Items', documentId: widget.itemId),
                        shouldCloseScreen: false);
                    provider.removeTab(provider.selectedIndex);
                  },
                ),
                MenuItemButton(
                  leadingIcon: const Icon(Icons.image_outlined),
                  child: const Text('사진 추가', style: AppTheme.textLabelStyle),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ImageGridScreen(
                            folderName: 'uploads/${itemData.itemName}'),
                      ),
                    ).then((_) {
                      // 화면이 닫힐 때 _checkFileExistence 실행
                      _updateFileExistence('uploads/${itemData.itemName}');
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    ];

    /// 이미지 URL을 브라우저에서 열기 위한 함수
    Future<void> _launchURL(String url) async {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    }

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
                Icon(
                  icon,
                  color: color,
                  size: 50,
                ),
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
                      child: GestureDetector(
                        onDoubleTap: () => _launchURL(
                            "https://map.naver.com/p/search/${itemData.itemName}"),
                        child: Tooltip(
                          message: "길게 누르기 : 클립보드 복사\n더블 클릭 : 네이버 지도 검색",
                          child: copyTextWidget(
                            context,
                            text: itemData.itemName,
                            widgetType: TextWidgetType.plain,
                            style: AppTheme.titleLargeTextStyle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
      final orderA = int.tryParse(
              fields[entryA.key]?['FieldOrder']?.toString() ?? '9999') ??
          9999;
      final orderB = int.tryParse(
              fields[entryB.key]?['FieldOrder']?.toString() ?? '9999') ??
          9999;
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
                          itemData.itemTag, itemData.id, '', true);
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
                          final dynamic result =
                              formatValue(context, entry.value);
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
                                        copyTextWidget(
                                          context,
                                          text: label,
                                          widgetType: TextWidgetType.selectable,
                                          style: AppTheme.fieldLabelTextStyle,
                                        ),
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
                                                itemProvider.fieldMappings[entry
                                                        .key]?['FieldName'] ??
                                                    entry.key,
                                                entry.value,
                                                itemData.id,
                                                '',
                                                true,
                                              );
                                            },
                                          ),
                                        )
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Flexible(
                                      child: result is Widget
                                          ? result
                                          : copyTextWidget(context,
                                              text: result,
                                              widgetType:
                                                  TextWidgetType.textField,
                                              controller: TextEditingController(
                                                  text: result),
                                              style: AppTheme.bodySmallTextStyle
                                                  .copyWith(fontSize: 13),
                                              maxLines: 0),
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
    // subItems의 해시값을 계산하여 내용 변경 감지
    final newHash = _computeSubItemsHash(item);
    if (newHash != _lastSubItemsHash) {
      _lastSubItemsHash = newHash;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _updateComputedGroups(item);
          _checkFileExistence();
        }
      });
    }

    Widget subitemList = ListView.builder(
      shrinkWrap: widget.viewSelect == 0 ? true : false,
      //  physics: const NeverScrollableScrollPhysics(),
      itemCount: _computedGroups.length,
      itemBuilder: (context, groupIndex) {
        final group = _computedGroups[groupIndex];

        ///---------------------------------------------------------------------------------- 아이템 그룹
        return Card(
          elevation: 0,
          child: Column(
            children: [
              Tooltip(
                message: '클릭 : 열기/닫기\n길게 누르기 : 그룹명 변경',
                decoration: BoxDecoration(
                  color: AppTheme.text9Color.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                ),
                child: ListTile(
                  dense: true,
                  minVerticalPadding: 0,
                  visualDensity: VisualDensity(vertical: -4),
                  title: Padding(
                    padding: const EdgeInsets.only(left: 20, right: 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Text(
                          group["groupTitle"],
                          style: AppTheme.bodySmallTextStyle.copyWith(
                            color: AppTheme.text9Color.withOpacity(0.3),
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 20),
                        const Expanded(
                          child: Divider(
                            color: AppTheme.text9Color,
                            thickness: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  onTap: () => _toggleGroupExpansion(groupIndex),
                  onLongPress: () => _showRenameGroupDialog(groupIndex),
                ),
              ),

              ///---------------------------------------------------------------------------------- 아이템
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.fastOutSlowIn,
                child: group["isExpanded"]
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // TextButton.icon(
                          //   style: TextButton.styleFrom(
                          //     minimumSize: Size(0, 30),
                          //     padding: EdgeInsets.symmetric(horizontal: 8),
                          //   ),
                          //   label: Text(
                          //     '아이템',
                          //     style:
                          //         AppTheme.tagTextStyle.copyWith(fontSize: 11),
                          //   ),
                          //   onPressed: () {
                          //     _toggleAllItemsInGroup(groupIndex, true);
                          //   },
                          //   icon: Icon(
                          //     !_computedGroups[groupIndex]["items"]
                          //             .whereType<
                          //                 Map<String,
                          //                     dynamic>>() // 리스트 내 요소의 타입을 확실하게 변환
                          //             .any((item) => item["isExpanded"] == true)
                          //         ? Icons.expand_less
                          //         : Icons.expand_more,
                          //     size: 20,
                          //     color: AppTheme.textHintTextStyle.color,
                          //   ),
                          // ),
                          Column(
                            children: group["items"]
                                .asMap()
                                .entries
                                .map<Widget>((entry) {
                              int itemIndex = entry.key;
                              var itemData = entry.value;
                              String folderName =
                                  'uploads/${item.itemName}/${itemData["title"]}';
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Tooltip(
                                    message: '클릭 : 열기/닫기\n길게 누르기 : 아이템 추가',
                                    child: ListTile(
                                      tileColor:
                                          AppTheme.text5Color.withOpacity(0.03),
                                      contentPadding: const EdgeInsets.fromLTRB(
                                          0, 0, 55, 0),
                                      dense: true,
                                      minVerticalPadding: 0,
                                      visualDensity:
                                          const VisualDensity(vertical: -4),
                                      title: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Tooltip(
                                            message: '아이템 메뉴',
                                            child: MenuAnchor(
                                              // ----------------------------------- 메뉴 버튼
                                              builder:
                                                  (context, controller, child) {
                                                return TextButton.icon(
                                                  style: TextButton.styleFrom(
                                                    padding: EdgeInsets.zero,
                                                    minimumSize:
                                                        const Size(50, 30),
                                                  ),
                                                  label: Text(
                                                    itemData['subOrder'] ?? '-',
                                                    style: AppTheme.tagTextStyle
                                                        .copyWith(
                                                            fontSize: 8,
                                                            color: AppTheme
                                                                .buttonlightbackgroundColor),
                                                  ),
                                                  icon: const Icon(
                                                    Icons.label_important_sharp,
                                                    color: AppTheme.text5Color,
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
                                                  // ----------- 메뉴아이템: 수정
                                                  leadingIcon: const Icon(
                                                      Icons.edit_note_outlined),
                                                  child: const Text(
                                                    'Edit',
                                                    style:
                                                        AppTheme.textLabelStyle,
                                                  ),
                                                  onPressed: () async {
                                                    await showAddDialogSubItem(
                                                        context,
                                                        provider,
                                                        widget.itemId,
                                                        itemData);
                                                  },
                                                ),
                                                MenuItemButton(
                                                  // ----------- 메뉴아이템: 삭제
                                                  leadingIcon: const Icon(Icons
                                                      .delete_forever_outlined),
                                                  child: const Text(
                                                    'Delete',
                                                    style:
                                                        AppTheme.textLabelStyle,
                                                  ),
                                                  onPressed: () async {
                                                    FiDeleteDialog(
                                                      context: context,
                                                      deleteFunction: () async {
                                                        FirebaseFirestore
                                                            .instance
                                                            .collection('Items')
                                                            .doc(widget.itemId)
                                                            .collection(
                                                                'Sub_Items')
                                                            .doc(itemData['id'])
                                                            .delete();
                                                      },
                                                      shouldCloseScreen: false,
                                                    );
                                                  },
                                                ),
                                                MenuItemButton(
                                                  // ----------- 메뉴아이템: 속성 추가
                                                  leadingIcon: const Icon(Icons
                                                      .add_to_photos_outlined),
                                                  child: const Text(
                                                    '속성 추가',
                                                    style:
                                                        AppTheme.textLabelStyle,
                                                  ),
                                                  onPressed: () async {
                                                    await _showAddAttributeDialog(
                                                        context,
                                                        provider,
                                                        widget.itemId,
                                                        itemData);
                                                    _toggleAllItemsInGroup(
                                                        groupIndex, false);
                                                  },
                                                ),
                                                MenuItemButton(
                                                  // ----------- 메뉴아이템: 사진 추가
                                                  leadingIcon: const Icon(
                                                      Icons.image_outlined),
                                                  child: const Text(
                                                    '사진 추가',
                                                    style:
                                                        AppTheme.textLabelStyle,
                                                  ),
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            ImageGridScreen(
                                                                folderName:
                                                                    folderName),
                                                      ),
                                                    ).then((_) {
                                                      // 화면이 닫힐 때 _checkFileExistence 실행
                                                      _updateFileExistence(
                                                          folderName);
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            '${itemData["title"]}',
                                            style: AppTheme.fieldLabelTextStyle
                                                .copyWith(
                                              color: _computedGroups[groupIndex]
                                                                      ["items"]
                                                                  [itemIndex]
                                                              ["attributes"]
                                                          .length >
                                                      0
                                                  ? const Color.fromARGB(255, 128, 46, 46) // 아이템 색상
                                                  : const Color.fromARGB(122, 128, 46, 46),
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          if (_fileExistsMap[folderName] ==
                                              true) ...[
                                            IconButton(
                                              constraints: const BoxConstraints(
                                                  minWidth: 0, minHeight: 0),
                                              icon: Icon(Icons.image_outlined,
                                                  color: AppTheme.text5Color,
                                                  size: 13),
                                              tooltip: '사진 정보',
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        ImageGridScreen(
                                                            folderName:
                                                                folderName),
                                                  ),
                                                ).then((_) {
                                                  // 화면이 닫힐 때 _checkFileExistence 실행
                                                  _updateFileExistence(
                                                      folderName);
                                                });
                                              },
                                            )
                                          ],
                                        ],
                                      ),
                                      onTap: () => _toggleItemExpansion(
                                          groupIndex, itemIndex),
                                      onLongPress: () async {
                                        await _showAddAttributeDialog(context,
                                            provider, widget.itemId, itemData);
                                        _toggleAllItemsInGroup(
                                            groupIndex, false);
                                      },
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // 필요에 따라 trailing 버튼 추가
                                        ],
                                      ),
                                    ),
                                  ),

                                  ///------------------------------------------------------------- 아이템 속성
                                  AnimatedSize(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.fastOutSlowIn,
                                    child: itemData["isExpanded"]
                                        ? SingleChildScrollView(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 40, right: 16),
                                              child: Wrap(
                                                spacing: 50.0,
                                                runSpacing: 10.0,
                                                children: (List.from(
                                                        itemData["attributes"])
                                                      ..sort((a, b) {
                                                        final aOrder = (a[
                                                                    'FieldOrder']
                                                                ?.toString() ??
                                                            '9999');
                                                        final bOrder = (b[
                                                                    'FieldOrder']
                                                                ?.toString() ??
                                                            '9999');
                                                        return int.parse(aOrder)
                                                            .compareTo(
                                                                int.parse(
                                                                    bOrder));
                                                      }))
                                                    .map<Widget>((attribute) {
                                                  return LayoutBuilder(
                                                    builder:
                                                        (context, constraints) {
                                                      final dynamic result =
                                                          formatValue(
                                                              context,
                                                              attribute[
                                                                  'FieldValue']);
                                                      return Card(
                                                        elevation: 0,
                                                        margin: const EdgeInsets
                                                            .all(0),
                                                        child: IntrinsicWidth(
                                                          child: Container(
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
                                                                copyTextWidget(
                                                                  context,
                                                                  text:
                                                                      "${attribute['FieldName']}",
                                                                  widgetType:
                                                                      TextWidgetType
                                                                          .selectable,
                                                                  style: AppTheme
                                                                      .bodySmallTextStyle
                                                                      .copyWith(
                                                                    fontSize:
                                                                        13,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color: AppTheme
                                                                        .text4Color,
                                                                  ),
                                                                ),
                                                                IconButton(
                                                                  padding:
                                                                      EdgeInsets
                                                                          .zero,
                                                                  visualDensity:
                                                                      const VisualDensity(
                                                                          horizontal:
                                                                              -4,
                                                                          vertical:
                                                                              -4),
                                                                  constraints: const BoxConstraints(
                                                                      minWidth:
                                                                          10,
                                                                      minHeight:
                                                                          10),
                                                                  tooltip:
                                                                      "Edit",
                                                                  icon: Icon(
                                                                    Icons.edit,
                                                                    size: 10,
                                                                    color: AppTheme
                                                                        .toolColor,
                                                                  ),
                                                                  onPressed:
                                                                      () {
                                                                    _showEditDialog(
                                                                      context,
                                                                      attribute[
                                                                          'FieldKey'],
                                                                      attribute[
                                                                          'FieldName'],
                                                                      attribute[
                                                                          'FieldValue'],
                                                                      widget
                                                                          .itemId,
                                                                      itemData[
                                                                          'id'],
                                                                      false,
                                                                    );
                                                                  },
                                                                ),
                                                                const SizedBox(
                                                                    width: 5),
                                                                Flexible(
                                                                  child: result
                                                                          is Widget
                                                                      ? result
                                                                      : copyTextWidget(
                                                                          context,
                                                                          text:
                                                                              result,
                                                                          widgetType:
                                                                              TextWidgetType.textField,
                                                                          controller:
                                                                              TextEditingController(text: result),
                                                                          style: AppTheme
                                                                              .bodySmallTextStyle
                                                                              .copyWith(fontSize: 13),
                                                                          maxLines:
                                                                              0,
                                                                        ),
                                                                ),
                                                                const SizedBox(
                                                                    width: 5),
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
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 5),
            ],
          ),
        );
      },
    );

//----------------------------------------------------------------- SubItem 상단 제목
    Widget content = Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                    style: AppTheme.textHintTextStyle.copyWith(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: AppTheme.buttonlightbackgroundColor),
          widget.viewSelect == 0 ? subitemList : Expanded(child: subitemList)
        ],
      ),
    );

    return content;
  }

  Future<void> _showRenameGroupDialog(int groupIndex) async {
    final oldGroupName = _computedGroups[groupIndex]["groupTitle"];
    final List groupItems = _computedGroups[groupIndex]["items"];

    await showDialog(
      context: context,
      builder: (context) {
        return RenameGroupDialog(
          oldGroupName: oldGroupName,
          groupItems: groupItems,
          itemId: widget.itemId,
        );
      },
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
    barrierDismissible: false,
    context: context,
    builder: (BuildContext context) {
      return WillPopScope(
        onWillPop: () async => true,
        child: Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          child: AddDialogItemField(
              itemProvider: itemProvider, itemId: itemId, item: item),
        ),
      );
    },
  );
}

Future<void> showAddDialogSubItem(BuildContext context,
    ItemProvider itemProvider, String itemId, var itemData) async {
  final item = context.read<ItemDetailProvider>().getItemData(itemId);
  await showDialog(
    barrierDismissible: false,
    context: context,
    builder: (BuildContext context) {
      return WillPopScope(
        onWillPop: () async => true,
        child: Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          child: AddDialogSubItemField(
              itemId: itemId, item: item, itemData: itemData),
        ),
      );
    },
  );
}

Future<void> _showAddAttributeDialog(BuildContext context,
    ItemProvider itemProvider, String itemId, var itemData) async {
  await showDialog(
    barrierDismissible: false,
    context: context,
    builder: (BuildContext context) {
      return WillPopScope(
        onWillPop: () async => true,
        child: Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          child: AddAttributeDialog(
            itemProvider: itemProvider,
            itemId: itemId,
            itemData: itemData,
          ),
        ),
      );
    },
  );
}
