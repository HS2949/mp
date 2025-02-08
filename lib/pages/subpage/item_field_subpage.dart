import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mp_db/Functions/firestore.dart';
import 'package:mp_db/constants/styles.dart';
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
  final TextEditingController _orderController = TextEditingController();
  final firestoreService = FirestoreService();

  void _showDialog({DocumentSnapshot? document}) {
    if (document != null) {
      _nameController.text = document['FieldName'];
      _fieldController.text = document['FieldKey'];
      _orderController.text = document['FieldOrder'];
    } else {
      _nameController.clear();
      _fieldController.clear();
      _orderController.clear();
    }

    bool isDefault = widget.isDefault; // Local state for the dialog

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            document == null ? 'Add Field' : 'Edit Field',
            style: AppTheme.appbarTitleTextStyle,
          ),
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
                      backgroundColor: Colors.blue[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // 둥근 모서리 설정
                        side: BorderSide.none, // 테두리 없애기
                      ),
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
                          suffixIcon: ClearButton(controller: _fieldController),
                          labelText: 'Field Key',
                          hintText:
                              '예) Address, PhonNumber, Holiday, Notes ... ',
                          filled: true,
                        )),
                    SizedBox(height: 10),
                    TextField(
                        controller: _orderController,
                        decoration: InputDecoration(
                          suffixIcon: ClearButton(controller: _orderController),
                          labelText: 'Order',
                          hintText: '예) 1, 2, 3, 4.. ',
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
                      'FieldName': _nameController.text.trim(),
                      'FieldKey': _fieldController.text.trim(),
                      'FieldOrder': _orderController.text.trim(),
                      'IsDefault': isDefault, // Save the state
                    },
                    autoGenerateId: true,
                  );
                } else {
                  firestoreService.updateItem(
                    collectionName: 'Fields',
                    documentId: document.id,
                    updatedData: {
                      'FieldName': _nameController.text.trim(),
                      'FieldKey': _fieldController.text.trim(),
                      'FieldOrder': _orderController.text.trim(),
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
                      style: AppTheme.textCGreyStyle.copyWith(fontSize: 22)),
                  Text(widget.title, style: AppTheme.bodyMediumTextStyle),
                  if (widget.isDefault == true) ...[
                    Spacer(),
                    SizedBox(
                      width: 100,
                      height: 40,
                      child: FloatingActionButton.extended(
                          onPressed: () => _showDialog(),
                          tooltip: '필드명 추가',
                          icon: const Icon(Icons.add,
                              color: AppTheme.primaryColor),
                          label: const Text(
                            'Add',
                            style: TextStyle(color: AppTheme.primaryColor),
                          ),
                          backgroundColor: AppTheme.buttonlightbackgroundColor),
                    ),
                  ]
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

                // final categories = snapshot.data!.docs;

                final categories = snapshot.data!.docs.toList();
                categories.sort((a, b) {
                  final String orderStrA =
                      (a.data() as Map<String, dynamic>)['FieldOrder'] ??
                          '9999';
                  final String orderStrB =
                      (b.data() as Map<String, dynamic>)['FieldOrder'] ??
                          '9999';

                  final int orderA = int.tryParse(orderStrA) ?? 9999;
                  final int orderB = int.tryParse(orderStrB) ?? 9999;

                  return orderA.compareTo(orderB);
                });

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
                                  Icon(
                                      isDefault
                                          ? Icons.loyalty
                                          : Icons.label_important_outline,
                                      color: isDefault
                                          ? Colors.yellow
                                          : Colors.blue),
                                  SizedBox(width: 30),
                                  if (screenWidth > 500) ...[
                                    SizedBox(
                                      width: 100,
                                      child: SelectableText(
                                        categoryData['FieldName'] ?? 'No Name',
                                        style: AppTheme.bodyMediumTextStyle,
                                      ),
                                    ),
                                    SizedBox(width: 30),
                                    SelectableText(
                                      categoryData['FieldKey'] ?? ' - ',
                                      style: AppTheme.textLabelStyle,
                                    ),
                                  ] else ...[
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 100,
                                          child: SelectableText(
                                            categoryData['FieldName'] ??
                                                'No Name',
                                            style: AppTheme.bodyMediumTextStyle,
                                          ),
                                        ),
                                        SizedBox(height: 5),
                                        Text(
                                          categoryData['FieldKey'] ?? ' - ',
                                          style: AppTheme.textLabelStyle,
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
                                        deleteFunction: () async =>
                                            firestoreService.deleteItem(
                                          collectionName: 'Fields',
                                          documentId: category.id,
                                        ),
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
                                    child: SelectableText(
                                      'Order >  ${categoryData['FieldOrder'] ?? ''}',
                                      style: AppTheme.tagTextStyle
                                          .copyWith(fontSize: 13),
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
