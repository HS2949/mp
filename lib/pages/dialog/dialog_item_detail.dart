// ignore_for_file: public_member_api_docs, sort_constructors_first
// ============================================================================
// 1. 기본 정보(항목) 추가 다이얼로그
// ============================================================================
// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 기존 import 외에 recordHistory 함수가 정의된 파일 im port (실제 경로로 수정)

import 'package:mp_db/Functions/firestore.dart';
import 'package:mp_db/Functions/value_history.dart';
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
  final FocusNode _focusNode = FocusNode(); // FocusNode 선언

  @override
  void initState() {
    super.initState();
    value1Controller = TextEditingController();
    defaultScrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode); // 포커스 설정
    });
  }

  @override
  void dispose() {
    value1Controller.dispose();
    defaultScrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode, // FocusNode 할당
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.of(context).pop(); // Esc 키를 누르면 이전 화면으로 이동
        }
      },

      child: SingleChildScrollView(
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
                          widget.itemProvider.fieldMappings[key]
                              ?['IsDefault'] ==
                          true)
                      .toList();
                  sortedKeys.sort((a, b) {
                    final orderA = int.tryParse(widget
                                .itemProvider.fieldMappings[a]?['FieldOrder']
                                ?.toString() ??
                            "9999") ??
                        9999;
                    final orderB = int.tryParse(widget
                                .itemProvider.fieldMappings[b]?['FieldOrder']
                                ?.toString() ??
                            "9999") ??
                        9999;
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
                  padding: const EdgeInsets.only(left: 20, right: 20),
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                    ),
                    label: Text(
                      'Image Upload',
                      style: AppTheme.tagTextStyle.copyWith(
                          fontSize: 15, overflow: TextOverflow.ellipsis),
                    ),
                    icon: const Icon(
                      Icons.upload,
                      color: AppTheme.text6Color,
                    ),
                    onPressed: () async {
                      // 파일 B에 있는 다이얼로그 함수를 호출하여 선택된 이미지 URL을 받아옴
                      String? imageUrl = await showImageSelectionDialog(context,
                          folder: 'uploads/${widget.item?.itemName}/default',
                          addFolder: '');
                      if (imageUrl != null) {
                        // 받아온 URL을 value1Controller에 할당
                        value1Controller.text = imageUrl;
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 2),
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

              if (value1Controller.text.contains('firebasestorage')) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20),
                    child: Text(
                      '그림 경우 : [@200] 형식 추가해서 높이 지정 가능',
                      style: AppTheme.textHintTextStyle.copyWith(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
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
                  const SizedBox(width: 5),
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
                          showOverlayMessage(
                              context, "'$labelKo' 항목이 이미 존재합니다.");
                          return;
                        }
                      }
                      await docRef.set({selectedKey!: defaultValue},
                          SetOptions(merge: true));

                      // recordHistory: 새 필드 추가 (이전값은 null)
                      await recordHistory(
                        context: context,
                        itemId: widget.itemId,
                        field: selectedKey!,
                        before: null,
                        after: defaultValue,
                      );

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
  final FocusNode _focusNode = FocusNode(); // FocusNode 선언

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

    if (widget.itemData != null && widget.itemData.length == 1)
      isAddmode = true; // 그룹명만 전달 받았을 경우 add 모드

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode); // 포커스 설정
    });
  }

  List<Map<String, dynamic>> _computeGroupsFromItem(Item item) {
    final Map<String, List<Map<String, dynamic>>> groupedData = {};
    for (var subItem in item.subItems) {
      final groupKey = subItem.fields['SubItem'] ?? '(미분류)';
      groupedData.putIfAbsent(groupKey, () => []).add(subItem.fields);
    }
    groupedData.forEach((groupKey, subItems) {
      subItems.sort((a, b) {
        int orderA = int.tryParse(a['SubOrder']?.toString() ?? "9999") ?? 9999;
        int orderB = int.tryParse(b['SubOrder']?.toString() ?? "9999") ?? 9999;
        return orderA.compareTo(orderB);
      });
    });

// 아이템 개수에 따른 정렬
    // final sortedGroups = groupedData.entries.toList()
    //   ..sort((a, b) => b.value.length.compareTo(a.value.length));

    // 그룹명 오름차순 정렬렬
    final sortedGroups = groupedData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key)); // 여기서 b.key → a.key로 가면 내림차순
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
    return KeyboardListener(
      focusNode: _focusNode, // FocusNode 할당
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.of(context).pop(); // Esc 키를 누르면 이전 화면으로 이동
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(15.0),
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${widget.item?.itemName ?? ""} - ${isAddmode ? '추가 정보' : '편집'}',
                style: AppTheme.appbarTitleTextStyle,
              ),
              const SizedBox(height: 20),
              DropdownMenu<String>(
                requestFocusOnTap: false,
                expandedInsets: const EdgeInsets.all(15),
                textStyle: TextStyle(color: AppTheme.text9Color),
                label: const Text('그룹명'),
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
                          style: AppTheme.textLabelStyle
                              .copyWith(color: AppTheme.text9Color),
                          controller: groupController,
                          decoration: InputDecoration(
                            suffixIcon:
                                ClearButton(controller: groupController),
                            contentPadding: const EdgeInsets.all(15),
                            labelText: '새 그룹명',
                            hintText: "예) 음식메뉴, 객실, 이용권, 기타..",
                            hintStyle: AppTheme.textLabelStyle
                                .copyWith(color: AppTheme.text9Color),
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
                        const Icon(Icons.label_important_sharp,
                            color: AppTheme.text5Color, size: 15),
                        const SizedBox(width: 8), // 아이콘과 텍스트 필드 사이 간격
                        Flexible(
                          child: TextField(
                            style: AppTheme.textLabelStyle
                                .copyWith(color: AppTheme.itemListColor),
                            controller: value2Controller,
                            decoration: InputDecoration(
                              fillColor: AppTheme.text5Color.withOpacity(0.05),
                              suffixIcon:
                                  ClearButton(controller: value2Controller),
                              contentPadding: const EdgeInsets.all(15),
                              labelText: '서브 아이템명',
                              hintText: "예) 메뉴명, 객실명, 서비스명",
                              hintStyle: AppTheme.textLabelStyle
                                  .copyWith(color: AppTheme.itemListColor),
                              border: const OutlineInputBorder(),
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
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
                  const SizedBox(width: 5),
                  ElevatedButton(
                    onPressed: () async {
                      final String subItemName = value2Controller.text.trim();
                      final String subItemOrder = orderController.text.trim();

                      // 1️⃣ 필수 입력 값 체크
                      if (subItemName.isEmpty) {
                        showOverlayMessage(context, "서브 아이템명을 입력해주세요.");
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
                        finalGroup = selectedGroup ?? '(미분류)';
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
                        // recordHistory: 서브 아이템 추가 시 각 필드 기록 (이전값 null)
                        newSubItemData.forEach((key, value) async {
                          await recordHistory(
                            context: context,
                            itemId: widget.itemId,
                            subItemId: documentId,
                            field: key,
                            before: null,
                            after: value,
                          );
                        });
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
                          // recordHistory: 수정된 필드별로 기록
                          updatedFields.forEach((key, newValue) async {
                            await recordHistory(
                              context: context,
                              itemId: widget.itemId,
                              subItemId: widget.itemData["id"],
                              field: key,
                              before: existingData?[key],
                              after: newValue,
                            );
                          });
                        }
                        // 8️⃣ 편집 모드에서 그룹(폴더명)이 변경되었으면 Files 컬렉션 업데이트
                        final String oldGroup = existingData?['SubName'] ?? '';
                        if (oldGroup != subItemName) {
                          final String oldFolder =
                              'uploads/${widget.item?.itemName}/$oldGroup';
                          final String newFolder =
                              'uploads/${widget.item?.itemName}/$subItemName';

                          QuerySnapshot filesSnapshot = await FirebaseFirestore
                              .instance
                              .collection('files')
                              .where('folder', isEqualTo: oldFolder)
                              .get();

                          WriteBatch batch = FirebaseFirestore.instance.batch();
                          for (var doc in filesSnapshot.docs) {
                            batch.update(doc.reference, {'folder': newFolder});
                          }
                          await batch.commit();
                        }
                      }

                      // 9️⃣ 완료 후 UI 업데이트 및 메시지 표시
                      Navigator.of(context).pop();
                      showOverlayMessage(
                        context,
                        '서브 아이템을 ${isAddmode ? '추가' : '수정'}하였습니다.',
                      );
                    },
                    child: Text(isAddmode ? 'Add' : 'Edit'),
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

// ============================================================================
// 3. 항목 편집 다이얼로그 (EditDialogContent)
// ============================================================================

class EditDialogContent extends StatefulWidget {
  final ItemProvider itemProvider;
  final String keyField; // 예: 'keyword'
  final String itemName;
  final String fieldName;
  final String fieldValue;
  final String itemId;
  final String subItemId;
  final String subTitle;
  final bool isDefault;

  EditDialogContent({
    required this.itemProvider,
    required this.keyField,
    required this.itemName,
    required this.fieldName,
    required this.fieldValue,
    required this.itemId,
    required this.subItemId,
    required this.subTitle,
    required this.isDefault,
  });

  @override
  _EditDialogContentState createState() => _EditDialogContentState();
}

class _EditDialogContentState extends State<EditDialogContent> {
  String? selectedKey;
  String? labelKo;
  late TextEditingController textController;
  final firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
// selectedKey = foundKey.isNotEmpty ? foundKey : widget.keyField;
    selectedKey = widget.keyField;
    labelKo = widget.itemProvider.fieldMappings[selectedKey]?['FieldName'] ??
        selectedKey;
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

                            // recordHistory: 아이템 필드 삭제 (before: 기존 값, after: null)
                            await recordHistory(
                              context: context,
                              itemId: widget.itemId,
                              field: widget.keyField,
                              before: widget.fieldValue,
                              after: null,
                            );
                          } else {
                            await FirebaseFirestore.instance
                                .collection('Items') // 부모 컬렉션
                                .doc(widget.itemId) // 부모 문서 (itemId 기준)
                                .collection('Sub_Items') // 하위 컬렉션
                                .doc(widget.subItemId) // 하위 문서 ID
                                .update({widget.keyField: FieldValue.delete()});

                            // recordHistory: 서브 아이템 필드 삭제
                            await recordHistory(
                              context: context,
                              itemId: widget.itemId,
                              subItemId: widget.subItemId,
                              field: widget.keyField,
                              before: widget.fieldValue,
                              after: null,
                            );
                          }
                        },
                        shouldCloseScreen: true,
                      );
                    },
                    icon: const Icon(Icons.delete_forever_outlined),
                    tooltip: "삭제",
                  ),
                ),
                if (widget.fieldName == '태그') ...[
                  TextFormField(
                    initialValue: widget.fieldName,
                    decoration: InputDecoration(
                      labelText: 'Edit Field',
                      labelStyle: AppTheme.textLabelStyle,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: AppTheme.buttonlightbackgroundColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    style: AppTheme.fieldLabelTextStyle,
                    readOnly: true,
                  )
                ] else ...[
                  DropdownMenu<String>(
                    initialSelection: selectedKey,
                    requestFocusOnTap: false,
                    expandedInsets: const EdgeInsets.all(0),
                    label: const Text('항목 선택'),
                    dropdownMenuEntries: () {
                      // 1) dynamic 타입이 될 수 있는 keys를 문자열 리스트로 변환
                      final allKeys = widget.itemProvider.fieldMappings.keys
                          .map<String>((key) => key.toString())
                          .toList();

                      // 2) 원하는 조건(특정 key 제외 등)에 맞춰 필터링
                      final filteredKeys = allKeys.where((key) {
                        // 예시) IsDefault == false, key != 'SubItem' 등
                        final mapping = widget.itemProvider.fieldMappings[key];
                        if (mapping == null) return false;
                        if (mapping['IsDefault'] != widget.isDefault)
                          return false;
                        if (key == 'SubItem' ||
                            key == 'SubName' ||
                            key == 'SubOrder') return false;
                        return true;
                      }).toList();

                      // 3) 정렬
                      filteredKeys.sort((a, b) {
                        final orderA = int.tryParse(widget.itemProvider
                                    .fieldMappings[a]?['FieldOrder']
                                    ?.toString() ??
                                "9999") ??
                            9999;
                        final orderB = int.tryParse(widget.itemProvider
                                    .fieldMappings[b]?['FieldOrder']
                                    ?.toString() ??
                                "9999") ??
                            9999;
                        return orderA.compareTo(orderB);
                      });

                      // 4) DropdownMenuEntry<String> 리스트로 변환
                      return filteredKeys.map<DropdownMenuEntry<String>>((key) {
                        final fieldName = widget.itemProvider.fieldMappings[key]
                                ?['FieldName'] ??
                            key;
                        return DropdownMenuEntry<String>(
                          value: key, // onSelected로 넘겨줄 실제 값
                          label: fieldName, // 일반적으로 표시되는 텍스트
                          labelWidget:
                              Text(fieldName, style: AppTheme.textLabelStyle),
                        );
                      }).toList();
                    }(),
                    onSelected: (String? newValue) {
                      setState(() {
                        selectedKey = newValue;
                        labelKo = widget.itemProvider.fieldMappings[selectedKey]
                                ?['FieldName'] ??
                            selectedKey;
                      });
                    },
                  )
                ],
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10, right: 10),
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 30),
                      ),
                      label: Text(
                        'Image Upload',
                        style: AppTheme.tagTextStyle.copyWith(
                            fontSize: 15, overflow: TextOverflow.ellipsis),
                      ),
                      icon:
                          const Icon(Icons.upload, color: AppTheme.text6Color),
                      onPressed: () async {
                        // 파일 B에 있는 다이얼로그 함수를 호출하여 선택된 이미지 URL을 받아옴
                        String? imageUrl = await showImageSelectionDialog(
                          context,
                          folder: 'uploads/${widget.itemName}/default',
                          addFolder:
                              'uploads/${widget.itemName}/${widget.subTitle}',
                        );
                        if (imageUrl != null) {
                          // 받아온 URL을 value1Controller에 할당
                          textController.text = imageUrl;
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 2),
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
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        maxLines: null,
                      ),
                    ),
                  ),
                ),
                if (textController.text.contains('firebasestorage')) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10, right: 10),
                      child: Text(
                        '그림 경우 : [@200] 형식 추가해서 높이 지정 가능',
                        style:
                            AppTheme.textHintTextStyle.copyWith(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
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
                      const SizedBox(width: 5),
                      ElevatedButton(
                        onPressed: () async {
                          bool canProceed = true;
                          if (selectedKey != widget.keyField) {
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
                                canProceed = false;
                              }
                            }
                          }
                          if (canProceed) {
                            final newValue = textController.text.trim();
                            // 기존 값과 새 값이 다르면 history 기록
                            if (newValue != widget.fieldValue) {
                              await recordHistory(
                                context: context,
                                itemId: widget.itemId,
                                subItemId: widget.subItemId.isEmpty
                                    ? null
                                    : widget.subItemId,
                                field: selectedKey!,
                                before: widget.fieldValue,
                                after: newValue,
                              );
                            }
                            Navigator.pop(context, {
                              'key': selectedKey,
                              'value': newValue,
                            });
                          }
                        },
                        child: const Text("Edit"),
                      )
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

// ============================================================================
// 4. 속성 추가 다이얼로그 (AddAttributeDialog)
// ============================================================================

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
  late TextEditingController _valueController;
  late ScrollController defaultScrollController;
  String? selectedKey;
  String? labelKo;
  final FocusNode _focusNode = FocusNode(); // FocusNode 선언

  @override
  void initState() {
    super.initState();
    _valueController = TextEditingController();
    defaultScrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode); // 포커스 설정
    });
  }

  @override
  void dispose() {
    _valueController.dispose();
    defaultScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.of(context).pop(); // Esc 키를 누르면 이전 화면으로 이동
        }
      },
      child: SingleChildScrollView(
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
                // Align(
                //   alignment: Alignment.centerRight,
                //   child: Padding(
                //     padding: const EdgeInsets.only(right: 20),
                //     child: SizedBox(
                //       // width: 120,
                //       height: 30,
                //       child: TextButton.icon(
                //         onPressed: () {
                //           showDialog(
                //             context: context,
                //             builder: (BuildContext context) {
                //               return DialogField(
                //                 isDefault:
                //                     false, // 필요한 경우 기본 정보(true) 또는 추가 정보(false)로 설정
                //                 document:
                //                     null, // 추가 시 새 항목을 위한 null, 편집 시 해당 DocumentSnapshot 전달
                //               );
                //             },
                //           );
                //         },
                //         icon: const Icon(Icons.add, color: AppTheme.primaryColor),
                //         label: const Text(
                //           'Add Field',
                //           style: TextStyle(
                //               color: AppTheme.primaryColor, fontSize: 11),
                //         ),
                //       ),
                //     ),
                //   ),
                // ),
                // const SizedBox(height: 2),
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
                              "9999") ??
                          9999;
                      final orderB = int.tryParse(widget
                                  .itemProvider.fieldMappings[b]?['FieldOrder']
                                  ?.toString() ??
                              "9999") ??
                          9999;
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
                    padding: const EdgeInsets.only(left: 20, right: 20),
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 30),
                      ),
                      label: Text(
                        'Image Upload',
                        style: AppTheme.tagTextStyle.copyWith(
                            fontSize: 15, overflow: TextOverflow.ellipsis),
                      ),
                      icon:
                          const Icon(Icons.upload, color: AppTheme.text6Color),
                      onPressed: () async {
                        // 파일 B에 있는 다이얼로그 함수를 호출하여 선택된 이미지 URL을 받아옴
                        String title = widget.itemProvider.items.firstWhere(
                            (item) => item.id == widget.itemId)['ItemName'];
                        String? imageUrl = await showImageSelectionDialog(
                          context,
                          folder: 'uploads/${title}/default',
                          addFolder: '',
                        );
                        if (imageUrl != null) {
                          // 받아온 URL을 value1Controller에 할당
                          _valueController.text = imageUrl;
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 2),
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
                            suffixIcon:
                                ClearButton(controller: _valueController),
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
                if (_valueController.text.contains('firebasestorage')) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20, right: 20),
                      child: Text(
                        '그림 경우 : [@200] 형식 추가해서 높이 지정 가능',
                        style:
                            AppTheme.textHintTextStyle.copyWith(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 5),
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
                              .update(
                                  {selectedKey!: _valueController.text.trim()});
                          // recordHistory: 서브 아이템 필드 추가 (이전값 null)
                          await recordHistory(
                            context: context,
                            itemId: widget.itemId,
                            subItemId: widget.itemData["id"],
                            field: selectedKey!,
                            before: null,
                            after: _valueController.text.trim(),
                          );
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
      ),
    );
  }
}

// ============================================================================
// 5. 그룹명 변경 다이얼로그 (RenameGroupDialog)
// ============================================================================

class RenameGroupDialog extends StatefulWidget {
  final String oldGroupName;
  final List groupItems; // 그룹 내 하위 아이템 목록
  final String itemId;

  const RenameGroupDialog({
    Key? key,
    required this.oldGroupName,
    required this.groupItems,
    required this.itemId,
  }) : super(key: key);

  @override
  _RenameGroupDialogState createState() => _RenameGroupDialogState();
}

class _RenameGroupDialogState extends State<RenameGroupDialog> {
  late TextEditingController _renameController;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _renameController = TextEditingController(text: widget.oldGroupName);
  }

  @override
  void dispose() {
    _renameController.dispose();
    super.dispose();
  }

  Future<void> _updateGroupName() async {
    final newGroupName = _renameController.text.trim();
    if (newGroupName.isEmpty || newGroupName == widget.oldGroupName) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      // WriteBatch 생성
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // widget.groupItems 에서 실제로 현재 그룹에 해당하는 아이템만 업데이트 처리
      final List itemsToUpdate = widget.groupItems
          .where((item) => item["subItem"] == widget.oldGroupName)
          .toList();

      for (var item in itemsToUpdate) {
        final DocumentReference docRef = FirebaseFirestore.instance
            .collection('Items')
            .doc(widget.itemId)
            .collection('Sub_Items')
            .doc(item["id"]);
        batch.update(docRef, {"SubItem": newGroupName});
      }

      // 배치 커밋: 모든 업데이트가 동시에 적용됨
      await batch.commit();

      // recordHistory: 그룹명 변경 (필드 "SubItem" 기록)
      await recordHistory(
        context: context,
        itemId: widget.itemId,
        field: "SubItem",
        before: widget.oldGroupName,
        after: newGroupName,
      );

// 변경된 그룹명을 부모 위젯에 전달하여 UI 업데이트
      Navigator.pop(context);
      showOverlayMessage(context, "그룹명이 변경되었습니다.");
    } catch (error) {
      Navigator.pop(context);
      showOverlayMessage(context, "그룹명 변경 중 오류가 발생했습니다.");
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("그룹명 변경"),
      content: TextField(
        controller: _renameController,
        decoration: const InputDecoration(
          labelText: "새로운 그룹명",
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("취소"),
        ),
        TextButton(
          onPressed: _isUpdating ? null : _updateGroupName,
          child: _isUpdating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text("변경"),
        ),
      ],
    );
  }
}
