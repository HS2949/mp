// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:mp_db/Functions/firestore.dart';
import 'package:mp_db/constants/styles.dart';
import 'package:mp_db/material/component_screen.dart';
import 'package:mp_db/pages/profile_page.dart';
import 'package:mp_db/utils/two_line.dart';
import 'package:mp_db/utils/widget_help.dart';

class Item_Field extends StatefulWidget {
  final String title;
  final bool isDefault;
  const Item_Field({
    Key? key,
    required this.title,
    required this.isDefault,
  }) : super(key: key);

  @override
  _Item_FieldState createState() => _Item_FieldState();
}

class _Item_FieldState extends State<Item_Field> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _fieldController = TextEditingController();
  final firestoreService = FirestoreService();

  void _showDialog({DocumentSnapshot? document}) {
    if (document != null) {
      _nameController.text = document['FieldName'];
      _fieldController.text = document['FieldKey'];
    } else {
      _nameController.clear();
      _fieldController.clear();
    }

    bool isDefault = widget.isDefault; // Local state for the dialog

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(document == null ? 'Add Field' : 'Edit Field'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 10),
                    FilterChip(
                      checkmarkColor: AppTheme.secondaryColor,
                      selectedColor: Colors.yellow[100],
                      backgroundColor: Colors.white,
                      label: Text(isDefault ? 'Default Field' : 'Resources'),
                      selected: isDefault,
                      onSelected: (selected) {
                        setState(() {
                          isDefault = selected; // Update local state
                        });
                      },
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        suffixIcon: ClearButton(controller: _nameController),
                        labelText: 'Field Name',
                        hintText: '예) 주소, 전화번호, 휴무, 메모 ... ',
                        filled: true,
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                        controller: _fieldController,
                        decoration: InputDecoration(
                          suffixIcon: ClearButton(controller: _nameController),
                          labelText: 'Field Key',
                          hintText:
                              '예) Address, PhonNumber, Holiday, Notes ... ',
                          filled: true,
                        )),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (document == null) {
                  firestoreService.addItem(
                    collectionName: 'Fields',
                    data: {
                      'FieldName': _nameController.text,
                      'FieldKey': _fieldController.text,
                      'IsDefault': isDefault, // Save the state
                    },
                    autoGenerateId: true,
                  );
                } else {
                  firestoreService.updateItem(
                    collectionName: 'Fields',
                    documentId: document.id,
                    updatedData: {
                      'FieldName': _nameController.text,
                      'FieldKey': _fieldController.text,
                      'IsDefault': isDefault, // Save the state
                    },
                  );
                }
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
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
                  SizedBox(width: 10),
                  Text('Fields  -  ',
                      style: AppTheme.titleLarge
                          .copyWith(color: AppTheme.buttonbackgroundColor)),
                  Text(widget.title, style: AppTheme.headlineSmall),
                  Spacer(),
                  SizedBox(
                    width: 100,
                    height: 40,
                    child: FloatingActionButton.extended(
                      onPressed: () => _showDialog(),
                      tooltip: '필드명 추가',
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                    ),
                  ),
                ],
              ),
            ),
            StreamBuilder(
              // stream: firestoreService.getItemsSnapshot('Fields'),
              stream: firestoreService.getConditionSnapshot(
                  'Fields', {'IsDefault': widget.isDefault}),

              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final categories = snapshot.data!.docs;

                return SizedBox(
                  width: 500,
                  // height: MediaQuery.of(context).size.height,
                  child: ListView.builder(
                    shrinkWrap: true, // ListView 크기를 자식 위젯에 맞춤
                    physics: NeverScrollableScrollPhysics(), // 스크롤 비활성화
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final categoryData =
                          category.data() as Map<String, dynamic>;
                      bool isDefault = categoryData['IsDefault'];
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
                                  Icon(Icons.loyalty,
                                      color: isDefault
                                          ? Colors.yellow
                                          : Colors.blue),
                                  SizedBox(width: 30),
                                  if (screenWidth > 500) ...[
                                    SizedBox(
                                      width: 100,
                                      child: Text(
                                        categoryData['FieldName'] ?? 'No Name',
                                        style: AppTheme.titleMedium,
                                      ),
                                    ),
                                    SizedBox(width: 30),
                                    Text(
                                      categoryData['FieldKey'] ?? ' - ',
                                      style: AppTheme.titleMedium,
                                    ),
                                  ] else ...[
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 100,
                                          child: Text(
                                            categoryData['FieldName'] ??
                                                'No Name',
                                            style: AppTheme.titleMedium,
                                          ),
                                        ),
                                        SizedBox(height: 5),
                                        Text(
                                          categoryData['FieldKey'] ?? ' - ',
                                          style: AppTheme.titleMedium,
                                        ),
                                      ],
                                    ),
                                  ],
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
                                        collectionName: 'Fields',
                                        documentId: category.id,
                                        firestoreService: firestoreService,
                                      );
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.0),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Flexible(
                                    child: Text(
                                      'ID: ${category.id}',
                                      style: AppTheme.bodySmall
                                          .copyWith(color: Colors.grey),
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
                );
              },
            )
          ],
        ),
      ),
    );
  }
}

class First_Field_Page extends StatelessWidget {
  const First_Field_Page({
    super.key,
    required this.showNavBottomBar,
    required this.scaffoldKey,
    required this.showSecondList,
  });

  final bool showNavBottomBar;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final bool showSecondList;

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      Item_Field(title: 'Default', isDefault: true),
      if (!showSecondList) ...[
        Item_Field(title: 'Resources', isDefault: false),
      ]
    ];
    List<double?> heights = List.filled(children.length, null);

    // Fully traverse this list before moving on.
    return FocusTraversalGroup(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: showSecondList
                ? const EdgeInsetsDirectional.only(end: smallSpacing)
                : EdgeInsets.zero,
            sliver: SliverList(
              delegate: BuildSlivers(
                heights: heights,
                builder: (context, index) {
                  return CacheHeight(
                    heights: heights,
                    index: index,
                    child: children[index],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Second_Field_Page extends StatelessWidget {
  const Second_Field_Page({
    super.key,
    required this.scaffoldKey,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      Item_Field(title: 'Resources', isDefault: false),
    ];
    List<double?> heights = List.filled(children.length, null);

    // Fully traverse this list before moving on.
    return FocusTraversalGroup(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsetsDirectional.only(end: smallSpacing),
            sliver: SliverList(
              delegate: BuildSlivers(
                heights: heights,
                builder: (context, index) {
                  return CacheHeight(
                    heights: heights,
                    index: index,
                    child: children[index],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
