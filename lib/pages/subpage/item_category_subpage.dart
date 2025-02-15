import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mp_db/Functions/firestore.dart';
import 'package:mp_db/constants/styles.dart';
import 'package:mp_db/utils/widget_help.dart';

class Item_Category extends StatefulWidget {
  const Item_Category({Key? key}) : super(key: key);

  @override
  _Item_CategoryState createState() => _Item_CategoryState();
}

class _Item_CategoryState extends State<Item_Category> {
  final TextEditingController _nameController = TextEditingController();
  final firestoreService = FirestoreService();

  // 사용하지 않는 colorController, iconController는 제거합니다.
  // final TextEditingController colorController = TextEditingController();
  // final TextEditingController iconController = TextEditingController();

  IconLabel? selectedIcon;
  ColorLabel? selectedColor;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showDialog({DocumentSnapshot? document}) {
    if (document != null) {
      _nameController.text = document['CategoryName'];
      selectedColor = ColorLabel.values.firstWhere(
        (e) => e.label == document['Color'],
        orElse: () => ColorLabel.silver, // 기본값 설정
      );
      // Icon 값을 label로 찾기
      selectedIcon = IconLabel.values.firstWhere(
        (e) => e.label == document['Icon'],
        orElse: () => IconLabel.smile, // 기본값 설정
      );
    } else {
      _nameController.clear();
      selectedIcon = IconLabel.values.firstWhere((e) => e.label == 'Smile');
      selectedColor = ColorLabel.values.firstWhere((e) => e.label == 'Grey');
    }

    showDialog(
      context: context,
      builder: (context) {
        // 다이얼로그 내부 상태 변경을 위해 StatefulBuilder 사용
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Container(
                width: 400,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Select Options',
                        style: AppTheme.appbarTitleTextStyle,
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          suffixIcon: ClearButton(controller: _nameController),
                          labelText: 'Category Name',
                          hintText: '예) 관광, 식당, 호텔, 차량 ... ',
                          filled: true,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Icon(
                            selectedIcon?.icon,
                            color: selectedColor?.color ?? Colors.grey.withAlpha(128),
                            size: 40,
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: DropdownMenu<IconLabel>(
                              initialSelection: selectedIcon,
                              enableFilter: true,
                              label: const Text('Icon'),
                              dropdownMenuEntries: IconLabel.values
                                  .map(
                                    (icon) => DropdownMenuEntry<IconLabel>(
                                      labelWidget: Text(
                                        icon.label,
                                        style: AppTheme.textLabelStyle,
                                      ),
                                      value: icon,
                                      leadingIcon: Icon(icon.icon, size: 20),
                                      label: icon.label,
                                    ),
                                  )
                                  .toList(),
                              onSelected: (icon) {
                                setState(() {
                                  selectedIcon = icon;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: DropdownMenu<ColorLabel>(
                              initialSelection: selectedColor,
                              enableFilter: true,
                              label: const Text('Color'),
                              dropdownMenuEntries: ColorLabel.values
                                  .map(
                                    (color) => DropdownMenuEntry<ColorLabel>(
                                      value: color,
                                      leadingIcon: Icon(Icons.favorite,
                                          color: color.color, size: 20),
                                      label: color.label,
                                    ),
                                  )
                                  .toList(),
                              onSelected: (color) {
                                setState(() {
                                  selectedColor = color;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              if (document == null) {
                                firestoreService.addItem(
                                  collectionName: 'Categories',
                                  data: {
                                    'CategoryName': _nameController.text,
                                    'Icon': selectedIcon?.label,
                                    'Color': selectedColor?.label,
                                  },
                                  autoGenerateId: false,
                                );
                              } else {
                                firestoreService.updateItem(
                                  collectionName: 'Categories',
                                  documentId: document.id,
                                  updatedData: {
                                    'CategoryName': _nameController.text.trim(),
                                    'Icon': selectedIcon?.label.trim(),
                                    'Color': selectedColor?.label.trim(),
                                  },
                                );
                              }
                              Navigator.of(context).pop();
                            },
                            child: const Text('Save'),
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

  @override
  Widget build(BuildContext context) {
    // DropdownMenuEntry 목록은 필요에 따라 생성(현재 사용되지 않는 변수지만 추후 활용 가능)
    final List<DropdownMenuEntry<ColorLabel>> colorEntries = <DropdownMenuEntry<ColorLabel>>[];
    for (final ColorLabel color in ColorLabel.values) {
      colorEntries.add(
        DropdownMenuEntry<ColorLabel>(
          value: color,
          label: color.label,
          enabled: color.label != 'Grey',
        ),
      );
    }

    final List<DropdownMenuEntry<IconLabel>> iconEntries = <DropdownMenuEntry<IconLabel>>[];
    for (final IconLabel icon in IconLabel.values) {
      iconEntries.add(
        DropdownMenuEntry<IconLabel>(
          value: icon,
          label: icon.label,
        ),
      );
    }

    return Align(
      alignment: Alignment.topLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: narrowScreenWidthThreshold * 1.2),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Text(
                      'Categories',
                      style: AppTheme.textCGreyStyle.copyWith(fontSize: 22),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 80,
                      height: 35,
                      child: FloatingActionButton.extended(
                        onPressed: () => _showDialog(),
                        tooltip: '카테고리 추가',
                        icon: const Icon(Icons.add, color: AppTheme.primaryColor),
                        label: const Text(
                          'Add',
                          style: TextStyle(color: AppTheme.primaryColor),
                        ),
                        backgroundColor: AppTheme.buttonlightbackgroundColor,
                      ),
                    ),
                  ],
                ),
              ),
              // StreamBuilder를 Expanded로 감싸서 레이아웃이 안정되도록 함
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: firestoreService.getItemsSnapshot('Categories'),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final categories = snapshot.data!.docs;

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final categoryData =
                            category.data() as Map<String, dynamic>;

                        final ColorLabel displayColor = ColorLabel.values.firstWhere(
                          (e) => e.label == categoryData['Color'],
                          orElse: () => ColorLabel.silver,
                        );
                        final IconLabel displayIcon = IconLabel.values.firstWhere(
                          (e) => e.label == categoryData['Icon'],
                          orElse: () => IconLabel.smile,
                        );
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 5.0, horizontal: 0.0),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Wrap(
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          Icon(
                                            displayIcon.icon,
                                            color: displayColor.color,
                                            size: 50,
                                          ),
                                          const SizedBox(width: 40),
                                          SelectableText(
                                            categoryData['CategoryName'] ?? 'No Name',
                                            style: AppTheme.bodyMediumTextStyle.copyWith(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Flexible(
                                      child: Wrap(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, size: 20),
                                            tooltip: '수정',
                                            onPressed: () =>
                                                _showDialog(document: category),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, size: 20),
                                            tooltip: '삭제',
                                            onPressed: () {
                                              FiDeleteDialog(
                                                context: context,
                                                deleteFunction: () async =>
                                                    firestoreService.deleteItem(
                                                  collectionName: 'Categories',
                                                  documentId: category.id,
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8.0),
                                Row(
                                  children: [
                                    Flexible(
                                      child: SelectableText(
                                        'ID: ${category.id}',
                                        style: AppTheme.textHintTextStyle.copyWith(fontSize: 13),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Flexible(
                                      child: SelectableText(
                                        'Icon: ${categoryData['Icon'] ?? '-'}',
                                        style: AppTheme.textHintTextStyle.copyWith(fontSize: 13),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Flexible(
                                      child: SelectableText(
                                        'Color: ${categoryData['Color'] ?? '-'}',
                                        style: AppTheme.textHintTextStyle.copyWith(fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
