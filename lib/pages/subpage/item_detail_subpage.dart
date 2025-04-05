// ignore_for_file: public_member_api_docs, sort_constructors_first
// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mp_db/Functions/value_history.dart';
import 'package:mp_db/dialog/dialog_FileView.dart';
import 'package:mp_db/dialog/dialog_ImageView.dart';
import 'package:mp_db/dialog/dialog_item_detail.dart';
import 'package:mp_db/pages/subpage/Detail/subItem_Attributes.dart';
import 'package:mp_db/providers/profile/profile_provider.dart'
    show ProfileProvider;
import 'package:mp_db/providers/user_provider.dart';
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
  late final itemDetailProvider;
  late final String itemName;

  final firestoreService = FirestoreService();
  bool _hasCheckedFileExistence = false;

  /// Firebase의 subItems 데이터를 그룹화한 결과를 저장하는 상태 변수
  List<Map<String, dynamic>> _computedGroups = [];
  bool _allGroupsExpanded = true;
  Map<String, bool> _fileExistsMap = {};

  // subItems 내용 변경 감지를 위한 해시값 저장
  String _lastSubItemsHash = '';

  // Provider의 isToggleAllItem 변경 감지를 위한 이전 값 저장
  bool? _prevToggleState;
  bool _hasFetchedHistory = false;

  @override
  void initState() {
    super.initState();
    provider = Provider.of<ItemProvider>(context, listen: false);
    itemName = provider.items
        .firstWhere((item) => item.id == widget.itemId)['ItemName'];
    itemDetailProvider =
        Provider.of<ItemDetailProvider>(context, listen: false);
    // itemId 변경 시 Firestore 조회
    Future.microtask(() {
      itemDetailProvider.listenToItemDetail(itemId: widget.itemId);
    });

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (mounted && !_hasFetchedHistory) {
    //     print("_fetchAllHistory프레임 이후 실행");
    //     // 즉시 플래그 업데이트하여 중복 실행 방지
    //     _hasFetchedHistory = true;
    //     _fetchAllHistory().then((_) {
    //       if (mounted) {
    //         setState(() {
    //           // 필요한 경우 UI 업데이트
    //         });
    //       }
    //     });
    //   }
    // });

    // Provider에서 전달받은 isToggleAllItem 초기값 저장 및 리스너 등록
    _prevToggleState = itemDetailProvider.isToggleAllItem;
    itemDetailProvider.addListener(_onProviderToggleChanged);
  }

  List<String> _computeSubItemExistingKeys(Map<String, dynamic> subItemData) {
    final fieldKeyList = <String>[];

    if (subItemData.containsKey('attributes') &&
        subItemData['attributes'] is List) {
      for (var attribute in subItemData['attributes'] as List) {
        if (attribute is Map<String, dynamic> &&
            attribute.containsKey('FieldKey')) {
          fieldKeyList.add(attribute['FieldKey'].toString());
        }
      }
    }

    return fieldKeyList;
  }

  void setHistory(BuildContext context, String newKey,
      {String? subItemId, DateTime? selectedDate}) {
    // 선택된 날짜가 없으면 현재 날짜 사용
    final DateTime setTime = selectedDate ?? DateTime.now();

    // 현재 사용자 정보 가져오기
    final currentUser = context.read<ProfileProvider>().state.user;

    // newKey에 대한 히스토리 정보를 생성
    final newHistory = {
      'userName': Provider.of<UserProvider>(context, listen: false)
          .getUserName(currentUser.id),
      'setTime': Timestamp.fromDate(setTime),
    };

    // 기존 히스토리 데이터를 가져와 newKey에 대해 업데이트
    final currentHistory = provider.getHistoryForTab() ?? {};

    // subItemId가 존재하면 '${newKey}_${subItemId}' 형태로 저장, 없으면 그냥 newKey 사용
    final historyKey = subItemId != null ? '${newKey}_$subItemId' : newKey;

    currentHistory[historyKey] = newHistory;
    provider.updateKeyHistory(currentHistory);
  }

  Future<void> _fetchAllHistory() async {
    final itemData =
        context.read<ItemDetailProvider>().getItemData(widget.itemId);

    if (itemData != null) {
      final Map<String, Map<String, dynamic>?> keyHistories = {};
      final List<Future> futures = [];

      // 메인 아이템의 필드는 기존처럼 처리합니다.
      itemData.fields.forEach((key, value) {
        futures.add(() async {
          final history = await fetchKeyHistory(
            itemId: widget.itemId,
            field: key,
            limitNum: 1,
          );
          if (history != null) {
            keyHistories[key] = history;
          }
        }());
      });

      // subItem의 필드는 field와 subItemId를 따로 쿼리합니다.
      for (final subItem in itemData.subItems) {
        final subItemId = subItem.id; // 고유 식별자
        subItem.fields.forEach((key, value) {
          if (key != 'SubItem' && key != 'SubName' && key != 'SubOrder') {
            futures.add(() async {
              final history = await fetchKeyHistory(
                itemId: widget.itemId,
                field: key, // field 조건은 그대로 전달
                subItemId: subItemId, // 별도 조건으로 subItemId 전달
                limitNum: 1,
              );
              if (history != null) {
                // keyHistories에서 구분을 위해 composite key 사용
                final compositeKey = '${key}_$subItemId';
                keyHistories[compositeKey] = history;
              }
            }());
          }
        });
      }

      await Future.wait(futures);
      if (!mounted) return;
      setState(() {
        provider.updateKeyHistory(keyHistories);
      });
    }
  }

  /// 🔹 특정 속성(FieldName)의 최신 변경 내역 가져오기 (유저 이름 포함)
  Future<Map<String, dynamic>?> fetchKeyHistory({
    required String itemId,
    required String field,
    required int limitNum,
    String? subItemId,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;

      Query query = firestore
          .collection('Items')
          .doc(itemId)
          .collection('history')
          .where('field', isEqualTo: field);

      if (subItemId != null) {
        query = query.where('subItemId', isEqualTo: subItemId);
      }

      query = query.orderBy('timestamp', descending: true);

      if (limitNum > 0) {
        query = query.limit(limitNum);
      }

      final querySnapshot = await query.get();
      print('데이터 읽기 히스토리 $itemId $subItemId $field');
      if (querySnapshot.docs.isNotEmpty) {
        final historyData =
            querySnapshot.docs.first.data() as Map<String, dynamic>;

        return {
          'userName': Provider.of<UserProvider>(context, listen: false)
              .getUserName(historyData['userId']),
          'setTime': historyData['setTime'] ?? historyData['timestamp'],
        };
      }
    } catch (e) {
      print("Firestore query failed: $e");
    }

    return null;
  }

  Future<void> _updateFileExistence(String folderName) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('files')
          .where('folder', isGreaterThanOrEqualTo: folderName)
          .where('folder', isLessThanOrEqualTo: '$folderName\uf8ff')
          .get();
      print('데이터 읽기 폴더 확인 $folderName ');

      // 파일이 있는 폴더명을 Set으로 모읍니다.
      Set<String> foldersWithFiles = {};
      for (var doc in querySnapshot.docs) {
        final folder = doc.data()['folder'] as String;
        foldersWithFiles.add(folder);
      }

      // 각 폴더에 대해 _hasFiles를 호출하여 파일 존재 여부를 확인합니다.
      Map<String, bool> existsMap = {};
      for (var folder in foldersWithFiles) {
        bool exists = await _hasFiles(folder);
        existsMap[folder] = exists;
      }
      // folderName에 대한 결과가 없으면 false를 할당
      if (!existsMap.containsKey(folderName)) {
        existsMap[folderName] = false;
      }
      print("Updated file existence: $existsMap");

      setState(() {
        // 기존 값과 병합하여 업데이트할 수도 있습니다.
        _fileExistsMap = {
          ..._fileExistsMap,
          ...existsMap,
        };
      });
    } catch (e) {
      print("Error checking files in subfolders of $folderName: $e");
    }
  }

  // 각 subItem 별 파일 여부를 확인하는 함수
  Future<bool> _hasFiles(String folderName) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('files')
          .where('folder', isEqualTo: folderName)
          .limit(1) // 성능 최적화를 위해 1개만 가져옴
          .get();
      print(' _hasFiles 데이터 읽기 $folderName');

      bool te = querySnapshot.docs.isNotEmpty;
      return te;
    } catch (e) {
      print("Error checking files in $folderName: $e");
      return false;
    }
  }

  bool _isFirstBuild = true;

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   if (!_hasFetchedHistory) {
  //     final itemData = Provider.of<ItemDetailProvider>(context, listen: false)
  //         .getItemData(widget.itemId);
  //     if (itemData != null) {
  //       _hasFetchedHistory = true; // 비동기 작업 전에 플래그를 먼저 설정
  //       _fetchAllHistory();
  //     }
  //   }
  // }

  void didUpdateWidget(covariant ItemDetailSubpage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemId != widget.itemId) {
      _computedGroups = [];
      _lastSubItemsHash = '';
    }

    if (_isFirstBuild) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return; // 위젯이 아직 활성 상태인지 확인
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
          "isExpanded": sortedGroups.length == 1 &&
              subItems.length == 1, // 아이템이 1개면 true, 2개 이상이면 false
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
    BuildContext context, {
    required String key,
    required String name,
    required String value,
    required String itemId,
    required String subItemId,
    required String subTitle,
    required bool isDefault,
    required List<String> existingKeys,
  }) async {
    final result = await showDialog(
      barrierDismissible: false, // ✅ 다이얼로그 바깥을 눌러도 닫히지 않도록 설정
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
        subTitle: subTitle,
        isDefault: isDefault,
        existingKeys: existingKeys, // 현재 존재하는 키 리스트 전달
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

        // newKey에 대한 히스토리 정보를 생성 (현재 날짜를 setTime으로 사용)
        setHistory(context, newKey, subItemId: subItemId);
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
          : const SizedBox.shrink();
    }

    // itemData가 준비되었고, 아직 _fetchAllHistory를 호출하지 않았다면 한 번 호출
    provider.keyHistory;
    if (itemData != null && !_hasFetchedHistory) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return; // 위젯이 아직 활성 상태인지 확인
        _fetchAllHistory();
        setState(() {
          _hasFetchedHistory = true;
        });
      });
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
        : widget.viewSelect < 2
            ? _buildFirstView(itemData)
            : _buildSecondView(itemData);
  }

  Widget _buildFirstView(Item itemData) {
    // main 화면에서 기존 key 목록 계산

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
                String? result = await _showAddDialogItem(context, provider,
                    widget.itemId, itemData.fields.keys.toList());
                // newKey에 대한 히스토리 정보를 생성 (현재 날짜를 setTime으로 사용)
                if (result != null) setHistory(context, result);
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
                          folderName: ['uploads/${itemData.itemName}'],
                          isUrl: false),
                    ),
                  ).then((_) {
                    _fileExistsMap;
                    _updateFileExistence('uploads/${itemData.itemName}');
                  });
                },
              ),
            ],
            if (_fileExistsMap['uploads/${itemData.itemName}/files'] ==
                true) ...[
              IconButton(
                // 기본 정보의 아이콘
                icon: const Icon(
                  Icons.attach_file_outlined,
                  color: AppTheme.text8Color,
                ),
                tooltip: '파일 목록',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FileListScreen(
                        folderName: 'uploads/${itemData.itemName}/files',
                      ),
                    ),
                  ).then((_) {
                    _fileExistsMap;
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
                  leadingIcon: const Icon(Icons.image_outlined),
                  child: const Text('Photo', style: AppTheme.textLabelStyle),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ImageGridScreen(
                            folderName: ['uploads/${itemData.itemName}'],
                            isUrl: false),
                      ),
                    ).then((_) {
                      _fileExistsMap;
                      _updateFileExistence('uploads/${itemData.itemName}');
                    });
                  },
                ),
                MenuItemButton(
                  leadingIcon: const Icon(Icons.edit_note_outlined),
                  child: const Text('Edit', style: AppTheme.textLabelStyle),
                  onPressed: () async {
                    final result = await showAddItem(
                        context, widget.itemId); // 다이얼로그 또는 화면이 닫힐 때까지 기다림
                    if (result != null) {
                      _fileExistsMap;
                      // _updateFileExistence('uploads/${result}');
                    } // 이후 실행
                  },
                ),
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
                  leadingIcon: const Icon(Icons.insert_drive_file_outlined),
                  child: const Text('파일 목록', style: AppTheme.textLabelStyle),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FileListScreen(
                          folderName: 'uploads/${itemData.itemName}/files',
                        ),
                      ),
                    ).then((_) {
                      // 화면이 닫힐 때 _updateFileExistence 실행
                      _fileExistsMap;
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
                GestureDetector(
                  onSecondaryTap: () => _launchURL(
                      "https://www.google.com/search?q=site%3Ainstagram.com%2Fexplore%2Flocations%2F+${itemData.itemName.replaceAll(' ', '')}"),
                  onDoubleTap: () => _launchURL(
                      "https://www.instagram.com/explore/search/keyword/?q=%23${itemData.itemName.replaceAll(' ', '')}"),
                  child: Tooltip(
                    message: "더블 클릭 : 인스타그램 키워드 검색\n오른쪽 버튼 : 인스타그램 장소 검색",
                    child: Icon(
                      icon,
                      color: color,
                      size: 50,
                    ),
                  ),
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
                            "https://map.naver.com/p/search/${itemData.itemName} 제주"),
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
    final Map<String, Color> labelColors = {
      //키워드
      '휴무': AppTheme.errorColor.withOpacity(0.3),
      // '정원': AppTheme.text5Color.withOpacity(0.5),
      '문구#1': AppTheme.textHintColor,
      '문구#2': AppTheme.textHintColor,
      '문구#3': AppTheme.textHintColor,
      '문구#4': AppTheme.textHintColor,
      '문구#5': AppTheme.textHintColor,
      '활동': AppTheme.textHintColor,
    };
    final Map<String, Color> keyColors = {
      //값
      '휴무': const Color.fromARGB(255, 255, 0, 0), //.withOpacity(0.7),
      '정원': const Color.fromARGB(255, 81, 34, 117),
      '문구#1': AppTheme.textHintColor,
      '문구#2': AppTheme.textHintColor,
      '문구#3': AppTheme.textHintColor,
      '문구#4': AppTheme.textHintColor,
      '문구#5': AppTheme.textHintColor,
      '활동': AppTheme.textHintColor,
    };

    final sortedItemFields = Map<String, dynamic>.fromEntries(itemFieldEntries);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasCheckedFileExistence) {
        String folderName = 'uploads/${itemData.itemName}';
        if (!_fileExistsMap.containsKey(folderName)) {
          _updateFileExistence(folderName);
          _hasCheckedFileExistence = true; // 한 번 호출 후 true로 변경
        }
      }
    });

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
                      _showEditDialog(
                        context,
                        key: 'keyword',
                        name: '태그',
                        value: itemData.itemTag,
                        itemId: itemData.id,
                        subItemId: '',
                        subTitle: '',
                        isDefault: true,
                        existingKeys: [],
                      );
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
                  spacing: 50.0,
                  runSpacing: 20.0,
                  children: [
                    for (var entry in sortedItemFields.entries)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final itemProvider = context.read<ItemProvider>();
                          final String label = itemProvider
                                  .fieldMappings[entry.key]?['FieldName'] ??
                              entry.key;
                          // fieldOrder 가져오기
                          final int fieldOrder = int.tryParse(itemProvider
                                      .fieldMappings[entry.key]?['FieldOrder']
                                      .toString() ??
                                  '99') ??
                              99;

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
                                        Builder(
                                          builder: (context) {
                                            final historyData = context
                                                .watch<ItemProvider>()
                                                .getHistoryForTab()?[entry.key];

                                            // setTime 가져오기
                                            final timestamp =
                                                historyData?['setTime']
                                                    as Timestamp?;
                                            String formattedTime = '';
                                            int daysDiff = 0;

                                            if (timestamp != null) {
                                              // 날짜 비교를 위한 시간 정보 제거
                                              final historyDate = DateTime(
                                                timestamp.toDate().year,
                                                timestamp.toDate().month,
                                                timestamp.toDate().day,
                                              );

                                              final nowDate = DateTime(
                                                DateTime.now().year,
                                                DateTime.now().month,
                                                DateTime.now().day,
                                              );

                                              daysDiff = nowDate
                                                  .difference(historyDate)
                                                  .inDays;

                                              // 날짜 포맷 적용
                                              formattedTime = DateFormat(
                                                      "yy. MM. dd", "ko_KR")
                                                  .format(historyDate);
                                            }

                                            // Tooltip 텍스트 생성
                                            final tooltipText = historyData !=
                                                    null
                                                ? '$formattedTime  ${historyData['userName']}  D+$daysDiff'
                                                : '';

                                            return Row(
                                              children: [
                                                Tooltip(
                                                  message: tooltipText,
                                                  child: GestureDetector(
                                                    onDoubleTap: () async {
                                                      // historyData의 timestamp를 DateTime으로 변환, 없으면 현재 날짜를 기본값으로 사용
                                                      DateTime initialDate =
                                                          (historyData?['setTime']
                                                                      as Timestamp?)
                                                                  ?.toDate() ??
                                                              DateTime.now();

                                                      // 사용자에게 날짜 선택 다이얼로그를 표시
                                                      DateTime? selectedDate =
                                                          await showDatePicker(
                                                        context: context,
                                                        initialDate:
                                                            initialDate,
                                                        firstDate:
                                                            DateTime(1900),
                                                        lastDate:
                                                            DateTime(2100),

                                                        initialEntryMode:
                                                            DatePickerEntryMode
                                                                .calendar,
                                                        initialDatePickerMode:
                                                            DatePickerMode.day,
                                                        helpText: '날짜를 선택하세요',
                                                        cancelText: '취소',
                                                        confirmText: '변경',
                                                        errorFormatText:
                                                            '올바른 날짜 형식을 입력하세요',
                                                        errorInvalidText:
                                                            '유효하지 않은 날짜입니다',
                                                        fieldLabelText: '날짜 입력',
                                                        fieldHintText:
                                                            'YYYY/MM/DD',
                                                        keyboardType:
                                                            TextInputType
                                                                .datetime,
                                                        barrierDismissible:
                                                            true, // ✅ 다이얼로그 바깥 클릭 허용
                                                      );

                                                      // 사용자가 날짜를 선택한 경우 recordHistory 함수를 호출
                                                      if (selectedDate !=
                                                          null) {
                                                        // 날짜를 원하는 형식으로 변환 (예: "24. 11. 01(수)")
                                                        String formattedDate =
                                                            DateFormat(
                                                                    "yy. MM. dd(E)",
                                                                    "ko_KR")
                                                                .format(
                                                                    selectedDate);

                                                        recordHistory(
                                                          context: context,
                                                          itemId: widget.itemId,
                                                          field: entry.key,
                                                          before:
                                                              '정보 확인:\n$formattedDate',
                                                          after: entry.value,
                                                          setTime: selectedDate,
                                                        );
                                                        // newKey에 대한 히스토리 정보를 생성 (현재 날짜를 setTime으로 사용)
                                                        setHistory(
                                                            context, entry.key,
                                                            selectedDate:
                                                                selectedDate);

                                                        showOverlayMessage(
                                                            context,
                                                            "${label}의 확인 날짜를 $formattedDate 로 갱신하였습니다.");
                                                      }
                                                    },
                                                    onLongPress: () {
                                                      showHistoryDialog(
                                                        context: context,
                                                        itemId: widget.itemId,
                                                        itemName: itemName,
                                                        fieldKey: entry.key,
                                                      );
                                                    },
                                                    child: copyTextWidget(
                                                      context,
                                                      text: label,
                                                      widgetType:
                                                          TextWidgetType.plain,
                                                      style: AppTheme
                                                          .fieldLabelTextStyle
                                                          .copyWith(
                                                        color: labelColors[
                                                                label] ??
                                                            AppTheme.text4Color,
                                                      ),
                                                      doGestureDetector: false,
                                                    ),
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.text2Color
                                                        .withOpacity(0.6),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                ),
                                                if (tooltipText.isNotEmpty &&
                                                    fieldOrder <= 50) ...[
                                                  const SizedBox(width: 4),
                                                  Builder(
                                                    builder: (context) {
                                                      // `D+숫자` 추출 및 스타일 적용
                                                      final match =
                                                          RegExp(r"D\+(\d+)")
                                                              .firstMatch(
                                                                  tooltipText);
                                                      final value = match !=
                                                              null
                                                          ? int.tryParse(match
                                                                  .group(1)
                                                                  .toString()) ??
                                                              0
                                                          : 0;

                                                      return Text(
                                                        match?.group(0) ?? "",
                                                        style: AppTheme
                                                            .bodySmallTextStyle
                                                            .copyWith(
                                                          fontSize: value >= 30
                                                              ? 11
                                                              : 8,
                                                          color: value >= 30
                                                              ? AppTheme
                                                                  .text6Color
                                                              : AppTheme
                                                                  .textHintColor,
                                                          fontWeight: value >=
                                                                  30
                                                              ? FontWeight.bold
                                                              : FontWeight
                                                                  .normal,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ]
                                              ],
                                            );
                                          },
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
                                                key: entry.key,
                                                name:
                                                    itemProvider.fieldMappings[
                                                                entry.key]
                                                            ?['FieldName'] ??
                                                        entry.key,
                                                value: entry.value,
                                                itemId: itemData.id,
                                                subItemId: '',
                                                subTitle: '',
                                                isDefault: true,
                                                existingKeys: itemData
                                                    .fields.keys
                                                    .toList(), // 현재 존재하는 키 리스트
                                              );
                                            },
                                          ),
                                        )
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Flexible(
                                      child: result is Widget
                                          ? Container(
                                              alignment: Alignment.centerLeft,
                                              child: result,
                                            )
                                          : copyTextWidget(
                                              context,
                                              text: result,
                                              widgetType:
                                                  TextWidgetType.textField,
                                              controller: TextEditingController(
                                                  text: result),
                                              style: AppTheme.bodySmallTextStyle
                                                  .copyWith(
                                                fontSize: 13,
                                                color: keyColors[label] ??
                                                    AppTheme.primaryColor,
                                              ),
                                              maxLines: 0,
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
    // subItems의 해시값을 계산하여 내용 변경 감지
    final newHash = _computeSubItemsHash(item);

    if (newHash != _lastSubItemsHash) {
      _lastSubItemsHash = newHash;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _updateComputedGroups(item);
        }
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasCheckedFileExistence) {
        String folderName =
            'uploads/${provider.items.firstWhere((item) => item.id == widget.itemId)['ItemName']}';
        if (!_fileExistsMap.containsKey(folderName)) {
          _updateFileExistence(folderName);
          _hasCheckedFileExistence = true; // 한 번 호출 후 true로 변경
        }
      }
    });

    Widget subitemList = ListView.builder(
      shrinkWrap: widget.viewSelect == 0 ? true : false,
      physics: BouncingScrollPhysics(),
      itemCount: _computedGroups.length + 1, // 마지막 공간을 위해 +1
      itemBuilder: (context, groupIndex) {
        if (groupIndex == _computedGroups.length) {
          // 마지막 여백 추가
          return SizedBox(height: 50);
        }

        final group = _computedGroups[groupIndex];

        final Map<String, Color> fieldLabelColors = {
          //키워드
          '입금가': AppTheme.text7Color.withOpacity(0.3),
          '청구가': AppTheme.text5Color.withOpacity(0.5),
          '정상가': AppTheme.primaryColor,
          '문구#1': AppTheme.textHintColor,
          '문구#2': AppTheme.textHintColor,
          '문구#3': AppTheme.textHintColor,
          '문구#4': AppTheme.textHintColor,
          '문구#5': AppTheme.textHintColor,
          '활동': AppTheme.textHintColor,
        };
        final Map<String, Color> fieldColors = {
          //값
          '입금가': AppTheme.text7Color.withOpacity(0.7),
          '청구가': const Color.fromARGB(255, 81, 34, 117),
          '정상가': AppTheme.primaryColor,
          '문구#1': AppTheme.textHintColor,
          '문구#2': AppTheme.textHintColor,
          '문구#3': AppTheme.textHintColor,
          '문구#4': AppTheme.textHintColor,
          '문구#5': AppTheme.textHintColor,
          '활동': AppTheme.textHintColor,
          
        };

        Future<void> _handleLongPress(int groupIndex, BuildContext context,
            ItemProvider provider, Map<String, dynamic> group) async {
          await showAddDialogSubItem(
            context,
            provider,
            (provider.tabViews[provider.selectedIndex].second
                    as ItemDetailSubpage)
                .getItemId,
            {"subItem": group["groupTitle"]}, // Map 형식으로 전달
          );
        }

        ///---------------------------------------------------------------------------------- 아이템 그룹
        return Card(
          elevation: 0,
          child: Column(
            children: [
              Tooltip(
                message:
                    '클릭 : 열기/닫기\n길게 누르기 or 오른쪽 버튼 : 아이템 추가\n더블 클릭  : 그룹명 변경',
                decoration: BoxDecoration(
                  color: AppTheme.text9Color.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                ),
                child: GestureDetector(
                  onTap: () => _toggleGroupExpansion(groupIndex), // 단일 클릭
                  onDoubleTap: () =>
                      _showRenameGroupDialog(groupIndex), // 이름 변경
                  onSecondaryTap: () async => await _handleLongPress(
                      groupIndex, context, provider, group),
                  onLongPress: () async => await _handleLongPress(
                      groupIndex, context, provider, group),
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
                  ),
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
                                    message:
                                        '클릭 : 열기/닫기\n더블클릭 : 모든 아이템 열기/닫기\n오른쪽 버튼 : 아이템 수정\n길게 누르기 : 속성 추가',
                                    child: GestureDetector(
                                      onDoubleTap: () {
                                        Provider.of<ItemDetailProvider>(context,
                                                listen: false)
                                            .toggleAllItem();
                                      },
                                      onTap: () => _toggleItemExpansion(
                                          groupIndex, itemIndex),
                                      onSecondaryTap: () async {
                                        String? result =
                                            await showAddDialogSubItem(
                                                context,
                                                provider,
                                                widget.itemId,
                                                itemData);

                                        if (result != null && result != "") {
                                          _updateFileExistence(result);
                                        }
                                      },
                                      onLongPress: () async {
                                        String? result =
                                            await _showAddAttributeDialog(
                                                context,
                                                provider,
                                                widget.itemId,
                                                itemData,
                                                _computeSubItemExistingKeys(
                                                    itemData));
                                        // newKey에 대한 히스토리 정보를 생성 (현재 날짜를 setTime으로 사용)
                                        if (result != null)
                                          setHistory(context, result,
                                              subItemId: itemData['id']);
                                        _toggleAllItemsInGroup(
                                            groupIndex, false);
                                      },
                                      child: ListTile(
                                        tileColor: AppTheme.text5Color
                                            .withOpacity(0.03),
                                        contentPadding:
                                            const EdgeInsets.fromLTRB(
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
                                                builder: (context, controller,
                                                    child) {
                                                  return TextButton.icon(
                                                    style: TextButton.styleFrom(
                                                      padding: EdgeInsets.zero,
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
                                                              color: AppTheme
                                                                  .buttonlightbackgroundColor),
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
                                                    // ----------- 메뉴아이템: 사진 추가
                                                    leadingIcon: const Icon(
                                                        Icons.image_outlined),
                                                    child: const Text(
                                                      'Photo',
                                                      style: AppTheme
                                                          .textLabelStyle,
                                                    ),
                                                    onPressed: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              ImageGridScreen(
                                                                  folderName: [
                                                                folderName
                                                              ],
                                                                  isUrl: false),
                                                        ),
                                                      ).then((_) {
                                                        _fileExistsMap;
                                                        _updateFileExistence(
                                                            'uploads/${item.itemName}');
                                                      });
                                                    },
                                                  ),
                                                  MenuItemButton(
                                                    // ----------- 메뉴아이템: 수정
                                                    leadingIcon: const Icon(Icons
                                                        .edit_note_outlined),
                                                    child: const Text(
                                                      'Edit',
                                                      style: AppTheme
                                                          .textLabelStyle,
                                                    ),
                                                    onPressed: () async {
                                                      String? result =
                                                          await showAddDialogSubItem(
                                                              context,
                                                              provider,
                                                              widget.itemId,
                                                              itemData);

                                                      if (result != null &&
                                                          result != "") {
                                                        _fileExistsMap;
                                                        _updateFileExistence(
                                                            result);
                                                      }
                                                    },
                                                  ),
                                                  MenuItemButton(
                                                    // ----------- 메뉴아이템: 삭제
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
                                                              .doc(
                                                                  widget.itemId)
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
                                                    // ----------- 메뉴아이템: 속성 추가
                                                    leadingIcon: const Icon(Icons
                                                        .add_to_photos_outlined),
                                                    child: const Text(
                                                      '  속성 추가',
                                                      style: AppTheme
                                                          .textLabelStyle,
                                                    ),
                                                    onPressed: () async {
                                                      String? result =
                                                          await _showAddAttributeDialog(
                                                              context,
                                                              provider,
                                                              widget.itemId,
                                                              itemData,
                                                              _computeSubItemExistingKeys(
                                                                  itemData));
                                                      // newKey에 대한 히스토리 정보를 생성 (현재 날짜를 setTime으로 사용)
                                                      if (result != null)
                                                        setHistory(
                                                            context, result,
                                                            subItemId:
                                                                itemData['id']);
                                                      _toggleAllItemsInGroup(
                                                          groupIndex, false);
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              '${itemData["title"]}',
                                              style: AppTheme
                                                  .fieldLabelTextStyle
                                                  .copyWith(
                                                color: _computedGroups[groupIndex]
                                                                        [
                                                                        "items"]
                                                                    [itemIndex]
                                                                ["attributes"]
                                                            .length >
                                                        0
                                                    ? AppTheme.itemListColor
                                                    : AppTheme.itemList0Color,
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            if (_fileExistsMap[folderName] ==
                                                true) ...[
                                              IconButton(
                                                constraints:
                                                    const BoxConstraints(
                                                        minWidth: 0,
                                                        minHeight: 0),
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
                                                              folderName: [
                                                            folderName
                                                          ],
                                                              isUrl: false),
                                                    ),
                                                  ).then((_) {
                                                    _fileExistsMap;
                                                    _updateFileExistence(
                                                        'uploads/${item.itemName}');
                                                  });
                                                },
                                              )
                                            ],
                                          ],
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // 필요에 따라 trailing 버튼 추가
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  ///------------------------------------------------------------- 아이템 속성
                                  // AnimatedSize(
                                  //   duration: const Duration(milliseconds: 300),
                                  //   curve: Curves.fastOutSlowIn,
                                  //   child: itemData["isExpanded"]
                                  //       ? SubItemAttributes(
                                  //           attributes: itemData["attributes"],
                                  //           itemId: widget.itemId,
                                  //           subItemId: itemData['id'],
                                  //           subTitle: itemData['title'],
                                  //           onEdit: (context,
                                  //               key,
                                  //               name,
                                  //               value,
                                  //               itemId,
                                  //               subItemId,
                                  //               subTitle,
                                  //               isDefault,
                                  //               existingKeys) {
                                  //             _showEditDialog(
                                  //               context,
                                  //               key: key,
                                  //               name: name,
                                  //               value: value,
                                  //               itemId: itemId,
                                  //               subItemId: subItemId,
                                  //               subTitle: subTitle,
                                  //               isDefault: false,
                                  //               existingKeys: existingKeys,
                                  //             );
                                  //           },
                                  //         )
                                  //       : const SizedBox.shrink(),
                                  // ),

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
                                                runSpacing: 20.0,
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
                                                                Builder(
                                                                  builder:
                                                                      (context) {
                                                                    final String?
                                                                        subItemId =
                                                                        itemData[
                                                                            'id'];
                                                                    final String
                                                                        fieldKey =
                                                                        attribute[
                                                                            'FieldKey']; // 기존 필드 키

                                                                    final String
                                                                        compositeKey =
                                                                        subItemId !=
                                                                                null
                                                                            ? '${fieldKey}_$subItemId'
                                                                            : fieldKey;

                                                                    final historyData = context
                                                                        .watch<
                                                                            ItemProvider>()
                                                                        .getHistoryForTab()?[compositeKey];

                                                                    // Timestamp 가져오기
                                                                    final timestamp =
                                                                        historyData?['setTime']
                                                                            as Timestamp?;
                                                                    String
                                                                        formattedTime =
                                                                        '';
                                                                    int daysDiff =
                                                                        0;

                                                                    if (timestamp !=
                                                                        null) {
                                                                      // 날짜 비교를 위한 시간 정보 제거
                                                                      final historyDate =
                                                                          DateTime(
                                                                        timestamp
                                                                            .toDate()
                                                                            .year,
                                                                        timestamp
                                                                            .toDate()
                                                                            .month,
                                                                        timestamp
                                                                            .toDate()
                                                                            .day,
                                                                      );

                                                                      final nowDate =
                                                                          DateTime(
                                                                        DateTime.now()
                                                                            .year,
                                                                        DateTime.now()
                                                                            .month,
                                                                        DateTime.now()
                                                                            .day,
                                                                      );

                                                                      daysDiff = nowDate
                                                                          .difference(
                                                                              historyDate)
                                                                          .inDays;

                                                                      // 날짜 포맷 적용
                                                                      formattedTime = DateFormat(
                                                                              "yy. MM. dd",
                                                                              "ko_KR")
                                                                          .format(
                                                                              historyDate);
                                                                    }

                                                                    // Tooltip 텍스트 생성
                                                                    final tooltipText = historyData !=
                                                                            null
                                                                        ? '$formattedTime  ${historyData['userName']}  D+$daysDiff'
                                                                        : '';
                                                                    // fieldOrder 가져오기
                                                                    final int
                                                                        fieldOrder =
                                                                        int.tryParse(attribute['FieldOrder']?.toString() ??
                                                                                '99') ??
                                                                            99;

                                                                    return Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .center,
                                                                      children: [
                                                                        Tooltip(
                                                                          message:
                                                                              tooltipText,
                                                                          child:
                                                                              GestureDetector(
                                                                            onDoubleTap:
                                                                                () async {
                                                                              // historyData의 timestamp를 DateTime으로 변환, 없으면 현재 날짜를 기본값으로 사용
                                                                              DateTime initialDate = (historyData?['setTime'] as Timestamp?)?.toDate() ?? DateTime.now();

                                                                              // 사용자에게 날짜 선택 다이얼로그를 표시
                                                                              DateTime? selectedDate = await showDatePicker(
                                                                                context: context,
                                                                                initialDate: initialDate,
                                                                                firstDate: DateTime(1900),
                                                                                lastDate: DateTime(2100),

                                                                                initialEntryMode: DatePickerEntryMode.calendar,
                                                                                initialDatePickerMode: DatePickerMode.day,
                                                                                helpText: '날짜를 선택하세요',
                                                                                cancelText: '취소',
                                                                                confirmText: '변경',
                                                                                errorFormatText: '올바른 날짜 형식을 입력하세요',
                                                                                errorInvalidText: '유효하지 않은 날짜입니다',
                                                                                fieldLabelText: '날짜 입력',
                                                                                fieldHintText: 'YYYY/MM/DD',
                                                                                keyboardType: TextInputType.datetime,
                                                                                barrierDismissible: true, // ✅ 다이얼로그 바깥 클릭 허용
                                                                              );

                                                                              // 사용자가 날짜를 선택한 경우 recordHistory 함수를 호출
                                                                              if (selectedDate != null) {
                                                                                // 날짜를 원하는 형식으로 변환 (예: "24. 11. 01(수)")
                                                                                String formattedDate = DateFormat("yy. MM. dd(E)", "ko_KR").format(selectedDate);

                                                                                recordHistory(
                                                                                  context: context,
                                                                                  itemId: widget.itemId,
                                                                                  subItemId: subItemId,
                                                                                  field: attribute['FieldKey'],
                                                                                  before: '정보 확인:\n$formattedDate',
                                                                                  after: attribute['FieldValue'],
                                                                                  setTime: selectedDate,
                                                                                );
                                                                                // newKey에 대한 히스토리 정보를 생성 (현재 날짜를 setTime으로 사용)
                                                                                setHistory(
                                                                                  context,
                                                                                  attribute['FieldKey'],
                                                                                  subItemId: subItemId,
                                                                                  selectedDate: selectedDate,
                                                                                );

                                                                                showOverlayMessage(context, "${attribute['FieldName']}의 확인 날짜를 $formattedDate 로 갱신하였습니다.");
                                                                              }
                                                                            },
                                                                            onLongPress:
                                                                                () {
                                                                              showHistoryDialog(
                                                                                context: context,
                                                                                itemId: widget.itemId,
                                                                                itemName: itemName,
                                                                                fieldKey: attribute['FieldKey'],
                                                                                subItemId: subItemId,
                                                                                subTitle: itemData['title'],
                                                                              );
                                                                            },
                                                                            child:
                                                                                copyTextWidget(
                                                                              context,
                                                                              text: attribute['FieldName'] ?? '',
                                                                              widgetType: TextWidgetType.plain,
                                                                              doGestureDetector: false,
                                                                              style: AppTheme.bodySmallTextStyle.copyWith(
                                                                                fontSize: 13,
                                                                                fontWeight: FontWeight.w600,
                                                                                color: fieldLabelColors[attribute['FieldName']] ?? AppTheme.text4Color,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          decoration:
                                                                              BoxDecoration(
                                                                            color:
                                                                                AppTheme.text2Color.withOpacity(0.6),
                                                                            borderRadius:
                                                                                BorderRadius.circular(8),
                                                                          ),
                                                                        ),
                                                                        if (tooltipText.isNotEmpty &&
                                                                            fieldOrder <=
                                                                                50) ...[
                                                                          const SizedBox(
                                                                              height: 4),
                                                                          Builder(
                                                                            builder:
                                                                                (context) {
                                                                              // `D+숫자` 추출 및 스타일 적용
                                                                              final match = RegExp(r"D\+(\d+)").firstMatch(tooltipText);
                                                                              final value = match != null ? int.tryParse(match.group(1).toString()) ?? 0 : 0;
                                                                              return Text(
                                                                                match?.group(0) ?? "",
                                                                                style: AppTheme.bodySmallTextStyle.copyWith(
                                                                                  fontSize: value >= 30 ? 11 : 8,
                                                                                  color: value >= 30 ? AppTheme.text6Color : AppTheme.textHintColor,
                                                                                  fontWeight: value >= 30 ? FontWeight.bold : FontWeight.normal,
                                                                                ),
                                                                              );
                                                                            },
                                                                          ),
                                                                        ],
                                                                      ],
                                                                    );
                                                                  },
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
                                                                      key: attribute[
                                                                          'FieldKey'],
                                                                      name: attribute[
                                                                          'FieldName'],
                                                                      value: attribute[
                                                                          'FieldValue'],
                                                                      itemId: widget
                                                                          .itemId,
                                                                      subItemId:
                                                                          itemData[
                                                                              'id'],
                                                                      subTitle:
                                                                          itemData[
                                                                              'title'],
                                                                      isDefault:
                                                                          false,
                                                                      existingKeys:
                                                                          _computeSubItemExistingKeys(
                                                                              itemData), // 현재 존재하는 키 리스트
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
                                                                              .copyWith(
                                                                            fontSize:
                                                                                13,
                                                                            color:
                                                                                fieldColors[attribute['FieldName']] ?? AppTheme.primaryColor,
                                                                          ),
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

Future<String?> _showAddDialogItem(BuildContext context,
    ItemProvider itemProvider, String itemId, List<String> existingKeys) async {
  final item = context.read<ItemDetailProvider>().getItemData(itemId);
  return await showDialog<String>(
    barrierDismissible: false, // ✅ 다이얼로그 바깥을 눌러도 닫히지 않도록 설정
    context: context,
    builder: (BuildContext context) {
      return WillPopScope(
        onWillPop: () async => true,
        child: Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          child: AddDialogItemField(
              itemProvider: itemProvider,
              itemId: itemId,
              item: item,
              existingKeys: existingKeys),
        ),
      );
    },
  );
}

Future<String?> showAddDialogSubItem(BuildContext context,
    ItemProvider itemProvider, String itemId, var itemData) async {
  final item = context.read<ItemDetailProvider>().getItemData(itemId);

  return await showDialog<String>(
    barrierDismissible: false, // ✅ 다이얼로그 바깥을 눌러도 닫히지 않도록 설정
    context: context,
    builder: (BuildContext context) {
      return WillPopScope(
        onWillPop: () async => false, // ✅ 뒤로가기 버튼도 막음
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

Future<String?> _showAddAttributeDialog(
    BuildContext context,
    ItemProvider itemProvider,
    String itemId,
    var itemData,
    existingKeys) async {
  return await showDialog<String>(
    barrierDismissible: false, // ✅ 다이얼로그 바깥을 눌러도 닫히지 않도록 설정
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
            existingKeys: existingKeys,
          ),
        ),
      );
    },
  );
}
