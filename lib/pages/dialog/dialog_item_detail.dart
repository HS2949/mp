// ============================================================================
// 1. 기본 정보(항목) 추가 다이얼로그
// ============================================================================
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mp_db/Functions/firestore.dart';
import 'package:mp_db/constants/styles.dart';
import 'package:mp_db/models/item_model.dart';
import 'package:mp_db/pages/dialog/dialog_firestorage.dart';
import 'package:mp_db/providers/Item_provider.dart';
import 'package:mp_db/utils/widget_help.dart';

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
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${widget.item?.itemName ?? ""} - 정보 추가',
                style: AppTheme.appbarTitleTextStyle),
            const SizedBox(height: 20),
            DropdownMenu<String>(
              initialSelection: selectedKey,
              // enableFilter: true,
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
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 20),
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                  ),
                  label: Text(
                    'Image Upload',
                    style: AppTheme.tagTextStyle.copyWith(
                      fontSize: 15,
                    ),
                  ),
                  icon: const Icon(
                    Icons.upload,
                    color: AppTheme.text6Color,
                  ),
                  onPressed: () async {
                    // 파일 B에 있는 다이얼로그 함수를 호출하여 선택된 이미지 URL을 받아옴
                    String? imageUrl = await showImageSelectionDialog(context);
                    if (imageUrl != null) {
                      // 받아온 URL을 value1Controller에 할당
                      value1Controller.text = imageUrl;
                    }
                  },
                ),
              ),
            ),
            SizedBox(height: 2),
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.label_important_sharp,
                        color: AppTheme.text5Color,
                        size: 15,
                      ),
                      const SizedBox(width: 8), // 아이콘과 텍스트 필드 사이 간격 추
                      Flexible(
                        child: TextField(
                          controller: value2Controller,
                          decoration: InputDecoration(
                            fillColor: AppTheme.text5Color.withOpacity(0.1),
                            suffixIcon:
                                ClearButton(controller: value2Controller),
                            contentPadding: const EdgeInsets.all(15),
                            labelText: '서브 아이템명',
                            hintText: "예) 메뉴명, 객실명, 서비스명",
                            border: const OutlineInputBorder(),
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ],
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
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
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 30),
                      ),
                      label: Text(
                        'Image Upload',
                        style: AppTheme.tagTextStyle.copyWith(
                          fontSize: 15,
                        ),
                      ),
                      icon: const Icon(
                        Icons.upload,
                        color: AppTheme.text6Color,
                      ),
                      onPressed: () async {
                        // 파일 B에 있는 다이얼로그 함수를 호출하여 선택된 이미지 URL을 받아옴
                        String? imageUrl =
                            await showImageSelectionDialog(context);
                        if (imageUrl != null) {
                          // 받아온 URL을 value1Controller에 할당
                          textController.text = imageUrl;
                        }
                      },
                    ),
                  ),
                ),
                SizedBox(height: 2),
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
                const SizedBox(height: 20),
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
                        child: const Text("Cancel"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // 저장 시 입력한 값을 반환합니다.
                          Navigator.pop(context, textController.text);
                        },
                        child: const Text("Edit"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('속성 추가', style: AppTheme.appbarTitleTextStyle),
              const SizedBox(height: 20),
              DropdownMenu<String>(
                initialSelection: selectedKey,
                // enableFilter: true,
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
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                    ),
                    label: Text(
                      'Image Upload',
                      style: AppTheme.tagTextStyle.copyWith(
                        fontSize: 15,
                      ),
                    ),
                    icon: const Icon(
                      Icons.upload,
                      color: AppTheme.text6Color,
                    ),
                    onPressed: () async {
                      // 파일 B에 있는 다이얼로그 함수를 호출하여 선택된 이미지 URL을 받아옴
                      String? imageUrl =
                          await showImageSelectionDialog(context);
                      if (imageUrl != null) {
                        // 받아온 URL을 value1Controller에 할당
                        _valueController.text = imageUrl;
                      }
                    },
                  ),
                ),
              ),
              SizedBox(height: 2),
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
                    child: const Text('Cancel'),
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
                    child: const Text('Add'),
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
