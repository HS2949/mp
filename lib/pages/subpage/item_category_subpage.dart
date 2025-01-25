import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mp_db/Functions/firestore.dart';
import 'package:mp_db/constants/styles.dart';
import 'package:mp_db/utils/widget_help.dart';

class Item_Category extends StatefulWidget {
  const Item_Category({super.key});

  @override
  _Item_CategoryState createState() => _Item_CategoryState();
}

class _Item_CategoryState extends State<Item_Category> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _iconController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final firestoreService = FirestoreService();

  final TextEditingController colorController = TextEditingController();
  final TextEditingController iconController = TextEditingController();
  IconLabel? selectedIcon;
  ColorLabel? selectedColor;

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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          suffixIcon: ClearButton(controller: _nameController),
                          labelText: 'Category Name',
                          hintText: '예) 관광, 식당, 호텔, 차량 ... ',
                          filled: true,
                        ),
                      ),
                      SizedBox(height: 20),
                      Row(
                        children: [
                          Icon(
                            selectedIcon?.icon,
                            color: selectedColor?.color ??
                                Colors.grey.withAlpha(128),
                            size: 40,
                          ),
                          SizedBox(width: 10),
                          Flexible(
                            child: DropdownMenu<IconLabel>(
                              initialSelection: selectedIcon,
                              enableFilter: true,
                              label: Text('Icon'),
                              dropdownMenuEntries: IconLabel.values
                                  .map(
                                    (icon) => DropdownMenuEntry<IconLabel>(
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
                          SizedBox(width: 10),
                          Flexible(
                            child: DropdownMenu<ColorLabel>(
                              initialSelection: selectedColor,
                              enableFilter: true,
                              label: Text('Color'),
                              dropdownMenuEntries: ColorLabel.values
                                  .map((color) => DropdownMenuEntry<ColorLabel>(
                                        value: color,
                                        leadingIcon: Icon(Icons.favorite,
                                            color: color.color, size: 20),
                                        label: color.label,
                                      ))
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
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              if (document == null) {
                                firestoreService.addItem(
                                  collectionName: 'Categories',
                                  data: {
                                    'CategoryName': _nameController.text,
                                    'Icon': selectedIcon?.label,
                                    'Color': selectedColor?.label
                                  },
                                  autoGenerateId: false,
                                );
                              } else {
                                firestoreService.updateItem(
                                  collectionName: 'Categories',
                                  documentId: document.id,
                                  updatedData: {
                                    'CategoryName': _nameController.text,
                                    'Icon': selectedIcon?.label,
                                    'Color': selectedColor?.label
                                  },
                                );
                              }
                              Navigator.of(context).pop();
                            },
                            child: Text('Save'),
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
    final List<DropdownMenuEntry<ColorLabel>> colorEntries =
        <DropdownMenuEntry<ColorLabel>>[];
    for (final ColorLabel color in ColorLabel.values) {
      colorEntries.add(DropdownMenuEntry<ColorLabel>(
          value: color, label: color.label, enabled: color.label != 'Grey'));
    }

    final List<DropdownMenuEntry<IconLabel>> iconEntries =
        <DropdownMenuEntry<IconLabel>>[];
    for (final IconLabel icon in IconLabel.values) {
      iconEntries
          .add(DropdownMenuEntry<IconLabel>(value: icon, label: icon.label));
    }
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.only(bottom: 10),
              width: 500,
              child: Row(
                children: [
                  Text('Categories',
                      style: AppTheme.titleLarge
                          .copyWith(color: AppTheme.buttonbackgroundColor)),
                  Spacer(),
                  SizedBox(
                    width: 100,
                    height: 40,
                    child: FloatingActionButton.extended(
                      onPressed: () => _showDialog(),
                      tooltip: '카테고리 추가',
                      icon: const Icon(Icons.add, color: AppTheme.primaryColor),
                      label: const Text('Add',
                          style: TextStyle(color: AppTheme.primaryColor)),
                      backgroundColor: Colors.grey[300],
                    ),
                  ),
                ],
              ),
            ),
            StreamBuilder(
              stream: firestoreService.getItemsSnapshot('Categories'),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final categories = snapshot.data!.docs;

                return Expanded(
                  child: SizedBox(
                    width: 500,
                    // height: MediaQuery.of(context).size.height,
                    child: ListView.builder(
                      shrinkWrap: true, // ListView 크기를 자식 위젯에 맞춤
                      // physics: NeverScrollableScrollPhysics(), // 스크롤 비활성화
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final categoryData =
                            category.data() as Map<String, dynamic>;
                            
                        selectedColor = ColorLabel.values.firstWhere(
                          (e) => e.label == categoryData['Color'],
                          orElse: () => ColorLabel.silver, // 기본값 설정
                        );

                        // Icon 값을 label로 찾기
                        selectedIcon = IconLabel.values.firstWhere(
                          (e) => e.label == categoryData['Icon'],
                          orElse: () => IconLabel.smile, // 기본값 설정
                        );
                        return Card(
                          margin: EdgeInsets.symmetric(
                              vertical: 5.0, horizontal: 0.0),
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Icon(selectedIcon?.icon,
                                        color: selectedColor?.color, size: 50),
                                    SizedBox(width: 50),
                                    Text(
                                      categoryData['CategoryName'] ?? 'No Name',
                                      style: AppTheme.titleMedium.copyWith(
                                          color: hexToColor(category['Color'])),
                                    ),
                                    Spacer(), // 텍스트와 아이콘 버튼 사이의 공간을 채움
                                    IconButton(
                                      icon: Icon(Icons.edit),
                                      tooltip: '수정',
                                      onPressed: () =>
                                          _showDialog(document: category),
                                    ),

                                    IconButton(
                                      icon: Icon(Icons.delete),
                                      tooltip: '삭제',
                                      onPressed: () {
                                        FiDeleteDialog(
                                          context: context,
                                          collectionName: 'Categories',
                                          documentId: category.id,
                                          firestoreService: firestoreService,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8.0),
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'ID: ${category.id}',
                                        style: AppTheme.bodySmall,
                                      ),
                                    ),
                                    SizedBox(width: 20),
                                    Flexible(
                                      child: Text(
                                        'Icon: ${categoryData['Icon'] ?? '-'}',
                                        style: AppTheme.bodySmall,
                                      ),
                                    ),
                                    SizedBox(width: 20),
                                    Flexible(
                                      child: Text(
                                        'Color: ${categoryData['Color'] ?? '-'}',
                                        style: AppTheme.bodySmall,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
